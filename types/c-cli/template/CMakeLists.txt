cmake_minimum_required(VERSION 3.14)

project({{NAME}}
  VERSION 0.1.0
  DESCRIPTION "A command-line program"
  LANGUAGES C)

option({{NAME_SNAKE}}_FETCH_GOOGLETEST
  "Download GoogleTest with FetchContent when no installed copy is found" OFF)

# ---------------------------------------------------------------------------
# The library: all of the program's logic, so the tests can call it directly.
# ---------------------------------------------------------------------------
add_library({{NAME_SNAKE}}_lib STATIC src/{{NAME_SNAKE}}.c)
target_include_directories({{NAME_SNAKE}}_lib PUBLIC include)
target_compile_definitions({{NAME_SNAKE}}_lib
  PRIVATE {{NAME_SNAKE}}_VERSION="${PROJECT_VERSION}")
set_target_properties({{NAME_SNAKE}}_lib PROPERTIES
  OUTPUT_NAME {{NAME_SNAKE}}
  C_STANDARD 11
  C_STANDARD_REQUIRED ON
  C_EXTENSIONS OFF)

# ---------------------------------------------------------------------------
# The program: a thin main() around the library.
# ---------------------------------------------------------------------------
add_executable({{NAME}} src/main.c)
target_link_libraries({{NAME}} PRIVATE {{NAME_SNAKE}}_lib)
set_target_properties({{NAME}} PROPERTIES
  C_STANDARD 11
  C_STANDARD_REQUIRED ON
  C_EXTENSIONS OFF)

if(CMAKE_C_COMPILER_ID MATCHES "GNU|Clang")
  target_compile_options({{NAME_SNAKE}}_lib PRIVATE -Wall -Wextra -pedantic)
  target_compile_options({{NAME}} PRIVATE -Wall -Wextra -pedantic)
endif()

install(TARGETS {{NAME}} RUNTIME DESTINATION bin)

# ---------------------------------------------------------------------------
# Unit tests (GoogleTest, C++): built only when GoogleTest is available.
# ---------------------------------------------------------------------------
set(tests_enabled OFF)
set(gtest_main_target "")

include(CheckLanguage)
check_language(CXX)
if(CMAKE_CXX_COMPILER)
  enable_language(CXX)

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
    set(gtest_main_target GTest::gtest_main)
  elseif(TARGET GTest::Main)
    set(gtest_main_target GTest::Main)
  endif()

  if(gtest_main_target)
    set(tests_enabled ON)
  endif()
endif()

if(tests_enabled)
  enable_testing()
  add_executable({{NAME_SNAKE}}_tests tests/{{NAME_SNAKE}}_test.cpp)
  target_link_libraries({{NAME_SNAKE}}_tests
    PRIVATE {{NAME_SNAKE}}_lib ${gtest_main_target})
  target_compile_features({{NAME_SNAKE}}_tests PRIVATE cxx_std_17)
  include(GoogleTest)
  gtest_discover_tests({{NAME_SNAKE}}_tests)
  message(STATUS "Unit tests: enabled - run them with ctest")
elseif(NOT CMAKE_CXX_COMPILER)
  message(STATUS "Unit tests: skipped - no C++ compiler found")
else()
  message(STATUS "Unit tests: skipped - GoogleTest not found. Install it "
    "(brew install googletest, or apt install libgtest-dev) or configure "
    "with -D{{NAME_SNAKE}}_FETCH_GOOGLETEST=ON to download it")
endif()

# Read by tests/smoke.sh to decide whether to run ctest.
set({{NAME_SNAKE}}_TESTS_ENABLED ${tests_enabled} CACHE INTERNAL
  "Whether the GoogleTest unit tests are built")
