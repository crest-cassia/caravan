#include <cstdio>
#include <unistd.h>
#include <x10/lang/String.h>

long launchSubProcessWithPipes( x10::lang::Rail<x10::lang::String*>* x10_argv, long* fps_pid);
x10::lang::Rail<x10::lang::String*>* readLinesUntilEmpty(FILE* fp_r);
void writeLine(FILE* fp_w, x10::lang::String* line);
x10::lang::String* getCWD();
void waitPid(long pid);

