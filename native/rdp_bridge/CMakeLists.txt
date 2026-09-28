cmake_minimum_required(VERSION 3.20)

project(rdc_bridge C)

find_package(Threads REQUIRED)

set(CMAKE_C_STANDARD 11)
set(CMAKE_C_STANDARD_REQUIRED ON)

set(FREERDP_ROOT
    "${CMAKE_CURRENT_SOURCE_DIR}/../freerdp/install"
)

add_library(rdc_bridge SHARED
    src/rdp_bridge.c
)

target_include_directories(rdc_bridge PRIVATE
    "${FREERDP_ROOT}/include/freerdp3"
    "${FREERDP_ROOT}/include/winpr3"
)

target_link_directories(rdc_bridge PRIVATE
    "${FREERDP_ROOT}/lib"
)

target_link_libraries(rdc_bridge PRIVATE
    freerdp3
    freerdp-client3
    winpr3
    Threads::Threads
)

set_target_properties(rdc_bridge PROPERTIES
    OUTPUT_NAME "rdc_bridge"
    BUILD_RPATH "${FREERDP_ROOT}/lib;$ORIGIN"
)
