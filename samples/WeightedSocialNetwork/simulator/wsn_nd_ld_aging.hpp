#ifndef WSN_ND_LD_AGING_HPP
#define WSN_ND_LD_AGING_HPP

#include <omp.h>
#include <cstdlib>
#include <cassert>
#include <iostream>
#include <fstream>
#include <list>
#include <map>
#include <set>
#include <sstream>
#include <boost/cstdint.hpp>
#include <boost/random.hpp>
#include "random.hpp"
#include "node.hpp"

//================================================
class WsnNDLDAging {
public:
  WsnNDLDAging(
    uint64_t seed, size_t net_size, double p_tri, double p_jump, double delta,
    double p_nd, double p_ld, double aging, double w_th
  );
  ~WsnNDLDAging() {};
  void Run( uint32_t tmax);
  void PrintEdge( std::ofstream& fout);
  void ToJson( std::ostream & out ) const;
protected:
  // parameters
  const uint64_t m_seed;
  const size_t m_net_size;
  const double m_p_tri;
  const double m_p_jump;
  const double m_delta;
  const double m_p_nd;
  const double m_p_ld;
  const double m_aging;
  const double m_link_th;

  // state variables
  std::vector<Node> m_nodes;
  typedef std::vector<Node>::iterator NodeIt;
  std::vector< std::pair<Node*,Node*> > m_enhancements;
  typedef std::vector< std::pair<Node*,Node*> >::iterator EnhanceIt;
  std::vector< std::pair<Node*,Node*> > m_attachements;
  typedef std::vector< std::pair<Node*,Node*> >::iterator AttachIt;
  std::vector<double> m_p_sums;

  void LocalAndGlobalAttachement(); // LA and GA
  void LA();
  void GA();
  void AttachPair(Node* i, Node* j, std::vector< std::pair<Node*,Node*> >& attachements);
  void EnhancePair(Node* i, Node* j, std::vector< std::pair<Node*,Node*> >& enhancements);
  void StrengthenEdges();
  void LinkDeletion();
  void LinkAging();
  void NodeDeletion();
  void DeleteNode(Node* ni);
  Node* RandomSelectExceptForNeighbors(Node* i);
  double AverageDegree();
  double AverageStrength();

  // non-copyable
  WsnNDLDAging(const WsnNDLDAging&);
  WsnNDLDAging& operator=(const WsnNDLDAging&);
};

#endif
