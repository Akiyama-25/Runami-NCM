cmake_minimum_required(VERSION 3.14)
project(runner LANGUAGES CXX)

set(BINARY_NAME "Runami-NCM")

cmake_policy(SET CMP0079 NEW)

include(GNUInstallDirs)

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

option(BUILD_SHARED_LIBS "Build using shared libraries" OFF)

function(apply_standard_settings TARGET)
  get_target_property(TARGET_TYPE ${TARGET} TYPE)
  if(TARGET_TYPE STREQUAL "INTERFACE_LIBRARY")
    target_compile_features(${TARGET} INTERFACE cxx_std_17)
    target_compile_definitions(${TARGET} INTERFACE UNICODE _UNICODE)
  else()
    target_compile_features(${TARGET} PUBLIC cxx_std_17)
    target_compile_definitions(${TARGET} PRIVATE UNICODE _UNICODE)
  endif()
endfunction()

set(INSTALL_BUNDLE_DATA_DIR "${CMAKE_INSTALL_PREFIX}/data")
set(INSTALL_BUNDLE_LIB_DIR "${CMAKE_INSTALL_PREFIX}")

# Flutter wrapper
include(flutter/CMakeLists.txt)

add_subdirectory(runner)
