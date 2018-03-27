import sys, os, json
import matplotlib.pyplot as plt
import numpy

fname = os.path.dirname(__file__) + "/pareto_front/zdt1_front.json"
with open(fname) as optimal_front_data:
    optimal_front = json.load(optimal_front_data)

# Use 500 of the 1000 points in the json file
optimal_front = sorted(optimal_front[i] for i in range(0, len(optimal_front), 2))


def load_population_data(path):
    return numpy.loadtxt(path)


front = load_population_data("fitness.txt")
optimal_front = numpy.array(optimal_front)
plt.scatter(optimal_front[:, 0], optimal_front[:, 1], c="r")
plt.scatter(front[:, 0], front[:, 1], c="b")
plt.axis("tight")
plt.show()
