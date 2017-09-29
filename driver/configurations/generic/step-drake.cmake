set(CTEST_SOURCE_DIRECTORY "${DASHBOARD_SOURCE_DIRECTORY}/drake")
set(CTEST_BINARY_DIRECTORY "${DASHBOARD_BINARY_DIRECTORY}/drake")

# Identify actions to be performed and report what we are doing
set(DASHBOARD_STEPS "")
list(APPEND DASHBOARD_STEPS "CONFIGURING")
list(APPEND DASHBOARD_STEPS "BUILDING")
if(DASHBOARD_INSTALL)
  list(APPEND DASHBOARD_STEPS "INSTALLING")
endif()
if(DASHBOARD_TEST)
  list(APPEND DASHBOARD_STEPS "TESTING")
endif()
string(REPLACE ";" " / " DASHBOARD_STEPS_STRING "${DASHBOARD_STEPS}")

notice("CTest Status: ${DASHBOARD_STEPS_STRING} DRAKE")

# Switch the dashboard to the drake only dashboard
# TODO remove when subprojects arrive
begin_stage(
  PROJECT_NAME "Drake"
  BUILD_NAME "${DASHBOARD_BUILD_NAME}-drake")

# Update the sources
ctest_update(SOURCE "${CTEST_SOURCE_DIRECTORY}"
  RETURN_VALUE DASHBOARD_UPDATE_RETURN_VALUE QUIET)

# Add any needed overrides to the cache and reconfigure
set(DRAKE_CONFIGURE_ARGS "")
set(DRAKE_CACHE_VARS
  LONG_RUNNING_TESTS
  TEST_TIMEOUT_MULTIPLIER
  CMAKE_POSITION_INDEPENDENT_CODE
)
foreach(DRAKE_CACHE_VAR ${DRAKE_CACHE_VARS})
  if(CACHE_CONTENT MATCHES "(^|\n)(${DRAKE_CACHE_VAR}:[^\n]+)\n")
    string(REPLACE ";" "\\;" _cache_value "${CMAKE_MATCH_2}")
    list(APPEND DRAKE_CONFIGURE_ARGS "-D${_cache_value}")
  endif()
endforeach()

list(APPEND DRAKE_CONFIGURE_ARGS
  "-DENABLE_DOCUMENTATION=${DASHBOARD_ENABLE_DOCUMENTATION}")
if(DASHBOARD_ENABLE_DOCUMENTATION)
  list(APPEND DRAKE_CONFIGURE_ARGS "-DBUILD_DOCUMENTATION_ALWAYS=ON")
endif()

list(APPEND DRAKE_CONFIGURE_ARGS --warn-uninitialized)

ctest_configure(BUILD "${CTEST_BINARY_DIRECTORY}"
  OPTIONS "${DRAKE_CONFIGURE_ARGS}"
  SOURCE "${CTEST_SOURCE_DIRECTORY}"
  RETURN_VALUE DASHBOARD_CONFIGURE_RETURN_VALUE QUIET)
if(NOT DASHBOARD_CONFIGURE_RETURN_VALUE EQUAL 0)
  append_step_status("CONFIGURE" FAILURE)
endif()

# Set up some testing parameters
ctest_read_custom_files("${CTEST_BINARY_DIRECTORY}")

set(CTEST_CUSTOM_MAXIMUM_NUMBER_OF_ERRORS 100)
set(CTEST_CUSTOM_MAXIMUM_NUMBER_OF_WARNINGS 100)

if(MATLAB)
  set(CTEST_CUSTOM_MAXIMUM_FAILED_TEST_OUTPUT_SIZE 307200)
  set(CTEST_CUSTOM_MAXIMUM_PASSED_TEST_OUTPUT_SIZE 307200)
endif()

# Run the build
ctest_build(APPEND NUMBER_ERRORS DASHBOARD_NUMBER_BUILD_ERRORS
  NUMBER_WARNINGS DASHBOARD_NUMBER_BUILD_WARNINGS
  RETURN_VALUE DASHBOARD_BUILD_RETURN_VALUE QUIET)
if(DASHBOARD_NUMBER_BUILD_ERRORS GREATER 0 OR NOT DASHBOARD_BUILD_RETURN_VALUE EQUAL 0)
  append_step_status("BUILD" FAILURE)
endif()

if(DASHBOARD_FAILURE)
  notice("CTest Status: NOT CONTINUING BECAUSE BUILD WAS NOT SUCCESSFUL")

  set(DASHBOARD_INSTALL OFF)
  set(DASHBOARD_TEST OFF)
endif()

if(DASHBOARD_INSTALL)
  ctest_submit(RETRY_COUNT 4 RETRY_DELAY 15
    RETURN_VALUE DASHBOARD_SUBMIT_RETURN_VALUE QUIET)
  ctest_build(TARGET "install" APPEND
    RETURN_VALUE DASHBOARD_INSTALL_RETURN_VALUE QUIET)
  if(DASHBOARD_INSTALL AND NOT DASHBOARD_INSTALL_RETURN_VALUE EQUAL 0)
    append_step_status("INSTALL" FAILURE)
  endif()
endif()

# Run tests
if(DASHBOARD_TEST)
  ctest_test(BUILD "${CTEST_BINARY_DIRECTORY}" ${CTEST_TEST_ARGS}
    RETURN_VALUE DASHBOARD_TEST_RETURN_VALUE QUIET)
endif()

# Submit the results
ctest_submit(RETRY_COUNT 4 RETRY_DELAY 15
  RETURN_VALUE DASHBOARD_SUBMIT_RETURN_VALUE QUIET)
