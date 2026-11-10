cmake_minimum_required(VERSION 3.14)
project(runner LANGUAGES CXX)

set(BINARY_NAME "Runami-NCM")

add_executable(${BINARY_NAME} WIN32
  "flutter_window.cpp"
  "main.cpp"
  "utils.cpp"
  "win32_window.cpp"
  "Runner.rc"
  "flutter_window.h"
  "utils.h"
  "win32_window.h"
  "resource.h"
)

apply_standard_settings(${BINARY_NAME})

target_compile_definitions(${BINARY_NAME} PRIVATE
  $<$<CONFIG:Debug>:_DEBUG>
  UNICODE
  _UNICODE
)

target_include_directories(${BINARY_NAME} PRIVATE
  "${CMAKE_CURRENT_SOURCE_DIR}"
  "${FLUTTER_MANAGED_DIR}"
)

target_link_libraries(${BINARY_NAME} PRIVATE
  flutter
  flutter_wrapper_app
)

target_link_libraries(${BINARY_NAME} PRIVATE ${FLUTTER_LIBRARIES})
