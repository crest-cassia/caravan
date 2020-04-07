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
  int pid;
  int sock;

  long LaunchSearcher( const std::vector<std::string>& argvs ) {
    long rc = ForkExec(argvs);
    WaitServerIsReady();
    return rc;
  }

  int ForkExec(const std::vector<std::string>& argvs) {
    std::vector<char*> temp;
    std::transform(argvs.begin(), argvs.end(), std::back_inserter(temp), [](const std::string& s)->char* {
      char* pc = new char[s.size() + 1];
      std::strcpy(pc, s.c_str());
      return pc;
    });
    temp.push_back(nullptr);
    char* const* argv = temp.data();

    if ( (pid = fork()) < 0 ) {
      perror("ForkExec");
      return -1;
    }
    if (pid == 0) { // at the child process
      // execute subprocess
      if (execvp(argv[0], argv) < 0) {
        perror("ForkExec");
        return 1;
      }
    }
    for(size_t i = 0 ; i < temp.size()-1; i++) { delete [] temp[i]; }

    return 0;
  }

  void WaitServerIsReady() {
    struct sockaddr_in server;
    server.sin_family = AF_INET;
    server.sin_port = htons(50007);
    server.sin_addr.s_addr = inet_addr("127.0.0.1");

    while(true) {
      usleep(100*1000); // sleep for 100ms
      sock = socket(AF_INET, SOCK_STREAM, 0);
      if( sock < 0 ) { throw std::runtime_error("failed to create a socket"); }
      int err = connect(sock, (struct sockaddr *)&server, sizeof(server));
      if(err == 0) break;
      std::cerr << "waiting for connection. retrying..." << std::endl;
      close(sock);
      int dead = waitpid(pid, nullptr, WNOHANG); // child process is dead
      if(dead) { throw std::runtime_error("server process is dead"); }
    }
  }

  void WaitSearcher() {
    waitpid(pid, nullptr, 0);
  }

  std::vector<uint8_t> ReceiveBytes(size_t n) {
    const size_t L = 4096;
    std::vector<uint8_t> buf(n);
    size_t idx = 0;
    while(idx < n) {
      size_t n_rec = recv(sock, &buf[idx], std::min(n-idx,L), 0);
      if(n_rec == 0) { // pipe is broken
        int dead = waitpid(pid, nullptr, WNOHANG);
        if(dead) { throw std::runtime_error("search_engine is dead"); }
        sleep(1);
      }
      idx += n_rec;
    }
    assert(idx == n);
    return std::move(buf);
  }

  inline std::vector<Task> ReadTasks() {
    std::vector<uint8_t> b1 = ReceiveBytes(8);
    size_t s = FromBigEndian(b1);
    std::vector<uint8_t> buf = ReceiveBytes(s);

    json tasks_j = json::from_msgpack(buf);
    std::vector<Task> tasks;
    for(const json& x: tasks_j) {
      tasks.emplace_back(x);
    }
    return tasks;
  }

  std::vector<Task> CreateInitialTasks() {
    return ReadTasks();
  }

  uint64_t FromBigEndian(const std::vector<uint8_t>& buf) {
    assert(buf.size() == 8);
    uint64_t x=1; // 0x00000001
    bool is_little = (*(char *) &x == 1);

    uint64_t out;
    auto* ptr = (unsigned char*) &out;
    ptr[0] = is_little ? buf[7] : buf[0];
    ptr[1] = is_little ? buf[6] : buf[1];
    ptr[2] = is_little ? buf[5] : buf[2];
    ptr[3] = is_little ? buf[4] : buf[3];
    ptr[4] = is_little ? buf[3] : buf[4];
    ptr[5] = is_little ? buf[2] : buf[5];
    ptr[6] = is_little ? buf[1] : buf[6];
    ptr[7] = is_little ? buf[0] : buf[7];
    return out;
  }

  std::vector<uint8_t> ToBigEndian(size_t i) {
    uint64_t x=1; // 0x00000001
    bool is_little = (*(char *) &x == 1);

    std::vector<uint8_t> tmp(8);
    auto* ptr = (unsigned char*) &i;
    tmp[0] = is_little ? ptr[7] : ptr[0];
    tmp[1] = is_little ? ptr[6] : ptr[1];
    tmp[2] = is_little ? ptr[5] : ptr[2];
    tmp[3] = is_little ? ptr[4] : ptr[3];
    tmp[4] = is_little ? ptr[3] : ptr[4];
    tmp[5] = is_little ? ptr[2] : ptr[5];
    tmp[6] = is_little ? ptr[1] : ptr[6];
    tmp[7] = is_little ? ptr[0] : ptr[7];
    return tmp;
  }

  void SendBytes(const std::vector<uint8_t>& buf) {
    send(sock, buf.data(), buf.size(), 0);
  }

  std::vector<Task> SendResult( const std::vector<uint8_t>& result_buf ) {
    std::vector<uint8_t> size_b = ToBigEndian(result_buf.size());
    SendBytes(size_b);
    SendBytes(result_buf);
    return ReadTasks();
  }

  void SendEmptyLine() {
    std::vector<uint8_t> size_b = ToBigEndian(0);
    SendBytes(size_b);
  }

};

#endif //CARAVAN_SCHEDULER_SEARCHENGINE_HPP
