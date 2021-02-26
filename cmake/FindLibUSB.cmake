# FindLibUSB.cmake
#
# Uses environment variable LibUSB_ROOT as backup search path
#
# - LibUSB_FOUND
# - LibUSB_INCLUDE_DIRS
# - LibUSB_LIBRARIES

FIND_PATH(LibUSB_INCLUDE_DIRS
    libusb-1.0/libusb.h
    DOC "Found LibUSB include directory"
    PATHS
        # macOS
        "/usr/local/opt/libusb" # homebrew (x86_64)
        "/opt/homebrew/opt/libusb" # homebrew (arm64)
        # TODO: Add Ubuntu paths
        # TODO: Add Windows paths
        # custom
        ENV LibUSB_ROOT
    PATH_SUFFIXES
        "include"
)

FIND_LIBRARY(LibUSB_LIBRARIES
  NAMES
  libusb-1.0.dylib # macOS
  DOC "Found LibUSB library path"
  PATHS
    # macOS
    "/usr/local/opt/libusb" # homebrew (x86_64)
    "/opt/homebrew/opt/libusb" # homebrew (arm64)
    # TODO: Add Ubuntu paths
    # TODO: Add Windows paths
    # custom
    ENV LibUSB_ROOT
  PATH_SUFFIXES
    "lib"
)

# TODO: Set paths to Windows DLLs

IF(LibUSB_INCLUDE_DIRS AND LibUSB_LIBRARIES)
INCLUDE(CheckCSourceCompiles)
set(CMAKE_REQUIRED_INCLUDES ${LibUSB_INCLUDE_DIRS})
set(CMAKE_REQUIRED_LIBRARIES ${LibUSB_LIBRARIES})
# TODO: Try to init UVC context in compiled test program
check_c_source_compiles("#include \"libusb-1.0/libusb.h\"\nint main(void) { return 0; }" LibUSB_WORKS)
set(CMAKE_REQUIRED_DEFINITIONS)
set(CMAKE_REQUIRED_INCLUDES)
set(CMAKE_REQUIRED_LIBRARIES)
ENDIF()

INCLUDE(FindPackageHandleStandardArgs)
FIND_PACKAGE_HANDLE_STANDARD_ARGS(LibUSB FOUND_VAR LibUSB_FOUND
  REQUIRED_VARS LibUSB_LIBRARIES LibUSB_INCLUDE_DIRS LibUSB_WORKS)
