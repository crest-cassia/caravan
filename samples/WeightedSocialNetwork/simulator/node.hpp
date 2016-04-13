#ifndef NODE_HPP
#define NODE_HPP

#include <cassert>
#include <iostream>
#include <vector>
#include <sstream>
#include "random.hpp"

class Node;

//=================================================
class Edge {
public:
  Edge(Node* n, double w0) {
    node = n;
    weight = w0;
  }
  Node* node;
  double weight;
};

//=================================================
class Node {
public:
  Node(size_t id) : m_id(id) {}
  size_t GetId() const { return m_id; }

  // randomly select edge with the probability proportional to its weight
  // if excluded_node is not NULL, the parent node is not included in the candidates
  // when excluded_node is NULL, the edge is selected from all the connecting edges
  Edge* EdgeSelection(Node* excluded_node);
  size_t Degree() const { return m_edges.size(); }
  double Strength() const;
  Edge* FindEdge(Node* nj);  // return the pointer to edge. If not found, return NULL;
  void AddEdge(Node* nj, double initial_weight);
  void EnhanceEdge(Node* nj, double delta);
  void DeleteEdge(Node* nj);
  void AgingEdge(double aging_factor, double threshold);
  const std::vector<Edge>& GetEdges() const { return m_edges; }
  void ClearAll() { m_edges.clear(); }
protected:
  size_t m_id;
  std::vector<Edge> m_edges;
  typedef std::vector<Edge>::iterator EdgeIt;
  typedef std::vector<Edge>::const_iterator CEdgeIt;
};

#endif
