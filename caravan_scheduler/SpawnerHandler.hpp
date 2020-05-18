//
// Created by Yohsuke Murase on 2020/05/16.
//

#ifndef CARAVAN_SCHEDULER__SPAWNERHANDLER_HPP_
#define CARAVAN_SCHEDULER__SPAWNERHANDLER_HPP_

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

typedef std::vector<std::pair<std::string, std::string>> env_t;

class SpawnerHandler {
 public:
  SpawnerHandler(int read_fd, int write_fd, int child_pid)
      : r_fd(read_fd), w_fd(write_fd), pid(child_pid), terminated(false) {};
  ~SpawnerHandler() {
    std::cerr << "Handler destructor" << std::endl;
    if (!terminated) { Terminate(); }
  }
  SpawnerHandler(SpawnerHandler&&) = default;
  int System(const std::string &cmd, const fs::path &work_dir = fs::current_path(),
             const env_t &envs = {}) {
    std::cerr << "System is called at Handler: " << cmd << std::endl;
    json j = {
        {"command", cmd},
        {"work_dir", work_dir.string()},
        {"envs", envs}
    };
    SendBytes(json::to_msgpack(j));
    int rc = ReceiveInt();
    std::cerr << "System done: " << rc << std::endl;
    return rc;
  }
  void Terminate() {
    close(r_fd);
    close(w_fd);
    waitpid(pid, nullptr, 0);
    terminated = true;
  };
 private:
  void SendBytes(const std::vector<uint8_t> &bytes) {
    uint64_t n = bytes.size();
    write(w_fd, &n, sizeof(uint64_t)); // send size
    write(w_fd, bytes.data(), bytes.size()); // send bytes
  }
  int ReceiveInt() {
    int n = 0;
    size_t s = read(r_fd, &n, sizeof(int));
    assert(s == sizeof(int));
    return n;
  }

  const int r_fd, w_fd, pid;
  bool terminated;
};

#endif //CARAVAN_SCHEDULER__SPAWNERHANDLER_HPP_
