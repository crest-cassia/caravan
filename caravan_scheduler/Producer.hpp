//
// Created by Yohsuke Murase on 2020/02/26.
//

#ifndef CARAVAN_SCHEDULER_PRODUCER_HPP
#define CARAVAN_SCHEDULER_PRODUCER_HPP

#include <iostream>
#include <vector>
#include <queue>
#include <map>
#include <set>
#include <chrono>
#include "mpi.h"
#include "Task.hpp"
#include "TaskResult.hpp"
#include "Logger.hpp"
#include "SearchEngine.hpp"

enum MsgTag {
  PROD_BUF_SEND_TASKS = 1,
  PROD_BUF_TERMINATE_REQUEST,
  BUF_PROD_TASK_REQUEST,
  BUF_PROD_SEND_RESULT,
  BUF_CONS_SEND_TASK,
  BUF_CONS_TERMINATE_REQUEST,
  CONS_BUF_TASK_REQUEST,
  CONS_BUF_SEND_RESULT
};

int my_MPI_Probe(int source, int tag, MPI_Comm comm, MPI_Status *status) {
  int received = 0, ret = 0;
  while(true) {
    ret = MPI_Iprobe(source, tag, comm, &received, status);
    if (received) break;
    usleep(10000);
  }
  return ret;
}

class Producer {
 public:
  Producer(Logger &_logger, const json &_OPTIONS) : logger(_logger), OPTIONS(_OPTIONS) {};

  std::queue<Task> tasks;
  std::map<long, TaskResult> task_results;
  Logger &logger;
  SearchEngine se;
  const json OPTIONS;

  void LaunchSearcher(const std::vector<std::string> &argvs) {
    int rc = se.LaunchSearcher(argvs);
    logger.d("launched searcher");
    if (rc != 0) { throw std::runtime_error("failed to spawn search engine"); }
  }
  void EnqueueInitialTasks() {
    logger.d("creating initial tasks");
    auto created = se.CreateInitialTasks();
    logger.d("created initial tasks");
    for (const auto &t: created) { tasks.push(t); }
  }

  void Run(const std::vector<int> &buffers) {
    logger.i("Producer started : %d buffers", buffers.size());
    std::set<long> running_task_ids;
    std::map<int, size_t> requesting_buffers;

    MPI_Request send_req = MPI_REQUEST_NULL;
    std::vector<uint8_t> send_buf;

    while (true) {
      logger.d("Producer has %d tasks %d running_tasks", tasks.size(), running_task_ids.size());
      bool has_something_to_send = (tasks.size() > 0 && requesting_buffers.size() > 0);
      bool has_something_to_receive = (running_task_ids.size() > 0 || requesting_buffers.size() < buffers.size());
      if (!has_something_to_send && !has_something_to_receive) { break; }

      MPI_Status st;
      int received = 0;
      int sent = 0;
      if (has_something_to_receive && has_something_to_send) {
        while (true) {  // wait until message is ready
          MPI_Iprobe(MPI_ANY_SOURCE, MPI_ANY_TAG, MPI_COMM_WORLD, &received, &st);
          if (received) break;
          MPI_Test(&send_req, &sent, MPI_STATUS_IGNORE); // MPI_Test on MPI_REQUEST_NULL returns true
          if (sent) break;
          usleep(10000);
        }
      } else if (has_something_to_receive) {
        my_MPI_Probe(MPI_ANY_SOURCE, MPI_ANY_TAG, MPI_COMM_WORLD, &st);
        received = 1;
      } else if (has_something_to_send) {
        MPI_Wait(&send_req, MPI_STATUS_IGNORE);
        sent = 1;
      }

      // receiving
      if (received) {
        if (st.MPI_TAG == MsgTag::BUF_PROD_TASK_REQUEST) {
          std::pair<int, int> worker_nreq = ReceiveRequest(st);
          requesting_buffers.insert(worker_nreq);
        } else if (st.MPI_TAG == MsgTag::BUF_PROD_SEND_RESULT) {
          long task_id = ReceiveResult(st);
          logger.d("Producer received result for %d", task_id);
          running_task_ids.erase(task_id);
          SendResultsToSearcher(task_id);
        } else {  // must not happen
          assert(false);
          MPI_Abort(MPI_COMM_WORLD, 1);
        }
      } else if (sent) {
        auto it = requesting_buffers.begin();
        int worker = it->first;
        size_t n_request = it->second;
        const auto task_ids = SendTasks(worker, n_request, &send_req, send_buf);
        for (long task_id: task_ids) {
          running_task_ids.insert(task_id);
        }
        requesting_buffers.erase(worker);
      }
    }

    MPI_Wait(&send_req, MPI_STATUS_IGNORE);

    for (auto req_w: requesting_buffers) {
      TerminateWorker(req_w.first);
    }
    logger.d("SE terminating");
    se.SendTerminateSignal();
    logger.d("producer terminated");
  }

  std::vector<long> SendTasks(int worker, size_t num_tasks, MPI_Request *p_req, std::vector<uint8_t> &send_buf) {
    json j;
    std::vector<long> task_ids;
    for (size_t i = 0; i < num_tasks && tasks.size() > 0; i++) {
      const Task t = tasks.front();
      tasks.pop();
      j.push_back(t);
      task_ids.push_back(t.task_id);
    }
    send_buf = std::move(json::to_msgpack(j));
    size_t n = send_buf.size();
    MPI_Isend(send_buf.data(), n, MPI_BYTE, worker, MsgTag::PROD_BUF_SEND_TASKS, MPI_COMM_WORLD, p_req);
    logger.d("%d tasks are assigned to %d", task_ids.size(), worker);
    return task_ids;
  }

  void TerminateWorker(int worker) {
    logger.d("worker %d terminating", worker);
    std::vector<char> buf;
    MPI_Send(&buf[0], 0, MPI_BYTE, worker, MsgTag::PROD_BUF_TERMINATE_REQUEST, MPI_COMM_WORLD);
  }

  std::pair<int, int> ReceiveRequest(const MPI_Status &st) {
    assert(st.MPI_TAG == MsgTag::BUF_PROD_TASK_REQUEST);
    int n_req = 0;
    MPI_Recv(&n_req, 1, MPI_INT, st.MPI_SOURCE, st.MPI_TAG, MPI_COMM_WORLD, MPI_STATUS_IGNORE);
    assert(n_req > 0);
    logger.d("Producer received request %d from %d", n_req, st.MPI_SOURCE);
    return std::make_pair(st.MPI_SOURCE, n_req);
  }

  long ReceiveResult(const MPI_Status &st) {
    assert(st.MPI_TAG == MsgTag::BUF_PROD_SEND_RESULT);
    int msg_size;
    MPI_Get_count(&st, MPI_CHAR, &msg_size);
    std::vector<unsigned char> buf(msg_size);
    MPI_Recv(&buf[0], msg_size, MPI_BYTE, st.MPI_SOURCE, st.MPI_TAG, MPI_COMM_WORLD, MPI_STATUS_IGNORE);
    logger.d("result was sent by %d", st.MPI_SOURCE);
    const json j = json::from_msgpack(buf);
    TaskResult tr = j.get<TaskResult>();
    task_results.emplace(tr.task_id, tr);
    logger.d("saved result of task %d", tr.task_id);
    return tr.task_id;
  }

  void SendResultsToSearcher(long task_id) {
    logger.d("sending results %d to search engine", task_id);
    const auto &res = task_results.find(task_id);
    assert(res != task_results.end());
    auto ts = se.SendResult(json::to_msgpack(res->second));
    logger.d("%d new tasks are created", ts.size());
    for (const auto &t: ts) {
      tasks.push(t);
    }
    logger.d("sending results to search engine");
  }

  double ElapsedSum() const {
    double s = 0.0;
    for (const auto &it: task_results) { s += it.second.ElapsedTime(); }
    return s;
  }
};

#endif //CARAVAN_SCHEDULER_PRODUCER_HPP
