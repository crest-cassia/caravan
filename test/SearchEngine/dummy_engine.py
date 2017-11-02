from __future__ import print_function
import sys

def submit(i,cmd,point,seed):
    s_point = " ".join( [str(x) for x in point] )
    out = "%d %s %d %s %d" % (i,cmd,i,s_point,seed)
    sys.stderr.write("[dummy] printing: %s\n" % out)
    print(out)

for i in range(3):
    submit(i,"./foobar.out",(i+1,i+2,3-i), i+1000)
sys.stderr.write("[dummy] printing an empty line:\n")
print("")

def read_a_line():
    return sys.stdin.readline().rstrip()

idx = 4
while True:
    line = read_a_line()
    if len(line) == 0:
        break
    sys.stderr.write("[dummy] received: %s\n" % line)
    submit(idx,"./foobar2.out",(2,3,4),1234)
    idx += 1
    sys.stderr.write("[dummy] printing an empty line:\n")
    print("")

sys.stderr.write("ending python\n")

