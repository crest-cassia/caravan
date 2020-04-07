import json

def calc(x, y):
    v = (x - 1.0) ** 2 + (y - 2.0) ** 2
    return v

with open("_input.json") as fin:
    p = json.load(fin)
    f = calc(p['x'], p['y'])
    with(open("_output.json",'w')) as fout:
        json.dump({'f':f}, fout)

