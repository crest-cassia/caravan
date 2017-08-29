from __future__ import print_function
import sys

def submit(i,cmd,point,seed):
    s_point = " ".join( [str(x) for x in point] )
    out = "%d %s %d %s %d" % (i,cmd,i,s_point,seed)
    print(out)

for i in range(3):
    submit(i,"./foobar.out",(i+1,i+2,3-i), i+1000)
print("")

def readlines_until_empty():
    lines = []
    while True:
        line = sys.stdin.readline().rstrip()
        if not line:
            break
        lines.append(line)
    return lines


while True:
    lines = readlines_until_empty()
    if len(lines) == 0:
        break
    for line in lines:
        sys.stderr.write("[dummy] received: %s\n" % line)
        submit(4,"./foobar2.out",(2,3,4),1234)
    print("")

sys.stderr.write("ending python\n")

