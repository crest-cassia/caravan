//
// Created by Yohsuke Murase on 2020/05/16.
//

#ifndef CARAVAN_SCHEDULER__SPAWNER_HPP_
#define CARAVAN_SCHEDULER__SPAWNER_HPP_

#include <iostream>
#include <vector>
#include <utility>
#include <cstdlib>
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
    close(r_fd);
    close(w_fd);
  }
  void Run() {
    while (true) {
      const json j = Receive();
      // std::cerr << "received: " << j << std::endl;
      if (j.empty()) { break; }
      const std::string cmd = j.at("command");
      const fs::path work_dir = j.at("work_dir");
      const auto env = j.at("envs");
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
      return json();
    }
    std::vector<uint8_t> buf(size);
    n_rec = read(r_fd, buf.data(), size);
    assert(n_rec == size);
    return std::move(json::from_msgpack(buf));
  }

  typedef std::vector<std::vector<std::string>> env_t;
  int System(const std::string &cmd, const fs::path &work_dir, const env_t &envs) {
    std::vector<std::pair<std::string, std::string> > org_envs;
    for (const auto &keyval : envs) {
      const std::string key = keyval.at(0);
      const char *org_val = std::getenv(key.c_str());
      if (org_val != nullptr) {
        org_envs.emplace_back(std::make_pair(key, org_val));
      } else {
        org_envs.emplace_back(std::make_pair(key, ""));
      }
      setenv(key.c_str(), keyval.at(1).c_str(), 1);
    }

    const fs::path cwd = fs::current_path();
    fs::current_path(work_dir);
    int rc = std::system(cmd.c_str());
    fs::current_path(cwd);

    for (const auto &keyval : org_envs) {
      if (keyval.second.empty()) {
        unsetenv(keyval.first.c_str());
      } else {
        setenv(keyval.first.c_str(), keyval.second.c_str(), 1);
      }
    }

    return rc;
  }
};

#endif //CARAVAN_SCHEDULER__SPAWNER_HPP_
