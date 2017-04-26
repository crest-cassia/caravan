#include "ising2d.hpp"

Ising2D::Ising2D( uint32_t lx, uint32_t ly, double beta, double h, uint64_t seed) :
m_lx(lx), m_ly(ly), m_beta(beta), m_h(h), m_seed(seed)
{
  ValidateParameters();
  SystemInitialization();
}

Ising2D::~Ising2D() {
  delete pRnd;
  // Release Memory
}

void Ising2D::ValidateParameters() {
  // validate parameters
  if ( m_lx % 2 == 0 ) {
    std::cerr << "Error! Lx must be odd" << std::endl;
    throw "invalid parameters";
  }
  if ( m_ly % 2 == 1 ) {
    std::cerr << "Error! Ly must be even" << std::endl;
    throw "invalid parameters";
  }
  if ( m_beta < 0.0 ) {
    std::cerr << "Error! beta must be positive" << std::endl;
    throw "invalid parameters";
  }
}

std::string Ising2D::SerializeParameters() {
  std::ostringstream oss;
  oss << "Lx: " << m_lx << ",\n"
      << "Ly: " << m_ly << ",\n"
      << "beta: " << m_beta << ",\n"
      << "h: "  << m_h  << ",\n";
  return oss.str();
}

void Ising2D::SystemInitialization() {
  uint32_t numAlloc = m_lx * (m_ly + 2);
  m_spins.assign(numAlloc, 1);
  // Hamiltonian for this system is
  //    H = - J \sum_{n.n.} \sigma_i \sigma_j - h \sum_i sigma_i
  for( int nCenterUp = 0; nCenterUp < 2; nCenterUp++) {
    for( int nNeighborUp = 0; nNeighborUp < 5; nNeighborUp++) {
      double ene_before = 0.0;
      int nNeighborDown = 4 - nNeighborUp;
      if ( nCenterUp == 1 ) {
        ene_before = - nNeighborUp + nNeighborDown;
        ene_before -= m_h;
      }
      else {
        ene_before = - nNeighborDown + nNeighborUp;
        ene_before += m_h;
      }

      double dE = -2.0 * ene_before;
      double p = exp( -m_beta*dE );
      m_trans[nCenterUp][nNeighborUp] = p;
    }
  }

  pRnd = new std::mt19937(m_seed);
  m_spins.assign( m_lx * (m_ly + 2) , 1);
}

void Ising2D::Update() {
  std::uniform_real_distribution<double> uni_dist(0.0,1.0);

  // update odd spins
  for( size_t i=m_lx; i < m_lx + m_lx * m_ly; i+=2) {
    double rnd = uni_dist(*pRnd);
    UpdateSpin(i, rnd);
  }
  CopyBoundarySpins();

  // update even spins
  for( size_t i=m_lx+1; i < m_lx + m_lx * m_ly; i+=2) {
    double rnd = uni_dist(*pRnd);
    UpdateSpin(i, rnd);
  }
  CopyBoundarySpins();
}

void Ising2D::UpdateSpin(size_t i, double random) {
  int neighbor_spins = m_spins[i-m_lx] + m_spins[i-1] + m_spins[i+1] + m_spins[i+m_lx];
  int center = m_spins[i];
  double trans = m_trans[center][neighbor_spins];
  if( random < trans ) {
    m_spins[i] = (m_spins[i] == 1) ? 0 : 1;
  }
}

void Ising2D::CopyBoundarySpins() {
  for( size_t i=0; i < m_lx; i++) {
    m_spins[i] = m_spins[i + m_lx * m_ly];
    m_spins[i + m_lx + m_lx * m_ly] = m_spins[i + m_lx];
  }
}

std::pair<double, double> Ising2D::UpdateAndMeasure() {
  Update();

  int32_t sum = 0;
  int32_t coupling = 0;
  for( size_t i = m_lx; i < m_lx + m_lx * m_ly; i++) {
    sum += (m_spins[i] * 2 - 1);
    coupling += -1 * (m_spins[i] * 2 - 1) * (m_spins[i-m_lx] * 2 - 1);
    coupling += -1 * (m_spins[i] * 2 - 1) * (m_spins[i-1] * 2 - 1);
  }
  double op = static_cast<double>(sum) / (m_lx * m_ly);
  double energy = static_cast<double>(coupling) / (m_lx * m_ly);
  energy += - m_h * op;

  return std::make_pair(op, energy);
}
