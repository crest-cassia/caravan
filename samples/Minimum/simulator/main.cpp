#include <cstdlib>

double RunSimulator( long p1, long p2, double p3, long seed ) {
  srand(seed);
  return 0.1 * ( p2 + p1*p3+ (rand()%5) );
}

