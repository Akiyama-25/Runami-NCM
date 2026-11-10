# cmake_minimum_required must be before any other command.
cmake_minimum_required(VERSION 3.14)

set(EPHEMERAL_DIR "${CMAKE_CURRENT_SOURCE_DIR}/ephemeral")

# Configuration provided via flutter tool.
include(${EPHEMERAL_DIR}/generated_config.cmake OPTIONAL)

# TODO: Move the rest of this into files in ephemeral. See
# https://github.com/flutter/flutter/issues/57146.
set(WRAPPER_ROOT "${EPHEMERAL_DIR}/cpp_client_wrapper")

# Set fallback configurations for older versions of the flutter tool.
if(NOT DEFINED FLUTTER_TARGET_PLATFORM)
  set(FLUTTER_TARGET_PLATFORM "windows-x64")
endif()

# === Flutter Tool Synchronization ===
# Set up the custom build step that runs the flutter assemble command to
# assemble the flutter resources, download the flutter library, and
# produce the intermediate build assets.
set(FLUTTER_ASSEMBLE_COMMAND
  "${FLUTTER_ROOT}/bin/flutter"
)
if(WIN32)
  set(FLUTTER_ASSEMBLE_COMMAND "${FLUTTER_ROOT}/bin/flutter.bat")
endif()

set(FLUTTER_ASSEMBLE_OUTPUTS
  "${EPHEMERAL_DIR}/flutter_windows.dll"
  "${EPHEMERAL_DIR}/flutter_windows.dll.exp"
  "${EPHEMERAL_DIR}/flutter_windows.dll.lib"
  "${EPHEMERAL_DIR}/flutter_windows.dll.pdb"
  "${WRAPPER_ROOT}/core_implementations.cc"
  "${WRAPPER_ROOT}/standard_codec.cc"
  "${WRAPPER_ROOT}/plugin_registrar.cc"
  "${WRAPPER_ROOT}/flutter_engine.cc"
  "${WRAPPER_ROOT}/flutter_view_controller.cc"
  "${WRAPPER_ROOT}/include/flutter/action.h"
  "${WRAPPER_ROOT}/include/flutter/basic_message_channel.h"
  "${WRAPPER_ROOT}/include/flutter/binary_messenger.h"
  "${WRAPPER_ROOT}/include/flutter/byte_stream_method_channel.h"
  "${WRAPPER_ROOT}/include/flutter/encodable_value.h"
  "${WRAPPER_ROOT}/include/flutter/event_channel.h"
  "${WRAPPER_ROOT}/include/flutter/event_sink.h"
  "${WRAPPER_ROOT}/include/flutter/event_stream_handler_functions.h"
  "${WRAPPER_ROOT}/include/flutter/flutter_engine.h"
  "${WRAPPER_ROOT}/include/flutter/flutter_view_controller.h"
  "${WRAPPER_ROOT}/include/flutter/flutter_view.h"
  "${WRAPPER_ROOT}/include/flutter/method_call.h"
  "${WRAPPER_ROOT}/include/flutter/method_channel.h"
  "${WRAPPER_ROOT}/include/flutter/method_result_functions.h"
  "${WRAPPER_ROOT}/include/flutter/method_result.h"
  "${WRAPPER_ROOT}/include/flutter/plugin_registrar.h"
  "${WRAPPER_ROOT}/include/flutter/plugin_registry.h"
  "${WRAPPER_ROOT}/include/flutter/standard_codec.h"
  "${WRAPPER_ROOT}/include/flutter/standard_message_codec.h"
  "${WRAPPER_ROOT}/include/flutter/standard_method_codec.h"
  "${WRAPPER_ROOT}/include/flutter/texture_registrar.h"
)

# This custom command will only run if any of the outputs are missing, or if
# inputs have changed.
add_custom_command(
  OUTPUT ${FLUTTER_ASSEMBLE_OUTPUTS}
  COMMAND ${FLUTTER_ASSEMBLE_COMMAND}
    --suppress-analytics
    assemble
    -dTargetPlatform=${FLUTTER_TARGET_PLATFORM}
    -dTrackWidgetCreation=${TRACK_WIDGET_CREATION}
    -dBuildMode=${CMAKE_BUILD_TYPE}
    -dTargetFile=${FLUTTER_TARGET}
    -dAdditionalArgs=${FLUTTER_ADDITIONAL_ARGS}
    ${FLUTTER_ASSET_INPUTS}
    ${FLUTTER_ASSEMBLE_TARGET}
  VERBATIM
)

add_custom_target(flutter_assemble DEPENDS
  ${FLUTTER_ASSEMBLE_OUTPUTS}
)

# === Flutter Library ===
set(FLUTTER_LIB_DIR "${EPHEMERAL_DIR}")
add_library(flutter INTERFACE)
target_include_directories(flutter INTERFACE
  "${EPHEMERAL_DIR}"
)
target_link_libraries(flutter INTERFACE "${FLUTTER_LIB_DIR}/flutter_windows.dll.lib")
add_dependencies(flutter flutter_assemble)

# === Wrapper ===
list(APPEND CPP_WRAPPER_SOURCES_CORE
  "${WRAPPER_ROOT}/core_implementations.cc"
  "${WRAPPER_ROOT}/standard_codec.cc"
)
list(APPEND CPP_WRAPPER_SOURCES_PLUGIN
  "${WRAPPER_ROOT}/plugin_registrar.cc"
)
list(APPEND CPP_WRAPPER_SOURCES_APP
  "${WRAPPER_ROOT}/flutter_engine.cc"
  "${WRAPPER_ROOT}/flutter_view_controller.cc"
)

# Container for wrapper sources to share standard build settings.
add_library(flutter_wrapper_defaults INTERFACE)
apply_standard_settings(flutter_wrapper_defaults)

# The library that apps and plugins should link to.
add_library(flutter_wrapper_core STATIC
  ${CPP_WRAPPER_SOURCES_CORE}
)
target_link_libraries(flutter_wrapper_core PUBLIC flutter flutter_wrapper_defaults)
target_include_directories(flutter_wrapper_core PUBLIC
  "${WRAPPER_ROOT}/include"
)
add_dependencies(flutter_wrapper_core flutter_assemble)

add_library(flutter_wrapper_app STATIC
  ${CPP_WRAPPER_SOURCES_APP}
)
target_link_libraries(flutter_wrapper_app PUBLIC flutter_wrapper_core flutter_wrapper_defaults)
target_include_directories(flutter_wrapper_app PUBLIC
  "${WRAPPER_ROOT}/include"
)
add_dependencies(flutter_wrapper_app flutter_assemble)

add_library(flutter_wrapper_plugin STATIC
  ${CPP_WRAPPER_SOURCES_PLUGIN}
)
target_link_libraries(flutter_wrapper_plugin PUBLIC flutter_wrapper_core flutter_wrapper_defaults)
target_include_directories(flutter_wrapper_plugin PUBLIC
  "${WRAPPER_ROOT}/include"
)
add_dependencies(flutter_wrapper_plugin flutter_assemble)

# === Plugins ===
set(FLUTTER_LIBRARY "${FLUTTER_LIB_DIR}/flutter_windows.dll")

# Plugins that support the desktop platform are compiled into the application.
include(${FLUTTER_MANAGED_DIR}/generated_plugins.cmake OPTIONAL)
