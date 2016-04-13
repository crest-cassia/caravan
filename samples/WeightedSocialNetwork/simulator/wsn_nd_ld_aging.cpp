#include <cmath>
#include "wsn_nd_ld_aging.hpp"

WsnNDLDAging::WsnNDLDAging(
  uint64_t seed, size_t net_size, double p_tri, double p_jump, double delta,
  double p_nd, double p_ld, double aging, double w_th)
: m_seed(seed), m_net_size(net_size), m_p_tri(p_tri), m_p_jump(p_jump), m_delta(delta),
  m_p_nd(p_nd), m_p_ld(p_ld), m_aging(aging), m_link_th(w_th)
{
  #pragma omp parallel
  {
    int num_threads = omp_get_num_threads();
    #pragma omp master
    {
      std::cerr << "num_threads: " << num_threads << std::endl;
      Random::Init(seed, num_threads);
      for( size_t i = 0; i < m_net_size; i++) {
        Node node(i);
        m_nodes.push_back( node );
      }
    }
  }
}

void WsnNDLDAging::Run( uint32_t t_max) {
  std::ofstream fout("timeseries.dat");

  #pragma omp parallel
  {
    for( uint32_t t=0; t < t_max; ++t) {
      LocalAndGlobalAttachement();

      #pragma omp master
      {
        if( m_p_nd > 0.0 ) {
          NodeDeletion();
        }
        if( m_p_ld > 0.0 ) {
          LinkDeletion();
        }
        if( m_aging < 1.0 ) {
          LinkAging();
        }
        if( t % 128 == 127 ) {
          std::cerr << "t: " << t << std::endl;
          fout << t << ' ' << AverageDegree()
               << ' ' << AverageStrength()
               << std::endl;
        }
      }
      #pragma omp barrier
    }
  }
}

void WsnNDLDAging::PrintEdge( std::ofstream & fout) {
  for( size_t i=0; i < m_nodes.size(); i++) {
    const std::vector<Edge> edges = m_nodes[i].GetEdges();
    for( std::vector<Edge>::const_iterator it = edges.begin(); it != edges.end(); ++it) {
      size_t j = it->node->GetId();
      if( i < j ) { fout << i << ' ' << j << ' ' << it->weight << std::endl; }
    }
  }
}

void WsnNDLDAging::ToJson( std::ostream& out ) const {
  out << "{ \"num_nodes\": " << m_nodes.size() << ",\n";

  out << "\"links\": [\n";
  std::string token = "";
  for( size_t i=0; i < m_nodes.size(); i++) {
    const std::vector<Edge> edges = m_nodes[i].GetEdges();
    for( std::vector<Edge>::const_iterator it = edges.begin(); it != edges.end(); ++it) {
      size_t j = it->node->GetId();
      if( i < j ) {
        out << token << "[" << i << "," << j << "," << it->weight << "]";
        token = ",\n";
      }
    }
  }
  out << "]}";
}

double WsnNDLDAging::AverageDegree() {
  size_t total = 0;
  for( NodeIt it = m_nodes.begin(); it != m_nodes.end(); ++it) {
    total += it->Degree();
  }
  return static_cast<double>(total) / m_nodes.size();
}

double WsnNDLDAging::AverageStrength() {
  double total = 0.0;
  for( NodeIt it = m_nodes.begin(); it != m_nodes.end(); ++it) {
    total += it->Strength();
  }
  return total / m_nodes.size();
}

void WsnNDLDAging::LocalAndGlobalAttachement() {
  GA();
  StrengthenEdges();
  LA();
  StrengthenEdges();
}

void WsnNDLDAging::GA() {
  // Global attachment
  int thread_num = omp_get_thread_num();
  std::vector< std::pair<Node*,Node*> > local_attachements;

  const size_t size = m_nodes.size();
  #pragma omp for schedule(static)
  for( size_t i = 0; i < size; ++i) {
    Node * ni = &m_nodes[i];
    double r = Random::Rand01(thread_num);
    if( ni->Degree() == 0 || r < m_p_jump ) {
      if( ni->Degree() == m_net_size - 1 ) { continue; }
      Node* nj = RandomSelectExceptForNeighbors(ni);
      assert( ni->FindEdge(nj) == NULL );
      AttachPair(ni, nj, local_attachements);
    }
  }

  #pragma omp critical
  {
    m_attachements.insert(m_attachements.end(), local_attachements.begin(), local_attachements.end());
  }
  #pragma omp barrier
}

void WsnNDLDAging::LA() {
  // Local attachment
  int thread_num = omp_get_thread_num();
  std::vector< std::pair<Node*,Node*> > local_enhancements;
  std::vector< std::pair<Node*,Node*> > local_attachements;

  const size_t size = m_nodes.size();
  #pragma omp for schedule(static)
  for( size_t i=0; i < size; ++i) {
    // search first child
    Node* ni = &m_nodes[i];
    if( ni->Degree() == 0 ) { continue; }
    Edge* first_edge = ni->EdgeSelection(NULL);
    Node* first_child = first_edge->node;
    EnhancePair(ni, first_child, local_enhancements);

    // search second child
    if( first_child->Degree() == 1 ) { continue; }
    Edge* second_edge = first_child->EdgeSelection(ni);
    Node* second_child = second_edge->node;
    EnhancePair(first_child, second_child, local_enhancements);

    // connect i and second_child with p_tri
    if( ni->FindEdge(second_child) ) {
      EnhancePair(ni, second_child, local_enhancements);
    } else {
      if( Random::Rand01(thread_num) < m_p_tri ) {
        AttachPair(ni, second_child, local_attachements);
      }
    }
  }

  #pragma omp critical
  {
    m_enhancements.insert(m_enhancements.end(), local_enhancements.begin(), local_enhancements.end());
    m_attachements.insert(m_attachements.end(), local_attachements.begin(), local_attachements.end());
  }
  #pragma omp barrier
}

void WsnNDLDAging::LinkDeletion() {
  std::map<size_t, std::vector<size_t> > linksToRemove;

  for( size_t i=0; i < m_net_size; i++) {
    const std::vector<Edge>& edges = m_nodes[i].GetEdges();
    for( std::vector<Edge>::const_iterator eit = edges.begin();
         eit != edges.end();
         eit++) {
      const Edge& edge = *eit;
      size_t j = edge.node->GetId();
      if( j <= i ) { continue; }
      if( Random::Rand01( omp_get_thread_num() ) < m_p_ld ) {
        linksToRemove[i].push_back(j);
        linksToRemove[j].push_back(i);
      }
    }
  }

  for( std::map<size_t, std::vector<size_t> >::const_iterator it = linksToRemove.begin();
       it != linksToRemove.end();
       ++it ) {
    size_t i = it->first;
    const std::vector<size_t>& vecj = it->second;
    for( std::vector<size_t>::const_iterator vit = vecj.begin();
         vit != vecj.end();
         ++vit ) {
      size_t j = *vit;
      m_nodes[i].DeleteEdge( &m_nodes[j] );
    }
  }
}

void WsnNDLDAging::NodeDeletion() {
  assert( omp_get_thread_num() == 0 );
  for( size_t i=0; i < m_net_size; ++i) {
    if( Random::Rand01(0) < m_p_nd ) {
      DeleteNode(&m_nodes[i]);
    }
  }
}

void WsnNDLDAging::DeleteNode(Node* ni) {
  const std::vector<Edge> edges = ni->GetEdges();
  for( std::vector<Edge>::const_iterator it = edges.begin(); it != edges.end(); ++it) {
    Node* nj = it->node;
    nj->DeleteEdge(ni);
  }
  ni->ClearAll();
}


void WsnNDLDAging::StrengthenEdges() {
  // strengthen edges
  // #pragma omp barrier
  #pragma omp master
  {
  std::sort(m_attachements.begin(), m_attachements.end());
  m_attachements.erase( std::unique(m_attachements.begin(), m_attachements.end()), m_attachements.end() );

  for( AttachIt it = m_attachements.begin(); it != m_attachements.end(); ++it) {
    Node* ni = it->first;
    Node* nj = it->second;
    assert( ni->FindEdge(nj) == NULL );
    assert( nj->FindEdge(ni) == NULL );
    const double w_0 = 1.0;
    ni->AddEdge(nj, w_0);
    nj->AddEdge(ni, w_0);
  }
  }
  #pragma omp barrier

  const size_t en_size = m_enhancements.size();
  #pragma omp for schedule(static)
  for( size_t idx = 0; idx < en_size; idx++) {
    Node* ni = m_enhancements[idx].first;
    Node* nj = m_enhancements[idx].second;
    ni->EnhanceEdge(nj, m_delta);
    nj->EnhanceEdge(ni, m_delta);
  }

  #pragma omp master
  {
  m_attachements.clear();
  m_enhancements.clear();
  }
  #pragma omp barrier
}

void WsnNDLDAging::AttachPair(Node* ni, Node* nj, std::vector< std::pair<Node*,Node*> >& attachements) {
  std::pair<Node*, Node*> node_pair = (ni<nj) ? std::make_pair(ni, nj) : std::make_pair(nj, ni);
  attachements.push_back(node_pair);
}

void WsnNDLDAging::EnhancePair(Node * ni, Node* nj, std::vector< std::pair<Node*,Node*> >& enhancements) {
  std::pair<Node*, Node*> node_pair = (ni<nj) ? std::make_pair(ni, nj) : std::make_pair(nj, ni);
  enhancements.push_back(node_pair);
}

void WsnNDLDAging::LinkAging() {
  for( size_t i=0; i < m_net_size; i++) {
    m_nodes[i].AgingEdge(m_aging, m_link_th);
  }
}

Node* WsnNDLDAging::RandomSelectExceptForNeighbors(Node* ni) {
  int num_candidate = m_net_size - ni->Degree() - 1;
  int idx = static_cast<int>( Random::Rand01( omp_get_thread_num() ) * num_candidate );
  std::vector<int> exclude_index;
  const std::vector<Edge>& edges = ni->GetEdges();
  for( std::vector<Edge>::const_iterator it = edges.begin(); it != edges.end(); ++it) {
    exclude_index.push_back( (*it).node->GetId() );
  }
  exclude_index.push_back(ni->GetId());
  std::sort(exclude_index.begin(), exclude_index.end());
  assert( exclude_index.size() == ni->Degree() + 1 );

  for( std::vector<int>::iterator it = exclude_index.begin(); it != exclude_index.end(); ++it) {
    if( idx >= *it ) { idx += 1; }
    else { break; }
  }
  assert( idx < static_cast<int>(m_net_size) );
  return &m_nodes[idx];
}

