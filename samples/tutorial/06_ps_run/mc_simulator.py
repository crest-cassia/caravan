import sys,random,json

with open('_input.json') as f:
    param = json.load(f)
    mu = param['mu']
    sigma = param['sigma']
    random.seed(param['_seed'])
    print(random.normalvariate(mu,sigma))
