cmake_minimum_required(VERSION 3.15)
project(CARAVAN_SCHEDULER)

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_OSX_DEPLOYMENT_TARGET 10.15)

set(SOURCE_FILES main.cpp Producer.hpp Task.hpp TaskResult.hpp Consumer.hpp Logger.hpp SearchEngine.hpp Buffer.hpp SpawnerHandler.hpp Spawner.hpp)
find_package(MPI)
find_package(Boost COMPONENTS filesystem REQUIRED)

set(CMAKE_RUNTIME_OUTPUT_DIRECTORY ${CMAKE_CURRENT_SOURCE_DIR})

add_executable(scheduler ${SOURCE_FILES})
target_link_libraries(scheduler ${MPI_LIBRARIES} Boost::filesystem)
target_include_directories(scheduler
        PUBLIC ${MPI_INCLUDE_PATH} ${Boost_INCLUDE_DIR} ${CMAKE_CURRENT_SOURCE_DIR}/json/include)
