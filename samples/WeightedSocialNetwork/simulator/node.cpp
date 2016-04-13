#include <omp.h>
#include <cmath>
#include <algorithm>
#include <boost/foreach.hpp>
#include "node.hpp"

double Node::Strength() const {
  double weight_sum = 0.0;
  for( std::vector<Edge>::const_iterator it = m_edges.begin(); it != m_edges.end(); ++it) {
    weight_sum += it->weight;
  }
  return weight_sum;
}

Edge* Node::EdgeSelection(Node* parent_node) {
  double prob_sum = 0.0;
  std::vector<double> probs( m_edges.size(), 0.0 );
  for(CEdgeIt it = m_edges.begin(); it != m_edges.end(); ++it) {
    if( it->node != parent_node ) {
      prob_sum += it->weight;
    }
    probs[ it - m_edges.begin() ] = prob_sum;
  }

  double r = prob_sum * Random::Rand01( omp_get_thread_num() );
  std::vector<double>::iterator found = std::upper_bound(probs.begin(), probs.end(), r);
  assert( found != probs.end() );
  return &(m_edges[ found - probs.begin() ]);
}

Edge* Node::FindEdge(Node* nj) {
  for( EdgeIt it = m_edges.begin(); it != m_edges.end(); ++it) {
    if( it->node == nj ) { return &(*it); }
  }
  return NULL;
}

void Node::AddEdge(Node* nj, double initial_weight) {
  assert( FindEdge(nj) == NULL );
  m_edges.push_back(Edge(nj, initial_weight));
}

void Node::EnhanceEdge(Node* nj, double delta) {
  Edge* edge = FindEdge(nj);
  assert(edge != NULL);
  #pragma omp atomic
  edge->weight += delta;
}

void Node::DeleteEdge(Node* nj) {
  Edge* edge = FindEdge(nj);
  assert(edge != NULL);
  *edge = m_edges.back();
  m_edges.pop_back();
  assert( FindEdge(nj) == NULL );
}

class IsLessThanThreshold {
public:
  IsLessThanThreshold(double th) : m_threshold(th) {};
  bool operator()(Edge edge) const {
    return (edge.weight < m_threshold) ? true : false;
  }
private:
  const double m_threshold;

};

void Node::AgingEdge(double aging_factor, double threshold) {
  for( EdgeIt it = m_edges.begin(); it != m_edges.end(); ++it) {
    it->weight *= aging_factor;
  }
  IsLessThanThreshold pred(threshold);
  m_edges.erase( std::remove_if(m_edges.begin(), m_edges.end(), pred),
                 m_edges.end());
}

