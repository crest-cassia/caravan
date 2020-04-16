import math,json

with open('_input.json') as f:
    x = json.load(f)
x1,x2,x3 = x['x1'],x['x2'],x['x3']
y = math.sin(x1) + 7.0*(math.sin(x2))**2 + 0.1*(x3**4)*math.sin(x1)
with open('_output.json', 'w') as f:
    json.dump({"y": y}, f)
