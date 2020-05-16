//
// Created by Yohsuke Murase on 2020/05/16.
//

#ifndef CARAVAN_SCHEDULER__SPAWNER_HPP_
#define CARAVAN_SCHEDULER__SPAWNER_HPP_

#include <iostream>
#include <vector>
#include <unistd.h>
#include <nlohmann/json.hpp>

using json = nlohmann::json;

#ifndef USE_BOOST_FS
#include <filesystem>
namespace fs = std::filesystem;
#else
#include <boost/filesystem.hpp>
namespace fs = boost::filesystem;
#endif

class Spawner {
 public:
  Spawner(int read_fd, int write_fd) : r_fd(read_fd), w_fd(write_fd) {};
  ~Spawner() {
    std::cerr << "destructing spawner" << std::endl;
    close(r_fd);
    close(w_fd);
  }
  void Run() {
    std::cerr << "spawner running" << std::endl;
    while (true) {
      const json j = Receive();
      std::cerr << "received: " << j << std::endl;
      if (j.empty()) { break; }
      const std::string cmd = j.at("command");
      const fs::path work_dir = j.at("work_dir");
      const auto env = j.at("envs");
      std::cerr << "launching command: " << cmd << std::endl;
      int rc = System(cmd, work_dir, env);
      write(w_fd, &rc, sizeof(int));
    }
  }
 private:
  const int r_fd, w_fd;
  json Receive() {
    uint64_t size = 0;
    int n_rec = read(r_fd, &size, sizeof(uint64_t));
    if (n_rec == 0) { // reached EOF
      std::cerr << "got EOF" << std::endl;
      return json();
    }
    std::vector<uint8_t> buf(size);
    n_rec = read(r_fd, buf.data(), size);
    assert(n_rec == size);
    return std::move(json::from_msgpack(buf));
  }

  typedef std::vector<std::vector<std::string>> env_t;
  int System(const std::string &cmd, const fs::path &work_dir, const env_t &envs) {
    // [TODO] implement envs
    const fs::path cwd = fs::current_path();
    fs::current_path(work_dir);
    int rc = std::system(cmd.c_str());
    fs::current_path(cwd);
    return rc;
  }



};

#endif //CARAVAN_SCHEDULER__SPAWNER_HPP_
