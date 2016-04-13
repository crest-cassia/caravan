#ifndef RANDOM_HPP
#define RANDOM_HPP

#include <iostream>
#include <boost/random.hpp>

//=================================================
// singleton class for random number generator
class Random {
public:
  static void Init(uint64_t seed, int num_threads = 1) {
    m_rnds.clear();

    for(int i=0; i <num_threads; i++) {
      m_rnds.push_back( boost::random::mt19937(seed+i) );
    }
  }
  static double Rand01(int thread_num) {
    boost::random::uniform_01<> uniform;
    return uniform(m_rnds[thread_num]);
  }
  static double Gaussian(int thread_num) {
    boost::random::normal_distribution<> gaussian;
    return gaussian(m_rnds[thread_num]);
  }
private:
  static std::vector<boost::random::mt19937> m_rnds;
};

#endif
