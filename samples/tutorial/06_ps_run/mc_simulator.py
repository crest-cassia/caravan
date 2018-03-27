import sys, random

mu = float(sys.argv[1])
sigma = float(sys.argv[2])
random.seed(int(sys.argv[3]))
print(random.normalvariate(mu, sigma))
