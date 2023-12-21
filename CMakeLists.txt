cmake_minimum_required (VERSION 3.15 FATAL_ERROR)

if (${CMAKE_SYSTEM_NAME} MATCHES "Darwin")
    project (FoleysVideoEngine 
            VERSION 0.2.0 
            LANGUAGES CXX OBJC C
            DESCRIPTION "A video engine module for JUCE"
            HOMEPAGE_URL "https://foleysfinest.com/foleys_video_engine/")
else()
    project (FoleysVideoEngine 
            VERSION 0.2.0 
            LANGUAGES CXX C
            DESCRIPTION "A video engine module for JUCE"
            HOMEPAGE_URL "https://foleysfinest.com/foleys_video_engine/")
endif()

list (APPEND CMAKE_MODULE_PATH "${CMAKE_CURRENT_LIST_DIR}/cmake")

if(NOT ffmpeg_FOUND)
    if (${CMAKE_SYSTEM_NAME} MATCHES "Darwin")
        find_package (ffmpeg REQUIRED)
    else()

        if(CMAKE_BUILD_TYPE)
            set (BT "${CMAKE_BUILD_TYPE}")
        elseif(CMAKE_DEFAULT_BUILD_TYPE)
            set (BT "${CMAKE_DEFAULT_BUILD_TYPE}")
        else()
            set (BT Release)
        endif()
        string (TOUPPER "${BT}" BT)
        message (VERBOSE "ffmpeg build configuration: ${BT}")

        if("${BT}" MATCHES "MINSIZEREL")
            set (size_opts --enable-small)
        else()
            unset (size_opts)
        endif()

        include (CheckLanguage)
        check_language (CUDA)
        if(CMAKE_CUDA_COMPILER)
            enable_language (CUDA)
            set (cuda_opts
                    "--nvcc=${CMAKE_CUDA_COMPILER}"
                    "--nvccflags=${CMAKE_CUDA_FLAGS_${BT}}")
        else()
            unset (cuda_opts)
        endif()

        find_program (MAKE_EXECUTABLE 
                      NAMES gmake make nmake 
                      DOC "make executable" 
                      REQUIRED)

        include (GNUInstallDirs)
        include (ExternalProject)

        if(BUILD_SHARED_LIBS)
            set (shared_opts --disable-static --enable-shared)
        else()
            set (shared_opts --enable-static --disable-shared)
        endif()

        if(CMAKE_POSITION_INDEPENDENT_CODE)
            set (pic_opts --enable-pic)
        else()
            unset (pic_opts)
        endif()

        if(CMAKE_INTERPROCEDURAL_OPTIMIZATION_${BT})
            set (lto_opts --enable-lto)
        else()
            unset (lto_opts)
        endif()

        if(CMAKE_CROSSCOMPILING)
            set (cross_opts 
                    --enable-cross-compile 
                    "--sysroot=${CMAKE_SYSROOT}"
                    "--target-os=${CMAKE_SYSTEM_NAME}")

            if (CMAKE_CROSSCOMPILING_EMULATOR)
                list (JOIN CMAKE_CROSSCOMPILING_EMULATOR " " cross_prefix_cmdline)
                list (APPEND cross_opts "--target-exec=${cross_prefix_cmdline}")
            endif()
        else()
            unset (cross_opts)
        endif()

        if(CMAKE_${BT}_POSTFIX)
            set (postfix_opts 
                    "--progs-suffix=${CMAKE_${BT}_POSTFIX}"
                    "--build-suffix=${CMAKE_${BT}_POSTFIX}")
        else()
            unset (postfix_opts)
        endif()

        find_package (PkgConfig)

        if(PKG_CONFIG_FOUND)
            list (JOIN PKG_CONFIG_ARGN " " pkg_config_flags)
            set (pkgconfig_opts 
                    "--pkg-config=${PKG_CONFIG_EXECUTABLE}"
                    "--pkg-config-flags=${pkg_config_flags}")
        else()
            unset (pkgconfig_opts)
        endif()

        include (ProcessorCount)
        ProcessorCount (numCores)

        ExternalProject_Add (
            ffmpeg
            GIT_REPOSITORY "https://github.com/FFmpeg/FFmpeg.git"
            GIT_TAG "393d1ee541b143633bfba2ff0e821d734fd511c2"
            GIT_SHALLOW  TRUE
            GIT_PROGRESS TRUE
            CONFIGURE_COMMAND "<SOURCE_DIR>/configure"
                "--logfile=<LOG_DIR>/ffmpeg-configure-output.log"
                "--prefix=<INSTALL_DIR>"
                "--bindir=<INSTALL_DIR>/${CMAKE_INSTALL_BINDIR}"
                "--datadir=<INSTALL_DIR>/${CMAKE_INSTALL_DATAROOTDIR}/ffmpeg"
                "--docdir=<INSTALL_DIR>/${CMAKE_INSTALL_DATAROOTDIR}/doc/ffmpeg"
                "--libdir=<INSTALL_DIR>/${CMAKE_INSTALL_LIBDIR}"
                "--incdir=<INSTALL_DIR>/${CMAKE_INSTALL_INCLUDEDIR}"
                "--mandir=<INSTALL_DIR>/${CMAKE_INSTALL_MANDIR}"
                ${shared_opts}
                ${cross_opts}
                "--host-os=${CMAKE_HOST_SYSTEM_NAME}"
                "--arch=${CMAKE_SYSTEM_PROCESSOR}"
                "--ar=${CMAKE_AR}"
                "--ranlib=${CMAKE_RANLIB}"
                "--strip=${CMAKE_STRIP}"
                "--cc=${CMAKE_C_COMPILER}"
                "--extra-cflags=${CMAKE_C_FLAGS_${BT}}"
                "--optflags=${CMAKE_C_FLAGS_RELEASE}"
                "--cxx=${CMAKE_CXX_COMPILER}"
                "--extra-cxxflags=${CMAKE_CXX_FLAGS_${BT}}"
                "--objcc=${CMAKE_OBJC_COMPILER}"
                "--extra-objcflags=${CMAKE_OBJC_FLAGS_${BT}}"
                ${pkgconfig_opts}
                ${doxygen_opts}
                ${postfix_opts}
                ${pic_opts}
                ${lto_opts}
                ${size_opts}
            BUILD_COMMAND "${MAKE_EXECUTABLE}" all "-j${numCores}"
            BUILD_IN_SOURCE TRUE
            BUILD_ALWAYS TRUE
            BUILD_JOB_SERVER_AWARE TRUE
            INSTALL_COMMAND "${MAKE_EXECUTABLE}" install
            TEST_COMMAND "${MAKE_EXECUTABLE}" check "-j${numCores}"
            TEST_EXCLUDE_FROM_MAIN TRUE
            INSTALL_DIR "${CMAKE_CURRENT_BINARY_DIR}/deploy"
            LOG_DIR "${CMAKE_CURRENT_BINARY_DIR}/logs"
            LOG_CONFIGURE TRUE
            LOG_BUILD TRUE
            LOG_INSTALL TRUE
            LOG_TEST TRUE
            LOG_MERGED_STDOUTERR TRUE
            LOG_OUTPUT_ON_FAILURE TRUE
            STEP_TARGETS test
        )

        ExternalProject_Add_Step (
            ffmpeg clean
            COMMAND "${MAKE_EXECUTABLE}" clean
            COMMAND "${MAKE_EXECUTABLE}" uninstall
            WORKING_DIRECTORY "<SOURCE_DIR>"
            COMMENT "Cleaning ffmpeg..."
            EXCLUDE_FROM_MAIN TRUE
            ALWAYS TRUE
        )

        ExternalProject_Add_StepTargets (ffmpeg clean)

        add_test (NAME ffmpeg.unit
                  COMMAND "${CMAKE_COMMAND}" 
                    --build "${CMAKE_BINARY_DIR}" 
                    --target ffmpeg-test)

        ExternalProject_Get_Property (ffmpeg INSTALL_DIR)

        install (DIRECTORY "${INSTALL_DIR}"
                 DESTINATION ..
                 USE_SOURCE_PERMISSIONS
                 COMPONENT ffmpeg)

        install (FILES Findffmpeg.cmake
                 DESTINATION "${CMAKE_INSTALL_LIBDIR}/cmake/ffmpeg"
                 COMPONENT ffmpeg)

        include (CPackComponent)
        cpack_add_component (ffmpeg DESCRIPTION "${ffmpeg_DESCRIPTION}")
    endif()
endif()

if(PROJECT_IS_TOP_LEVEL)
    message(STATUS "No parent project found, requiring JUCE")
    find_package (JUCE 6 REQUIRED)
endif()

juce_add_module ("${CMAKE_CURRENT_LIST_DIR}" ALIAS_NAMESPACE Foleys)

target_compile_definitions (foleys_video_engine INTERFACE 
                JUCE_MODAL_LOOPS_PERMITTED=1 
                JUCE_STRICT_REFCOUNTEDPOINTER=1 
                JUCE_PLUGINHOST_AU=1 
                JUCE_PLUGINHOST_VST3=1 
                JUCE_PLUGINHOST_LADSPA=1)

target_link_libraries (foleys_video_engine INTERFACE FFmpeg::FFmpeg)

#

set (FVE_INSTALL_DEST "${CMAKE_INSTALL_LIBDIR}/cmake/foleys_video_engine"
        CACHE STRING
        "Directory below INSTALL_PREFIX where the foleys_video_engine CMake package files will be installed to")

install (DIRECTORY "${CMAKE_CURRENT_LIST_DIR}"
         DESTINATION "${FVE_INSTALL_DEST}/.."
         COMPONENT foleys_video_engine
         PATTERN *.md EXCLUDE
         PATTERN .git/* EXCLUDE
         PATTERN .github/* EXCLUDE
         PATTERN *.json EXCLUDE
         PATTERN CMakeLists.txt EXCLUDE 
         PATTERN "${CMAKE_CURRENT_BINARY_DIR}/" EXCLUDE)

include (CPackComponent)

cpack_add_component (foleys_video_engine
            GROUP Foleys 
            INSTALL_TYPES Developer)

include (CMakePackageConfigHelpers)

write_basic_package_version_file (foleys_video_engine-config-version.cmake 
                                  VERSION "${PROJECT_VERSION}"
                                  COMPATIBILITY SameMajorVersion
                                  ARCH_INDEPENDENT)

configure_package_config_file (cmake/config.cmake foleys_video_engine-config.cmake
                               INSTALL_DESTINATION "${FVE_INSTALL_DEST}" 
                               NO_SET_AND_CHECK_MACRO)

install (FILES "${CMAKE_CURRENT_BINARY_DIR}/foleys_video_engine-config-version.cmake"
               "${CMAKE_CURRENT_BINARY_DIR}/foleys_video_engine-config.cmake" 
        DESTINATION "${FVE_INSTALL_DEST}"
        COMPONENT foleys_video_engine)

export (PACKAGE foleys_video_engine)
