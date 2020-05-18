//
// Created by Yohsuke Murase on 2020/02/26.
//

#ifndef CARAVAN_SCHEDULER_CONSUMER_HPP
#define CARAVAN_SCHEDULER_CONSUMER_HPP

#include <iostream>
#include <vector>
#include <string>
#include <chrono>
#include "mpi.h"
#include "Logger.hpp"
#include "Task.hpp"
#include "TaskResult.hpp"
#include "Producer.hpp"
#include "SpawnerHandler.hpp"

class Consumer {
 public:
  Consumer(int _parent,
           SpawnerHandler &_sh,
           Logger &_logger,
           std::chrono::system_clock::time_point _ref_time,
           const json &_OPTIONS)
      : parent(_parent), sh(_sh), logger(_logger), ref_time(_ref_time), OPTIONS(_OPTIONS) {};
  const int parent;
  Logger &logger;
  const json &OPTIONS;
  const std::chrono::system_clock::time_point ref_time;
  SpawnerHandler &sh;
  void Run() {
    while (true) {
      SendRequest();

      Task t = ReceiveTask();
      // If the length is zero, all tasks are completed.
      if (t.task_id < 0) {
        logger.d("Finish OK");
        break;
      }

      auto now = std::chrono::system_clock::now();
      long dt = OPTIONS["CARAVAN_TIMEOUT"].get<long>()
          - std::chrono::duration_cast<std::chrono::seconds>(now - ref_time).count();
      if (dt > 0) {
        logger.d("running %d", t.task_id);
        TaskResult res = t.Run(logger, sh, ref_time, OPTIONS["CARAVAN_WORK_BASE_DIR"], dt);
        SendResult(res);
      } else {
        logger.i("timeout: task %d is cancelled", t.task_id);
        TaskResult res = TaskResult::CancelledTaskResult(t.task_id);
        SendResult(res);
      }
    }
  }
  void SendRequest() {
    int request = 1;
    logger.d("sending request");
    MPI_Send(&request, 1, MPI_INT, parent, MsgTag::CONS_BUF_TASK_REQUEST, MPI_COMM_WORLD);
  }
  Task ReceiveTask() {
    int task_len = 0;
    MPI_Status st;
    // receive the length of a command
    MPI_Probe(parent, MPI_ANY_TAG, MPI_COMM_WORLD, &st);
    if (st.MPI_TAG == MsgTag::BUF_CONS_TERMINATE_REQUEST) {
      char buf;
      MPI_Recv(&buf, 0, MPI_CHAR, parent, st.MPI_TAG, MPI_COMM_WORLD, &st);
      return Task(-1, "");
    }
    assert(st.MPI_TAG == MsgTag::BUF_CONS_SEND_TASK);
    MPI_Get_count(&st, MPI_CHAR, &task_len);
    std::vector<unsigned char> buf(task_len);
    MPI_Recv(&buf[0], buf.size(), MPI_CHAR, parent, st.MPI_TAG, MPI_COMM_WORLD, &st);
    const json j = json::from_msgpack(buf);
    return j.get<Task>();
  }
  void SendResult(const TaskResult &res) {
    auto buf = json::to_msgpack(res);
    int n = buf.size();
    MPI_Send(&buf[0], n, MPI_BYTE, parent, MsgTag::CONS_BUF_SEND_RESULT, MPI_COMM_WORLD);
    logger.d("sent task result %d", res.task_id);
  }
};

#endif //CARAVAN_SCHEDULER_CONSUMER_HPP
