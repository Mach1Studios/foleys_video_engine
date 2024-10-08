cmake_minimum_required (VERSION 3.15 FATAL_ERROR)

include_guard (GLOBAL)

include (FetchContent)
include (FeatureSummary)
include (FindPackageMessage)

set_package_properties ("${CMAKE_FIND_PACKAGE_NAME}" 
                        PROPERTIES 
                            URL "https://juce.com/"
                            DESCRIPTION "Cross platform framework for plugin and app development")

set (juce_git_hash 37d6161da2aa94d1530cef860b1642e1e4d9e08d) # most recent JUCE 6 commit

FetchContent_Declare (JUCE
                      GIT_REPOSITORY https://github.com/juce-framework/JUCE.git
                      GIT_TAG "${juce_git_hash}")

set (JUCE_BUILD_EXAMPLES OFF)
set (JUCE_BUILD_EXTRAS OFF)
set (JUCE_ENABLE_MODULE_SOURCE_GROUPS ON)

FetchContent_MakeAvailable (JUCE)

find_package_message ("${CMAKE_FIND_PACKAGE_NAME}" 
                      "JUCE package found -- Sources downloaded"
                      "JUCE (GitHub) [${juce_git_hash}]")

set (${CMAKE_FIND_PACKAGE_NAME}_FOUND TRUE)
