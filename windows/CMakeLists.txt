cmake_minimum_required(VERSION 3.14)
project(runami_ncm LANGUAGES CXX)

set(BINARY_NAME "runami_ncm")

cmake_policy(SET CMP0079 NEW)

# Standard CMake install directory layout
include(GNUInstallDirs)

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

options(BUILD_SHARED_LIBS "Build using shared libraries" OFF)

set(INSTALL_BUNDLE_DATA_DIR "${CMAKE_INSTALL_PREFIX}/data")
set(INSTALL_BUNDLE_LIB_DIR "${CMAKE_INSTALL_PREFIX}")

# Flutter wrapper
add_subdirectory(flutter)

add_subdirectory(runner)
