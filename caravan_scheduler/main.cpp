#include <chrono>
#include <iostream>
#include <mpi.h>
#include <numeric>
#include <vector>
#include "Task.hpp"
#include "Producer.hpp"
#include "Buffer.hpp"
#include "Consumer.hpp"


json GetOptions() {
  json OPTIONS = {
      {"CARAVAN_NUM_PROC_PER_BUF", 384 },  // # of consumer processes for each buffer proc
      {"CARAVAN_TIMEOUT", 86400 }, // timeout duration in sec
      {"CARAVAN_SOCKET_PORT", 50007 }, // port used for communication between producer and search engine
      // {"CARAVAN_SEND_RESULT_INTERVAL", 3 }, // interval to send results in sec
      {"CARAVAN_WORK_BASE_DIR", "."}, // the directory under which work directories are created
      {"CARAVAN_LOG_LEVEL", 1} // log level (int)
  };

  for(auto& elm: OPTIONS.items()) {
    const std::string key = elm.key();
    const char* val = std::getenv(key.c_str());
    if( val != nullptr ) {
      if( elm.value().is_number_integer() ) {
        char* e;
        elm.value() = std::strtol(val, &e, 0);
        if(*e != '\0') {
          std::cerr << "invalid value is given for " << key << " : " << val << std::endl;
          throw std::runtime_error("invalid input");
        }
      }
      else if( elm.value().is_string() ) {
        elm.value() = val;
      }
      else {
        throw std::runtime_error("must not happen");
      }
    }
  }
  return OPTIONS;
}

json BcastOptions(int rank) {
  std::vector<uint8_t> opt_buf;
  if(rank == 0) {
    const json j = GetOptions();
    opt_buf = std::move(json::to_msgpack(j) );
    uint64_t size = opt_buf.size();
    MPI_Bcast(&size, 1, MPI_UINT64_T, 0, MPI_COMM_WORLD);
    MPI_Bcast(opt_buf.data(), opt_buf.size(), MPI_BYTE, 0, MPI_COMM_WORLD);
  }
  else {
    uint64_t size = 0;
    MPI_Bcast(&size, 1, MPI_UINT64_T, 0, MPI_COMM_WORLD);
    opt_buf.resize(size);
    MPI_Bcast(opt_buf.data(), opt_buf.size(), MPI_BYTE, 0, MPI_COMM_WORLD);
  }
  return json::from_msgpack(opt_buf);
}

// role(0:prod,1:buf,2:cons), parent, children
std::tuple<int,int,std::vector<int>> GetRole(int rank, int procs, int num_proc_per_buf) {
  assert(procs >= 2);
  int role, parent;
  std::vector<int> children;
  if(rank == 0) {
    role = 0;
    parent = -1;
    children.push_back(1);
    for(int i = num_proc_per_buf; i < procs; i+= num_proc_per_buf) { children.push_back(i); }
  }
  else if(rank == 1) {
    role = 1;
    parent = 0;
    for(int i=2; i < num_proc_per_buf && i < procs; i++) { children.push_back(i); }
  }
  else if(rank % num_proc_per_buf == 0) {
    role = 1;
    parent = 0;
    for(int i=rank+1; i<rank+num_proc_per_buf && i < procs; i++) { children.push_back(i); }
  }
  else {
    role = 2;
    parent = (rank / num_proc_per_buf) * num_proc_per_buf;
    if(parent == 0) { parent = 1; }
  }
  return std::make_tuple(role, parent, children);
}

int main(int argc, char* argv[]) {
  MPI_Init(&argc, &argv);
  /*
  if( argc < 2 ) {
    std::cerr << "Usage: mpiexec -np ${PROCS} " << argv[0] << " ${CMD TO SEARCH PS}" << std::endl;
    MPI_Abort(MPI_COMM_WORLD, 1);
  }
   */

  int rank, procs;
  MPI_Comm_rank(MPI_COMM_WORLD, &rank);
  MPI_Comm_size(MPI_COMM_WORLD, &procs);

  std::chrono::system_clock::time_point start;
  if(rank == 0) {
    start = std::chrono::system_clock::now();
  }
  MPI_Bcast( (void *)&start, sizeof(std::chrono::system_clock::time_point), MPI_CHAR, 0, MPI_COMM_WORLD );

  const json OPTIONS = BcastOptions(rank);

  const auto role = GetRole(rank, procs, OPTIONS["CARAVAN_NUM_PROC_PER_BUF"]);

  Logger logger(start, OPTIONS["CARAVAN_LOG_LEVEL"]);
  if( std::get<0>(role) == 0 ) {
    Producer prod(logger, OPTIONS);
    std::vector<Task> tasks;
    std::vector<std::string> argvs;
    for(int i=1; i<argc; i++) { argvs.emplace_back(argv[i]); }
    prod.LaunchSearcher( argvs );
    prod.EnqueueInitialTasks();

    prod.Run(std::get<2>(role));

    // logging
    std::chrono::system_clock::time_point end = std::chrono::system_clock::now();
    double elapsed = std::chrono::duration_cast<std::chrono::milliseconds>(end - start).count() / 1000.0;
    double total = prod.ElapsedSum();
    logger.i("Elapsed time: %f [s]", total);
    double eff = total / (elapsed * (procs - 1));
    logger.i("Parallel Efficiency : %f ", eff);
    logger.d("Task list (Command : Elapsed time)");
    for(const auto& it : prod.task_results ) {
      logger.d("%d : %f [s] : %s", it.second.task_id, it.second.ElapsedTime(), it.second.output.dump().c_str() );
    }

    // dump results
    std::ofstream binout("tasks.msgpack", std::ios::binary);
    const std::vector<uint8_t> dumped = json::to_msgpack(prod.task_results);
    binout.write( (const char*)dumped.data(), dumped.size() );
    binout.flush();
    binout.close();
  }
  else if( std::get<0>(role) == 1 ) {
    Buffer buf(std::get<1>(role), logger, start, OPTIONS);
    buf.Run(std::get<2>(role));
  }
  else {
    assert( std::get<0>(role) == 2 );
    Consumer cons(std::get<1>(role), logger, start, OPTIONS);
    cons.Run();
  }
  MPI_Finalize();
  return 0;
}

