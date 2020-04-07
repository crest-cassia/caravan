//
// Created by Yohsuke Murase on 2020/02/26.
//

#ifndef CARAVAN_SCHEDULER_TASK_HPP
#define CARAVAN_SCHEDULER_TASK_HPP

#include <iostream>
#include <cstdio>
#include <string>
#include <cstdlib>
#include <sstream>
#include <vector>
#include <unistd.h>
#include <cassert>
#include <filesystem>
#include <nlohmann/json.hpp>
#include "Logger.hpp"
#include "TaskResult.hpp"

using json = nlohmann::json;

class Task {
  public:
  Task(long _id, std::string _cmd, const json& _input = nullptr) : task_id(_id), command(std::move(_cmd)), input(_input) {};
  Task() : task_id(-1) {};
  long task_id;
  std::string command;
  json input;
  TaskResult Run(Logger& logger, const std::chrono::system_clock::time_point& ref_time, const std::string& work_base_dir, long timeout) const {
    const std::filesystem::path cwd = std::filesystem::current_path();

    const std::filesystem::path work_dir = WorkDirPath(work_base_dir);

    std::filesystem::create_directories(work_dir);
    if(!input.is_null()) {
      std::ofstream fout(InputFilePath(work_base_dir));
      fout << input;
      fout.flush();  // explicitly flush fout
    }
    std::filesystem::current_path(work_dir);

    auto start_at = std::chrono::system_clock::now();
    long s_at = std::chrono::duration_cast<std::chrono::milliseconds>(start_at - ref_time).count();
    logger.d("Starting task %d at %s, timeout %d sec", task_id, work_dir.c_str(), timeout);
    setenv("CARAVAN_TASK_TIMEOUT", std::to_string(timeout).c_str(), 1);
    int rc = std::system(command.c_str());
    auto finish_at = std::chrono::system_clock::now();
    long f_at = std::chrono::duration_cast<std::chrono::milliseconds>(finish_at - ref_time).count();
    logger.d("Completed task %d", task_id);
    std::filesystem::current_path(cwd);

    int my_rank;
    MPI_Comm_rank(MPI_COMM_WORLD, &my_rank);
    TaskResult res(task_id, rc, my_rank, s_at, f_at);

    const std::filesystem::path res_path = OutputFilePath(work_base_dir);
    logger.d("Output file %s", res_path.c_str());
    if( std::filesystem::exists(res_path) ) {
      size_t res_size = std::filesystem::file_size(res_path);
      logger.d("Output file is found for task %d (%d bytes)", task_id, res_size);
      json j;
      std::ifstream fin(res_path);
      fin >> j;
      res.output = j;
      logger.d("Output: %s", res.output.dump().c_str() );
    }

    return res;
  }
  std::filesystem::path WorkDirPath(const std::string& work_base_dir) const {
    char buf[256];
    int n = std::snprintf(buf, sizeof(buf), "%s/w%04ld/w%07ld", work_base_dir.c_str(), task_id/1000, task_id);
    assert(n >= 0 && n < 256);
    return std::filesystem::path(buf);
  }
  std::filesystem::path InputFilePath(const std::string& work_base_dir) const {
    auto p = WorkDirPath(work_base_dir);
    p.append("_input.json");
    return p;
  }
  std::filesystem::path OutputFilePath(const std::string& work_base_dir) const {
    auto p = WorkDirPath(work_base_dir);
    p.append("_output.json");
    return p;
  }
};

void to_json(json& j, const Task& t) {
  j = json{{"id", t.task_id}, {"cmd", t.command}, {"input", t.input}};
}

void from_json(const json& j, Task& t) {
  j.at("id").get_to(t.task_id);
  j.at("cmd").get_to(t.command);
  t.input = j.at("input");
}

#endif //CARAVAN_SCHEDULER_TASK_HPP
