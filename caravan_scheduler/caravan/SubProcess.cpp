#include <iostream>
#include <vector>
#include <cstdio>
#include <cstdlib>
#include <cstring>
#include <unistd.h>
#include <sys/types.h>
#include <sys/wait.h>
#include <sys/poll.h>
#include <signal.h>
#include <x10/lang/Rail.h>
#include <x10/util/ArrayList.h>
#include <x10/lang/String.h>

int popen2(char*const* argv, int *fd_r, int *fd_w) {

  const size_t READ = 0;
  const size_t WRITE = 1;

  int pipe_child2parent[2];
  int pipe_parent2child[2];
  int pid;

  if (pipe(pipe_child2parent) != 0 ||
    pipe(pipe_parent2child) != 0 ||
    (pid = fork()) < 0
    ) {
    perror("popen2");
    close(pipe_child2parent[READ]);
    close(pipe_child2parent[WRITE]);
    close(pipe_parent2child[READ]);
    close(pipe_parent2child[WRITE]);
    return -1;
  }

  if (pid == 0) { // at the child process
    close(pipe_parent2child[WRITE]);
    close(pipe_child2parent[READ]);
    dup2(pipe_parent2child[READ], 0);
    dup2(pipe_child2parent[WRITE], 1);
    close(pipe_parent2child[READ]);
    close(pipe_child2parent[WRITE]);

    // execute subprocess
    if (execvp(argv[0], argv) < 0) {
        perror("popen2");
        close(pipe_parent2child[READ]);
        close(pipe_child2parent[WRITE]);
        return 1;
    }
  }

  // at the parent process
  close(pipe_parent2child[READ]);
  close(pipe_child2parent[WRITE]);

  *fd_r = pipe_child2parent[READ];
  *fd_w = pipe_parent2child[WRITE];

  return pid;
}


void lntrim(char *str) {  
  char *p;  
  p = strchr(str, '\n');  
  if(p != NULL) {  
    *p = '\0';  
  }  
}

long waitIncomingData(long fd_r, long timeout, long pid) {
  int rc = 0;
  struct pollfd fds[1];
  fds[0].fd = (int)fd_r;
  fds[0].events = POLLIN;
  fds[0].revents = 0;

  rc = poll(fds,1,timeout);
  while( rc == 0 ) {
    if( kill(pid,0) != 0 ) {
      return 1; // sub-process is dead
    }
  }

  if( rc < 0 ) {
    return -1; // poll call failed
  }
  return 0;  // ready to read
}

x10::lang::Rail<x10::lang::String*>* readLinesUntilEmpty(FILE* fp_r) {
  size_t buf_size = 512;
  char* buf = (char*) malloc(buf_size);

  x10::util::ArrayList<x10::lang::String*>* lines = x10::util::ArrayList<x10::lang::String*>::_make();

  int len = getline( &buf, &buf_size, fp_r );
  lntrim(buf);
  while( strlen(buf) > 0 ) {
    // std::cerr << "[DEBUG] reading: " << buf << std::endl;
    x10::lang::String* val = x10::lang::String::_make(buf, false);
    lines->add(val);
    len = getline( &buf, &buf_size, fp_r );
    lntrim(buf);
  }
  free(buf);

  return lines->toRail();
}

void writeLine(FILE* fp_w, x10::lang::String* line) {
  // std::cerr << "[DEBUG] writing: " << p_s->c_str() << std::endl;
  fprintf(fp_w, "%s\n", line->c_str() );
  fflush(fp_w);
  // std::cerr << "[DEBUG] writing end" << std::endl;
}

long launchSubProcessWithPipes( x10::lang::Rail<x10::lang::String*>* x10_argv, long* fps_pid) {

  size_t size = x10_argv->FMGL(size);
  char** argv = new char*[size+1];
  for( size_t i=0; i < x10_argv->FMGL(size); i++) {
    x10::lang::String* ps = x10_argv->raw[i];
    argv[i] = const_cast<char*>( ps->c_str() );
  }
  argv[size] = NULL;

  int fd_r, fd_w;
  int pid = popen2( argv, &fd_r, &fd_w);
  if( pid < 0 ) {
    return -1l;
  }
  FILE* fp_r = fdopen(fd_r, "r");
  FILE* fp_w = fdopen(fd_w, "w");
  fps_pid[0] = pid;
  fps_pid[1] = (long) fp_r;
  fps_pid[2] = (long) fp_w;
  fps_pid[3] = (long) fd_r;
  fps_pid[4] = (long) fd_w;

  delete [] argv;

  return 0l;
}

x10::lang::String* getCWD() {
  char cwd[1024];
  if( getcwd(cwd, sizeof(cwd)) != NULL ) {
    return x10::lang::String::_make(cwd, false);
  }
  else {
    return x10::lang::String::_make("", false);
  }
}

void waitPid(long pid) {
  waitpid(pid, NULL, 0);
}

