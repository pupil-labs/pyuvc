cmake_minimum_required(VERSION 3.24)
project(pyuvc
    LANGUAGES C
    DESCRIPTION "Python bindings for the Pupil Labs libuvc library"
    HOMEPAGE_URL "https://github.com/pupil-labs/pyuvc"
)
cmake_policy(SET CMP0054 NEW)

option(FORCE_LOCAL_LIBUVC_BUILD "Build local libuvc, even if an installed version was found" OFF)
message(STATUS "FORCE_LOCAL_LIBUVC_BUILD=${FORCE_LOCAL_LIBUVC_BUILD}")

find_package(libuvc QUIET)

if(NOT ${libuvc_FOUND})
    option(UVC_DEBUGGING "Enable UVC debug logs" OFF)
    message(STATUS "UVC_DEBUGGING=${UVC_DEBUGGING}")

    if(${UVC_DEBUGGING} AND UNIX)
        SET(CMAKE_C_FLAGS "-g  -DUVC_DEBUGGING")
    endif()

    add_subdirectory(../libuvc-source skbuild-libuvc)

    if(APPLE)
        set(CMAKE_INSTALL_RPATH @loader_path/${CMAKE_INSTALL_LIBDIR})
    elseif(UNIX)
        set(CMAKE_INSTALL_RPATH $ORIGIN/${CMAKE_INSTALL_LIBDIR})
    endif()
elseif(UNIX)
    message(STATUS "Setting RPATH to ${libuvc_LIBRARY_DIRS}")
    set(CMAKE_INSTALL_RPATH ${libuvc_LIBRARY_DIRS})
endif()

# find skbuild cmake packages
find_package(PythonExtensions REQUIRED)
find_package(Cython REQUIRED)

# find external cmake packages
find_package(NumPy REQUIRED)

if(UNIX)
    find_package(PkgConfig)
    pkg_check_modules(libturbojpeg REQUIRED libturbojpeg)
    pkg_check_modules(LIBUSB REQUIRED libusb-1.0)
else()
    set(TURBOJPEG_WIN_INCLUDE_DIR "NOTSET" CACHE PATH "Path to the libturbojpeg include dir")
    set(TURBOJPEG_WIN_IMPORT_LIB_PATH "NOTSET" CACHE FILEPATH "Path to the libturbojpeg import library")

    list(APPEND required_variables
        TURBOJPEG_WIN_INCLUDE_DIR
        TURBOJPEG_WIN_IMPORT_LIB_PATH
    )
    message(STATUS "Validating config:")

    foreach(VAR IN LISTS required_variables)
        if(${VAR} STREQUAL "NOTSET")
            message(FATAL_ERROR "Required variable ${VAR} is not set!")
        endif()
    endforeach()

    foreach(VAR IN LISTS required_variables)
        message(STATUS "  ${VAR}: ${${VAR}}")
    endforeach()

    add_definitions("-D_TIMESPEC_DEFINED")
endif()

# Note: add_cython_target does not actually add a target, but fills a variable with the
# corresponding compiled source file, e.g. here 'uvc_bindings.c'. If only the
# name is specified, it will look for a cython file with the same base name:
# 'uvc_bindings.pyx' in this case.
set(CYTHON_ANNOTATE TRUE)
add_cython_target(uvc_bindings C PY3) # CXX does not generate a corretc module

# Create a module library from the source file and wrap it with settings for
# creating a python extension.
add_library(uvc_bindings MODULE ${uvc_bindings})
python_extension_module(uvc_bindings)

# include cpp folder for finding headers
target_include_directories(uvc_bindings PRIVATE ".")

# include numpy headers
target_include_directories(
    uvc_bindings
    PRIVATE
    ${NumPy_INCLUDE_DIRS}

    # Unix
    ${LIBUSB_INCLUDE_DIRS}
    ${libturbojpeg_INCLUDE_DIRS}

    # Windows vars
    ${LIBUSB_WIN_INCLUDE_DIR}
    ${TURBOJPEG_WIN_INCLUDE_DIR}
)

target_link_directories(uvc_bindings PRIVATE ${libturbojpeg_LIBRARY_DIRS})

target_link_libraries(
    uvc_bindings
    PLLibUVC::uvc
    ${libturbojpeg_LIBRARIES}

    # Windows
    ${TURBOJPEG_WIN_IMPORT_LIB_PATH}
)

# install here
install(TARGETS uvc_bindings LIBRARY DESTINATION ".")
