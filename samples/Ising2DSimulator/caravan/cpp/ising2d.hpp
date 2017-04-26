#ifndef ISING2D_HPP
#define ISING2D_HPP

#include <iostream>
#include <string>
#include <vector>
#include <cassert>
#include <fstream>
#include <sstream>
#include <array>
#include <random>
#include <cstdint>

// Simple Ising model simulation on square lattice
// Metropolic transition probability
// checker-board decomposition update
class Ising2D {
public:
  Ising2D( uint32_t lx, uint32_t ly, double beta, double h, uint64_t seed);
  virtual ~Ising2D();
  void Update();
  std::pair<double, double> UpdateAndMeasure();
  double AverageOrderParameter();
  double AverageOrderParameterSquare();
  double Energy();
  std::string SerializeParameters();
  void DumpJson(std::string sOutputJsonPath);
private:
  const uint32_t m_lx, m_ly; // system sizes
  const double m_beta;  // inverse temperature (J is fixed to 1.0)
  const double m_h;
  const uint32_t m_seed;
  std::mt19937 * pRnd;
  std::vector<int8_t> m_spins; // upspin : 1, downspin: 0
  std::array< std::array<double, 5>, 2 > m_trans;
  void ValidateParameters();
  void SystemInitialization();
  void UpdateSpin(size_t i, double dRnd);  // udpate spin[i]
  void CopyBoundarySpins();
};

#endif // ISING2D_HPP
