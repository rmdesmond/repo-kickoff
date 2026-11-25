cmake_minimum_required(VERSION 3.14)

project({{NAME}}
  VERSION 0.1.0
  DESCRIPTION "A command-line program"
  LANGUAGES CXX)

option({{NAME_SNAKE}}_BUILD_TESTS "Build the GoogleTest unit tests" ON)
option({{NAME_SNAKE}}_FETCH_GOOGLETEST
  "Download GoogleTest with FetchContent when no installed copy is found" OFF)

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_CXX_EXTENSIONS OFF)

# ---------------------------------------------------------------------------
# The library: all of the program's logic, so the tests can call it directly.
# ---------------------------------------------------------------------------
add_library({{NAME_SNAKE}}_lib STATIC src/{{NAME_SNAKE}}.cpp)
target_include_directories({{NAME_SNAKE}}_lib PUBLIC include)
target_compile_definitions({{NAME_SNAKE}}_lib
  PRIVATE {{NAME_SNAKE}}_VERSION="${PROJECT_VERSION}")
set_target_properties({{NAME_SNAKE}}_lib PROPERTIES OUTPUT_NAME {{NAME_SNAKE}})

# ---------------------------------------------------------------------------
# The program: a thin main() around the library.
# ---------------------------------------------------------------------------
add_executable({{NAME}} src/main.cpp)
target_link_libraries({{NAME}} PRIVATE {{NAME_SNAKE}}_lib)

if(CMAKE_CXX_COMPILER_ID MATCHES "GNU|Clang")
  target_compile_options({{NAME_SNAKE}}_lib PRIVATE -Wall -Wextra -pedantic)
  target_compile_options({{NAME}} PRIVATE -Wall -Wextra -pedantic)
endif()

install(TARGETS {{NAME}} RUNTIME DESTINATION bin)

# ---------------------------------------------------------------------------
# Unit tests: GoogleTest. Required unless the tests are turned off.
# ---------------------------------------------------------------------------
if({{NAME_SNAKE}}_BUILD_TESTS)
  set({{NAME_SNAKE}}_gtest_help
    "Install GoogleTest (brew install googletest, or apt install libgtest-dev), "
    "configure with -D{{NAME_SNAKE}}_FETCH_GOOGLETEST=ON to download it, "
    "or turn the tests off with -D{{NAME_SNAKE}}_BUILD_TESTS=OFF.")

  find_package(GTest QUIET)
  if(NOT GTest_FOUND AND NOT GTEST_FOUND AND {{NAME_SNAKE}}_FETCH_GOOGLETEST)
    message(STATUS "GoogleTest not installed: downloading it ({{NAME_SNAKE}}_FETCH_GOOGLETEST=ON)")
    if(POLICY CMP0135)
      cmake_policy(SET CMP0135 NEW)
    endif()
    include(FetchContent)
    FetchContent_Declare(googletest
      URL https://github.com/google/googletest/releases/download/v1.15.2/googletest-1.15.2.tar.gz
      URL_HASH SHA256=7b42b4d6ed48810c5362c265a17faebe90dc2373c885e5216439d37927f02926)
    set(gtest_force_shared_crt ON CACHE BOOL "" FORCE)
    set(INSTALL_GTEST OFF CACHE BOOL "" FORCE)
    FetchContent_MakeAvailable(googletest)
  endif()

  # GoogleTest's own package (and FetchContent) name the target
  # GTest::gtest_main; CMake's FindGTest before 3.20 names it GTest::Main.
  if(TARGET GTest::gtest_main)
    set({{NAME_SNAKE}}_gtest_main GTest::gtest_main)
  elseif(TARGET GTest::Main)
    set({{NAME_SNAKE}}_gtest_main GTest::Main)
  else()
    message(FATAL_ERROR "GoogleTest not found. " ${{{NAME_SNAKE}}_gtest_help})
  endif()

  enable_testing()
  add_executable({{NAME_SNAKE}}_tests tests/{{NAME_SNAKE}}_test.cpp)
  target_link_libraries({{NAME_SNAKE}}_tests
    PRIVATE {{NAME_SNAKE}}_lib ${{{NAME_SNAKE}}_gtest_main})
  include(GoogleTest)
  gtest_discover_tests({{NAME_SNAKE}}_tests)
endif()
