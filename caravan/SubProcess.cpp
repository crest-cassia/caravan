#include <iostream>
#include <vector>
#include <cstdio>
#include <cstdlib>
#include <cstring>
#include <unistd.h>
#include <x10/lang/Rail.h>
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

x10::lang::Rail<x10::lang::String*>* readLinesUntilEmpty(FILE* fp_r) {
  size_t buf_size = 512;
  char* buf = (char*) malloc(buf_size);

  std::vector<x10::lang::String*> lines;

  int len = getline( &buf, &buf_size, fp_r );
  lntrim(buf);
  while( strlen(buf) > 0 ) {
    // std::cerr << "[DEBUG] reading: " << buf << std::endl;
    x10::lang::String* val = x10::lang::String::_make(buf, false);
    lines.push_back(val);
    len = getline( &buf, &buf_size, fp_r );
    lntrim(buf);
  }
  // std::cerr << "[DEBUG] reading task end" << std::endl;
  free(buf);

  size_t num_lines = lines.size();
  x10::lang::Rail<x10::lang::String*>* arr(x10::lang::Rail<x10::lang::String*>::_make(num_lines));
  for (int i = 0; i < num_lines; i++) {
    arr->__set(i, lines[i]);
  }
  return arr;
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

  delete [] argv;

  return 0l;
}

