cmake_minimum_required(VERSION 3.14)
project(runami_ncm LANGUAGES CXX)

set(BINARY_NAME "Runami-NCM")

cmake_policy(SET CMP0079 NEW)

include(GNUInstallDirs)

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

option(BUILD_SHARED_LIBS "Build using shared libraries" OFF)

if(NOT COMMAND apply_standard_settings)
  function(apply_standard_settings TARGET)
    target_compile_features(${TARGET} PUBLIC cxx_std_17)
    target_compile_definitions(${TARGET} PRIVATE UNICODE _UNICODE)
  endfunction()
endif()

set(INSTALL_BUNDLE_DATA_DIR "${CMAKE_INSTALL_PREFIX}/data")
set(INSTALL_BUNDLE_LIB_DIR "${CMAKE_INSTALL_PREFIX}")

# Flutter wrapper
add_subdirectory(flutter)

add_subdirectory(runner)
