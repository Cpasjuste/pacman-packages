set(CMAKE_SYSTEM_NAME Generic)

set(CMAKE_C_COMPILER "powerpc-eabi-gcc")
set(CMAKE_CXX_COMPILER "powerpc-eabi-g++")
set(CMAKE_AR "powrpc-eabi-gcc-ar")
set(CMAKE_RANLIB "powerpc-eabi-gcc-ranlib")

set(CMAKE_FIND_ROOT_PATH_MODE_PROGRAM NEVER)
set(CMAKE_FIND_ROOT_PATH_MODE_LIBRARY ONLY)
set(CMAKE_FIND_ROOT_PATH_MODE_INCLUDE ONLY)
set(CMAKE_FIND_ROOT_PATH_MODE_PACKAGE ONLY)

SET(BUILD_SHARED_LIBS OFF CACHE INTERNAL "Shared libs not available" )
