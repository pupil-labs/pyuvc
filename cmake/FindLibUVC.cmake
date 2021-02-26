# FindLibUVC.cmake
#
# Uses environment variable LibUVC_ROOT as backup search path
#
# - LibUVC_FOUND
# - LibUVC_INCLUDE_DIRS
# - LibUVC_LIBRARIES

FIND_PATH(LibUVC_INCLUDE_DIRS
    libuvc.h
    DOC "Found LibUVC include directory"
    PATHS
        # Unix - compiled from source
        "/usr/local"
        # TODO: Add Windows paths
        # custom
        ENV LibUVC_ROOT
    PATH_SUFFIXES
        "include"
        "include/libuvc"
)

FIND_LIBRARY(LibUVC_LIBRARIES
    NAMES
        libuvc.dylib # macOS
    DOC "Found LibUVC library path"
    PATHS
        # Unix - compiled from source
        "/usr/local"
        # TODO: Add Windows paths
        # custom
        ENV LibUVC_ROOT
    PATH_SUFFIXES
        "lib"
)

# TODO: Set paths to Windows DLLs

IF(LibUVC_INCLUDE_DIRS AND LibUVC_LIBRARIES)
INCLUDE(CheckCSourceCompiles)
set(CMAKE_REQUIRED_INCLUDES ${LibUVC_INCLUDE_DIRS})
set(CMAKE_REQUIRED_LIBRARIES ${LibUVC_LIBRARIES})
# TODO: Try to init UVC context in compiled test program
check_c_source_compiles("#include \"libuvc.h\"\nint main(void) { return 0; }" LibUVC_WORKS)
set(CMAKE_REQUIRED_DEFINITIONS)
set(CMAKE_REQUIRED_INCLUDES)
set(CMAKE_REQUIRED_LIBRARIES)
ENDIF()

INCLUDE(FindPackageHandleStandardArgs)
FIND_PACKAGE_HANDLE_STANDARD_ARGS(LibUVC FOUND_VAR LibUVC_FOUND
  REQUIRED_VARS LibUVC_LIBRARIES LibUVC_INCLUDE_DIRS LibUVC_WORKS)
