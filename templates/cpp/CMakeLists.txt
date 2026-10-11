cmake_minimum_required(VERSION 3.18.1)
project(sfsynth)

add_library(sfsynth SHARED synth.cpp)

find_library(log-lib log)
target_link_libraries(sfsynth ${log-lib})
