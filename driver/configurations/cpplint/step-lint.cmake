# TODO move to site.cmake when subprojects arrive
set(DASHBOARD_PROJECT_NAME "Drake")

# now start the actual drake build
set(CTEST_SOURCE_DIRECTORY "${DASHBOARD_WORKSPACE}/drake")
set(CTEST_BINARY_DIRECTORY "${DASHBOARD_WORKSPACE}/build/drake")

# switch the dashboard to the drake only dashboard
set(CTEST_BUILD_NAME "${DASHBOARD_BUILD_NAME}-drake-cpplint")
set(CTEST_PROJECT_NAME "${DASHBOARD_PROJECT_NAME}")
set(CTEST_NIGHTLY_START_TIME "${DASHBOARD_NIGHTLY_START_TIME}")
set(CTEST_DROP_METHOD "https")
set(CTEST_DROP_SITE "${DASHBOARD_CDASH_SERVER}")
set(CTEST_DROP_LOCATION "/submit.php?project=${DASHBOARD_PROJECT_NAME}")
set(CTEST_DROP_SITE_CDASH ON)

notice("CTest Status: RUNNING CPPLINT")

ctest_start("${DASHBOARD_MODEL}" TRACK "${DASHBOARD_TRACK}" QUIET)
ctest_update(SOURCE "${CTEST_SOURCE_DIRECTORY}"
  RETURN_VALUE DASHBOARD_UPDATE_RETURN_VALUE QUIET)

ctest_read_custom_files("${CTEST_BINARY_DIRECTORY}")

set(CTEST_BUILD_COMMAND
  "${DASHBOARD_WORKSPACE}/drake/common/test/cpplint_wrapper.py")

set(CTEST_CUSTOM_MAXIMUM_NUMBER_OF_ERRORS 1000)
set(CTEST_CUSTOM_MAXIMUM_NUMBER_OF_WARNINGS 1000)

set(CTEST_CUSTOM_ERROR_MATCH
  "TOTAL [0-9]+ files checked, found [1-9][0-9]* warnings"
  ${CTEST_CUSTOM_ERROR_MATCH}
)

ctest_build(APPEND NUMBER_ERRORS DASHBOARD_NUMBER_BUILD_ERRORS
  NUMBER_WARNINGS DASHBOARD_NUMBER_BUILD_WARNINGS QUIET)
if(DASHBOARD_NUMBER_BUILD_ERRORS GREATER 0)
  set(DASHBOARD_FAILURE ON)
  list(APPEND DASHBOARD_FAILURES "CPPLINT")
endif()

# Submit the results of cpplint
set(DASHBOARD_BUILD_URL_FILE
  "${CTEST_BINARY_DIRECTORY}/${DASHBOARD_BUILD_NAME}.url")
file(WRITE "${DASHBOARD_BUILD_URL_FILE}" "$ENV{BUILD_URL}")
ctest_upload(FILES "${DASHBOARD_BUILD_URL_FILE}" QUIET)

ctest_submit(RETRY_COUNT 4 RETRY_DELAY 15
  RETURN_VALUE DASHBOARD_SUBMIT_RETURN_VALUE QUIET)