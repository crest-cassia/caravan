//
// Created by Yohsuke Murase on 2020/03/17.
//

#ifndef CARAVAN_SCHEDULER_BUFFER_HPP
#define CARAVAN_SCHEDULER_BUFFER_HPP

#include <iostream>
#include <vector>
#include <chrono>
#include <cstring>
#include "mpi.h"
#include "Task.hpp"
#include "TaskResult.hpp"
#include "Logger.hpp"
#include "Producer.hpp"

class Buffer {
 public:
  Buffer(int _parent, Logger &_logger, std::chrono::system_clock::time_point _ref_time, const json &_OPTIONS)
      : parent(_parent), logger(_logger), OPTIONS(_OPTIONS) {};
  const int parent;
  Logger &logger;
  const json &OPTIONS;

  std::queue<Task> tasks;
  std::map<long, TaskResult> task_results;

  void EnqueueInitialTasks(long n_consumers) {
    logger.d("requesting initial tasks");
    MPI_Request req;
    std::vector<uint8_t> buf;
    SendRequest(n_consumers, &req, buf);
    MPI_Wait(&req, MPI_STATUS_IGNORE);
    MPI_Status st;
    my_MPI_Probe(MPI_ANY_SOURCE, MsgTag::PROD_BUF_SEND_TASKS, MPI_COMM_WORLD, &st);
    ReceiveTasks(st);
    logger.d("created initial tasks");
  }

  void Run(const std::vector<int> &consumers) {
    logger.i("Buffer started: parent %d, %d consumers", parent, consumers.size());
    std::set<long> running_task_ids;
    std::set<int> requesting_workers;
    bool request_sent = false;
    bool terminate_received = false;

    EnqueueInitialTasks(consumers.size());

    MPI_Request send_req = MPI_REQUEST_NULL;
    std::vector<uint8_t> send_buf;

    while (true) {
      logger.d("%d tasks, %d running_tasks, %d requesting_workers, %d task_resutls, %d consumers, request_sent %d",
               tasks.size(),
               running_task_ids.size(),
               requesting_workers.size(),
               task_results.size(),
               consumers.size(),
               request_sent);
      bool has_tasks_to_send = (tasks.size() > 0 && requesting_workers.size() > 0);
      bool has_request_to_send = (tasks.size() == 0 && !request_sent && requesting_workers.size() > 0);
      bool has_results_to_send = (task_results.size() > 0);
      bool has_something_to_send = (has_tasks_to_send || has_request_to_send || has_results_to_send);
      bool has_something_to_receive = (running_task_ids.size() > 0 || !terminate_received);
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
          usleep(1000);
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
        assert(has_something_to_receive);
        if (st.MPI_TAG == MsgTag::CONS_BUF_TASK_REQUEST) {
          int worker = ReceiveRequest(st);
          requesting_workers.insert(worker);
        } else if (st.MPI_TAG == MsgTag::CONS_BUF_SEND_RESULT) {
          long task_id = ReceiveResult(st);
          running_task_ids.erase(task_id);
        } else if (st.MPI_TAG == MsgTag::PROD_BUF_SEND_TASKS) {
          ReceiveTasks(st);
          request_sent = false;
        } else if (st.MPI_TAG == MsgTag::PROD_BUF_TERMINATE_REQUEST) {
          MPI_Recv(nullptr, 0, MPI_BYTE, st.MPI_SOURCE, st.MPI_TAG, MPI_COMM_WORLD, MPI_STATUS_IGNORE);
          terminate_received = true;
        } else {  // must not happen
          assert(false);
          MPI_Abort(MPI_COMM_WORLD, 1);
        }
      } else if (sent) {
        if (has_tasks_to_send) {  // Sending a task to a Consumer
          const int worker = *(requesting_workers.begin());
          long task_id = SendTask(worker, &send_req, send_buf);
          running_task_ids.insert(task_id);
          requesting_workers.erase(worker);
        } else if (has_request_to_send) { // Send a request to Producer
          SendRequest(requesting_workers.size(), &send_req, send_buf);
          request_sent = true;
        } else if (has_results_to_send) {
          auto it = task_results.begin();
          SendResult(it->second, &send_req, send_buf);
          task_results.erase(it);
        } else {  // must not happen
          assert(false);
          MPI_Abort(MPI_COMM_WORLD, 1);
        }
      }
    }

    MPI_Wait(&send_req, MPI_STATUS_IGNORE);

    for (long w: consumers) {
      TerminateWorker(w);
    }
  }

  long SendTask(const int worker, MPI_Request *p_req, std::vector<uint8_t> &send_buf) {
    const Task t = tasks.front();
    tasks.pop();
    send_buf = std::move(json::to_msgpack(t));
    MPI_Isend(send_buf.data(), send_buf.size(), MPI_BYTE, worker, MsgTag::BUF_CONS_SEND_TASK, MPI_COMM_WORLD, p_req);
    logger.d("task %d is assigned to %d", t.task_id, worker);
    return t.task_id;
  }

  void SendRequest(const int n_request, MPI_Request *p_req, std::vector<uint8_t> &send_buf) {
    size_t s = sizeof(n_request);
    send_buf.resize(s);
    std::memcpy(send_buf.data(), &n_request, s);
    MPI_Isend(send_buf.data(), 1, MPI_INT, parent, MsgTag::BUF_PROD_TASK_REQUEST, MPI_COMM_WORLD, p_req);
    logger.d("requesting %d tasks", n_request);
  }

  void SendResult(const TaskResult &res, MPI_Request *p_req, std::vector<uint8_t> &send_buf) {
    send_buf = std::move(json::to_msgpack(res));
    MPI_Isend(send_buf.data(), send_buf.size(), MPI_BYTE, parent, MsgTag::BUF_PROD_SEND_RESULT, MPI_COMM_WORLD, p_req);
    logger.d("sent a result of task %d", res.task_id);
  }

  int ReceiveRequest(const MPI_Status &st) {
    assert(st.MPI_TAG == CONS_BUF_TASK_REQUEST);
    int n_req = 0;
    MPI_Recv(&n_req, 1, MPI_INT, st.MPI_SOURCE, st.MPI_TAG, MPI_COMM_WORLD, MPI_STATUS_IGNORE);
    assert(n_req == 1);
    return st.MPI_SOURCE;
  }

  void ReceiveTasks(const MPI_Status &st) {
    logger.d("receiving tasks from %d", st.MPI_SOURCE);
    assert(st.MPI_TAG == MsgTag::PROD_BUF_SEND_TASKS);
    int task_len = 0;
    // calculate the length of a command
    MPI_Get_count(&st, MPI_CHAR, &task_len);
    assert(task_len > 0);
    std::vector<unsigned char> buf(task_len);
    MPI_Recv(&buf[0], buf.size(), MPI_CHAR, parent, st.MPI_TAG, MPI_COMM_WORLD, MPI_STATUS_IGNORE);
    const json j = json::from_msgpack(buf);
    logger.d("%s", j.dump().c_str());
    std::vector<Task> received;
    for (const json &j_t: j) { tasks.push(j_t.get<Task>()); }
  }

  long ReceiveResult(const MPI_Status &st) {
    assert(st.MPI_TAG == MsgTag::CONS_BUF_SEND_RESULT);
    int worker = st.MPI_SOURCE;
    int msg_size;
    MPI_Get_count(&st, MPI_CHAR, &msg_size);
    std::vector<unsigned char> buf(msg_size);
    MPI_Recv(&buf[0], msg_size, MPI_BYTE, worker, st.MPI_TAG, MPI_COMM_WORLD, MPI_STATUS_IGNORE);
    logger.d("result was sent by %d, %d bytes", worker, msg_size);
    const json j = json::from_msgpack(buf);
    logger.d("%s", j.dump().c_str());
    TaskResult tr = j.get<TaskResult>();
    task_results.emplace(tr.task_id, tr);
    logger.d("saved result of task %d", tr.task_id);
    return tr.task_id;
  }

  void TerminateWorker(int worker) {
    MPI_Send(nullptr, 0, MPI_BYTE, worker, MsgTag::BUF_CONS_TERMINATE_REQUEST, MPI_COMM_WORLD);
    logger.d("worker %d terminating", worker);
  }
};

#endif //CARAVAN_SCHEDULER_BUFFER_HPP
