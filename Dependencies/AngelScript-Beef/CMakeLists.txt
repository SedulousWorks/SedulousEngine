# AngelScript-Beef's native build.
#
# The vendored angelscript/ and add_on/ are left EXACTLY as the SDK ships them: the SDK's own
# CMake project builds the library, and the C shim (angelscript_beef.cpp) plus the two add-ons
# it needs are a second static target beside it. Both archives go to dist/.
#
# Everything is registered with the generic calling convention, so AS_MAX_PORTABILITY, which
# the SDK turns on by itself under Emscripten, changes nothing for the host.

cmake_minimum_required(VERSION 3.16 FATAL_ERROR)

# The static CRT, as every other native dependency and the Beef link itself (libcmtd) use;
# the SDK's own project would otherwise pick the DLL runtime and the link refuses to mix
# them. Set before project() so the SDK subdirectory inherits it.
set(CMAKE_MSVC_RUNTIME_LIBRARY "MultiThreaded$<$<CONFIG:Debug>:Debug>")

project(angelscript_beef CXX C)

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_POSITION_INDEPENDENT_CODE ON)
set(BUILD_SHARED_LIBS OFF CACHE BOOL "" FORCE)
set(AS_DISABLE_INSTALL ON CACHE BOOL "" FORCE)

add_subdirectory(angelscript/projects/cmake)

add_library(angelscript_beef STATIC
  angelscript_beef.cpp
  add_on/scriptstdstring/scriptstdstring.cpp
  add_on/scriptstdstring/scriptstdstring_utils.cpp
  add_on/scriptarray/scriptarray.cpp)
target_include_directories(angelscript_beef
  PUBLIC ${CMAKE_CURRENT_SOURCE_DIR}
  PRIVATE ${CMAKE_CURRENT_SOURCE_DIR}/angelscript/include)
target_link_libraries(angelscript_beef PUBLIC angelscript)
