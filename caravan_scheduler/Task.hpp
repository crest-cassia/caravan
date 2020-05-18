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
#include <nlohmann/json.hpp>
#include "Logger.hpp"
#include "TaskResult.hpp"
#include "SpawnerHandler.hpp"

using json = nlohmann::json;
#ifndef USE_BOOST_FS
#include <filesystem>
namespace fs = std::filesystem;
#else
#include <boost/filesystem.hpp>
namespace fs = boost::filesystem;
#endif

class Task {
 public:
  Task(long _id, std::string _cmd, const json &_input = nullptr)
      : task_id(_id), command(std::move(_cmd)), input(_input) {};
  Task() : task_id(-1) {};
  long task_id;
  std::string command;
  json input;
  TaskResult Run(Logger &logger,
                 SpawnerHandler &sh,
                 const std::chrono::system_clock::time_point &ref_time,
                 const std::string &work_base_dir,
                 long timeout) const {
    const fs::path work_dir = WorkDirPath(work_base_dir);

    fs::create_directories(work_dir);
    if (!input.is_null()) {
      std::ofstream fout(InputFilePath(work_base_dir).string());
      fout << input;
      fout.flush();  // explicitly flush fout
    }

    auto start_at = std::chrono::system_clock::now();
    long s_at = std::chrono::duration_cast<std::chrono::milliseconds>(start_at - ref_time).count();
    logger.d("Starting task %d at %s, timeout %d sec", task_id, work_dir.c_str(), timeout);
    int rc = sh.System(command, work_dir, {{"CARAVAN_TASK_TIMEOUT", std::to_string(timeout)}});
    auto finish_at = std::chrono::system_clock::now();
    long f_at = std::chrono::duration_cast<std::chrono::milliseconds>(finish_at - ref_time).count();
    logger.d("Completed task %d", task_id);

    int my_rank;
    MPI_Comm_rank(MPI_COMM_WORLD, &my_rank);
    TaskResult res(task_id, rc, my_rank, s_at, f_at);

    const fs::path res_path = OutputFilePath(work_base_dir);
    logger.d("Output file %s", res_path.c_str());
    if (fs::exists(res_path)) {
      size_t res_size = fs::file_size(res_path);
      logger.d("Output file is found for task %d (%d bytes)", task_id, res_size);
      json j;
      std::ifstream fin(res_path.string());
      fin >> j;
      res.output = j;
      logger.d("Output: %s", res.output.dump().c_str());
    }

    return res;
  }
  fs::path WorkDirPath(const std::string &work_base_dir) const {
    char buf[256];
    int n = std::snprintf(buf, sizeof(buf), "%s/w%04ld/w%07ld", work_base_dir.c_str(), task_id / 1000, task_id);
    assert(n >= 0 && n < 256);
    return fs::path(buf);
  }
  fs::path InputFilePath(const std::string &work_base_dir) const {
    auto p = WorkDirPath(work_base_dir);
    p.append("_input.json");
    return p;
  }
  fs::path OutputFilePath(const std::string &work_base_dir) const {
    auto p = WorkDirPath(work_base_dir);
    p.append("_output.json");
    return p;
  }
};

void to_json(json &j, const Task &t) {
  j = json{{"id", t.task_id}, {"cmd", t.command}, {"input", t.input}};
}

void from_json(const json &j, Task &t) {
  j.at("id").get_to(t.task_id);
  j.at("cmd").get_to(t.command);
  t.input = j.at("input");
}

#endif //CARAVAN_SCHEDULER_TASK_HPP
