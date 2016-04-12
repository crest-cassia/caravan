#include <iostream>
#include <string>
#include "ising2d.cpp"

double RunSimulator(
  long lx,
  long ly,
  double beta,
  double h,
  long t_init,
  long t_measure,
  long seed
  ) {
  
  Ising2D sim(
      static_cast<uint32_t>(lx),
      static_cast<uint32_t>(ly),
      beta,
      h,
      static_cast<uint32_t>(seed) );
  // std::cout << sim.SerializeParameters() << std::endl;

  for( uint32_t t = 0; t < static_cast<uint32_t>(t_init); t++) {
    sim.Update();
  }

  double op_sum = 0.0;
  double op_square_sum = 0.0;
  double energy_sum = 0.0;
  for( uint32_t t = 0; t < static_cast<uint32_t>(t_measure); t++) {
    std::pair<double, double> ret = sim.UpdateAndMeasure();
    op_sum += ret.first;
    op_square_sum += ret.first * ret.first;
    energy_sum += ret.second;
    // std::cout << t << ' ' << ret.first << ' ' << ret.second << std::endl;
  }

  return op_sum / t_measure;
}

