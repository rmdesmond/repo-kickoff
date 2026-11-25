cmake_minimum_required(VERSION 3.14)

project({{NAME}}
  VERSION 0.1.0
  DESCRIPTION "A C library"
  LANGUAGES C)

include(GNUInstallDirs)
include(CMakePackageConfigHelpers)

# Static by default; configure with -DBUILD_SHARED_LIBS=ON for a shared one.
option(BUILD_SHARED_LIBS "Build a shared library instead of a static one" OFF)

# Tests are on by default when this is the top-level project, and off when
# another project pulls it in with add_subdirectory or FetchContent, so that
# project needs neither GoogleTest nor C++.
if(CMAKE_SOURCE_DIR STREQUAL PROJECT_SOURCE_DIR)
  set({{NAME_SNAKE}}_tests_default ON)
else()
  set({{NAME_SNAKE}}_tests_default OFF)
endif()
option({{NAME_SNAKE}}_BUILD_TESTS "Build the GoogleTest unit tests"
  ${{{NAME_SNAKE}}_tests_default})
option({{NAME_SNAKE}}_FETCH_GOOGLETEST
  "Download GoogleTest with FetchContent when no installed copy is found" OFF)

# ---------------------------------------------------------------------------
# The library
# ---------------------------------------------------------------------------
add_library({{NAME_SNAKE}} src/{{NAME_SNAKE}}.c)
add_library({{NAME_SNAKE}}::{{NAME_SNAKE}} ALIAS {{NAME_SNAKE}})

target_include_directories({{NAME_SNAKE}} PUBLIC
  $<BUILD_INTERFACE:${PROJECT_SOURCE_DIR}/include>
  $<INSTALL_INTERFACE:${CMAKE_INSTALL_INCLUDEDIR}>)
target_compile_definitions({{NAME_SNAKE}}
  PRIVATE {{NAME_SNAKE}}_VERSION_STRING="${PROJECT_VERSION}")
set_target_properties({{NAME_SNAKE}} PROPERTIES
  C_STANDARD 11
  C_STANDARD_REQUIRED ON
  C_EXTENSIONS OFF
  VERSION ${PROJECT_VERSION}
  SOVERSION ${PROJECT_VERSION_MAJOR})

if(CMAKE_C_COMPILER_ID MATCHES "GNU|Clang")
  target_compile_options({{NAME_SNAKE}} PRIVATE -Wall -Wextra -pedantic)
endif()

# ---------------------------------------------------------------------------
# Unit tests: GoogleTest, in C++17. Required when the tests are built.
# ---------------------------------------------------------------------------
if({{NAME_SNAKE}}_BUILD_TESTS)
  set({{NAME_SNAKE}}_gtest_help
    "Install GoogleTest (brew install googletest, or apt install libgtest-dev), "
    "configure with -D{{NAME_SNAKE}}_FETCH_GOOGLETEST=ON to download it, "
    "or turn the tests off with -D{{NAME_SNAKE}}_BUILD_TESTS=OFF.")

  include(CheckLanguage)
  check_language(CXX)
  if(NOT CMAKE_CXX_COMPILER)
    message(FATAL_ERROR "The unit tests need a C++ compiler, and none was found. "
      "Install one, or turn the tests off with -D{{NAME_SNAKE}}_BUILD_TESTS=OFF.")
  endif()
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
    set({{NAME_SNAKE}}_gtest_main GTest::gtest_main)
  elseif(TARGET GTest::Main)
    set({{NAME_SNAKE}}_gtest_main GTest::Main)
  else()
    message(FATAL_ERROR "GoogleTest not found. " ${{{NAME_SNAKE}}_gtest_help})
  endif()

  enable_testing()
  add_executable({{NAME_SNAKE}}_test tests/{{NAME_SNAKE}}_test.cpp)
  target_link_libraries({{NAME_SNAKE}}_test
    PRIVATE {{NAME_SNAKE}}::{{NAME_SNAKE}} ${{{NAME_SNAKE}}_gtest_main})
  target_compile_features({{NAME_SNAKE}}_test PRIVATE cxx_std_17)
  include(GoogleTest)
  gtest_discover_tests({{NAME_SNAKE}}_test)
endif()

# ---------------------------------------------------------------------------
# Install: the library, its header, and a CMake package so that other
# projects can find_package({{NAME}}) and link {{NAME_SNAKE}}::{{NAME_SNAKE}}.
# ---------------------------------------------------------------------------
install(TARGETS {{NAME_SNAKE}}
  EXPORT {{NAME_SNAKE}}Targets
  ARCHIVE DESTINATION ${CMAKE_INSTALL_LIBDIR}
  LIBRARY DESTINATION ${CMAKE_INSTALL_LIBDIR}
  RUNTIME DESTINATION ${CMAKE_INSTALL_BINDIR})
install(FILES include/{{NAME_SNAKE}}.h
  DESTINATION ${CMAKE_INSTALL_INCLUDEDIR})

set({{NAME_SNAKE}}_cmake_dir ${CMAKE_INSTALL_LIBDIR}/cmake/{{NAME}})
install(EXPORT {{NAME_SNAKE}}Targets
  NAMESPACE {{NAME_SNAKE}}::
  DESTINATION ${{{NAME_SNAKE}}_cmake_dir})

configure_package_config_file(cmake/{{NAME}}Config.cmake.in
  ${PROJECT_BINARY_DIR}/{{NAME}}Config.cmake
  INSTALL_DESTINATION ${{{NAME_SNAKE}}_cmake_dir})
write_basic_package_version_file(
  ${PROJECT_BINARY_DIR}/{{NAME}}ConfigVersion.cmake
  VERSION ${PROJECT_VERSION}
  COMPATIBILITY SameMajorVersion)
install(FILES
  ${PROJECT_BINARY_DIR}/{{NAME}}Config.cmake
  ${PROJECT_BINARY_DIR}/{{NAME}}ConfigVersion.cmake
  DESTINATION ${{{NAME_SNAKE}}_cmake_dir})
