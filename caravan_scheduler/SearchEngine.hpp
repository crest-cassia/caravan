//
// Created by Yohsuke Murase on 2020/02/28.
//

#ifndef CARAVAN_SCHEDULER_SEARCHENGINE_HPP
#define CARAVAN_SCHEDULER_SEARCHENGINE_HPP

#include <iostream>
#include <vector>
#include <string>
#include <cstdio>
#include <cstdlib>
#include <vector>
#include <string>
#include <unistd.h>
#include <sys/types.h>
#include <sys/wait.h>
#include <sys/poll.h>
#include <sys/types.h>
#include <sys/socket.h>
#include <netinet/in.h>
#include <arpa/inet.h>
#include <csignal>

#include "Task.hpp"

using json = nlohmann::json;

class SearchEngine {
 public:
  MPI_Comm intercomm;

  long LaunchSearcher( const std::vector<std::string>& argvs) {
    char** args = new char*[argvs.size()];
    for (size_t i = 0; i < argvs.size()-1; i++) {
      args[i] = new char[argvs[i+1].size()+1];
      std::strcpy(args[i], argvs[i+1].c_str());
    }
    args[argvs.size()-1] = nullptr;  // last argument must be a nullptr
    int rc = MPI_Comm_spawn(argvs[0].c_str(), args, 1, MPI_INFO_NULL, 0, MPI_COMM_SELF, &intercomm, MPI_ERRCODES_IGNORE);
    for (size_t i = 0; i < argvs.size()-1; i++) { delete[] args[i]; }
    delete[] args;
    return rc;
  }

  std::vector<Task> CreateInitialTasks() {
    return ReadTasks();
  }

  std::vector<Task> SendResult(const std::vector<uint8_t>& result_buf) {
    MPI_Send(&result_buf[0], result_buf.size(), MPI_BYTE, 0, 0, intercomm);
    return ReadTasks();
  }

  void SendTerminateSignal() {
    MPI_Send(nullptr, 0, MPI_BYTE, 0, 1, intercomm);  // tag==1 indicates the termination
    MPI_Comm_disconnect(&intercomm);
  }

 private:
  inline std::vector<Task> ReadTasks() {
    MPI_Status st;
    MPI_Probe(0, 0, intercomm, &st);
    int n_bytes = 0;
    MPI_Get_count(&st, MPI_BYTE, &n_bytes);
    std::vector<unsigned char> buf(n_bytes);
    MPI_Recv(&buf[0], n_bytes, MPI_BYTE, st.MPI_SOURCE, st.MPI_TAG, intercomm, MPI_STATUS_IGNORE);
    const json tasks_j = json::from_msgpack(buf);
    std::vector<Task> tasks;
    for(const json& x: tasks_j) {
      tasks.emplace_back(x);
    }
    return tasks;
  }
};

#endif //CARAVAN_SCHEDULER_SEARCHENGINE_HPP
