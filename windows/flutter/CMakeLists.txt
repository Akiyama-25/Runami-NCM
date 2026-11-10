cmake_minimum_required(VERSION 3.14)
set(EPHEMERAL_DIR "${CMAKE_CURRENT_SOURCE_DIR}/ephemeral")

# Configuration provided via flutter tool.
include(${EPHEMERAL_DIR}/generated_config.cmake OPTIONAL)

set(FLUTTER_MANAGED_DIR "${CMAKE_CURRENT_SOURCE_DIR}")

# Plugins that support the desktop platform are compiled into the application
include(${FLUTTER_MANAGED_DIR}/generated_plugins.cmake OPTIONAL)
