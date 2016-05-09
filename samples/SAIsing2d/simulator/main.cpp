#include <cmath>

// Non-monotonic Ishigami Function (3 parameters)
// First-order indices:
// x1: 0.3139
// x2: 0.4424
// x3: 0.0
double RunSimulator( double x1, double x2, double x3 ) {
  return std::sin(x1) + 7.0*std::pow( std::sin(x2), 2.0) + 0.1*std::pow(x3,4.0)*std::sin(x1);
}

