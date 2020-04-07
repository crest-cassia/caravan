//
// Created by Yohsuke Murase on 2020/02/26.
//

#ifndef CARAVAN_SCHEDULER_TASKRESULT_HPP
#define CARAVAN_SCHEDULER_TASKRESULT_HPP

#include <iostream>
#include <fstream>
#include <cstdint>
#include <vector>
#include <array>
#include <string>
#include <sstream>
#include <nlohmann/json.hpp>

using json = nlohmann::json;

class TaskResult {
  public:
  TaskResult(long _id, long _rc, long _rank, long _start_at, long _finish_at)
    : task_id(_id), rc(_rc), rank(_rank), start_at(_start_at), finish_at(_finish_at) {};
  TaskResult() : task_id(-1), rc(-1), rank(-1), start_at(-1), finish_at(-1) {};
  long task_id;
  long rc;
  long rank;
  long start_at;
  long finish_at;
  json output;
  double ElapsedTime() const {
    return static_cast<double>(finish_at - start_at) / 1000.0;
  }
  static TaskResult CancelledTaskResult(long _id) {
    return TaskResult(_id, -1, -1, -1, -1);
  }
};

void to_json(json& j, const TaskResult& tr) {
  j = json{{"id", tr.task_id}, {"rc", tr.rc}, {"rank", tr.rank}, {"start_at", tr.start_at}, {"finish_at", tr.finish_at}, {"output", tr.output}};
}

void from_json(const json& j, TaskResult& tr) {
  j.at("id").get_to(tr.task_id);
  j.at("rc").get_to(tr.rc);
  j.at("rank").get_to(tr.rank);
  j.at("start_at").get_to(tr.start_at);
  j.at("finish_at").get_to(tr.finish_at);
  tr.output = j.at("output");
}

#endif //CARAVAN_SCHEDULER_TASKRESULT_HPP
