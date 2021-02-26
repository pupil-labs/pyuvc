# FindTurboJPEG.cmake
#
# Uses environment variable TurboJPEG_ROOT as backup search path
#
# - TurboJPEG_FOUND
# - TurboJPEG_INCLUDE_DIRS
# - TurboJPEG_LIBRARIES

FIND_PATH(TurboJPEG_INCLUDE_DIRS
    turbojpeg.h
    DOC "Found TurboJPEG include directory"
    PATHS
        # macOS
        "/usr/local/opt/jpeg-turbo" # homebrew (x86_64)
        "/opt/homebrew/opt/jpeg-turbo" # homebrew (arm64)
        # TODO: Add Ubuntu paths
        # TODO: Add Windows paths
        # custom
        ENV TurboJPEG_ROOT
    PATH_SUFFIXES
        "include"
)

FIND_LIBRARY(TurboJPEG_LIBRARIES
    NAMES
        turbojpeg # macOS
    DOC "Found TurboJPEG library path"
    PATHS
        # macOS
        "/usr/local/opt/jpeg-turbo" # homebrew (x86_64)
        "/opt/homebrew/opt/jpeg-turbo" # homebrew (arm64)
        # TODO: Add Ubuntu paths
        # TODO: Add Windows paths
        # custom
        ENV TurboJPEG_ROOT
    PATH_SUFFIXES
        "lib"
)

# TODO: Set paths to Windows DLLs

IF(TurboJPEG_INCLUDE_DIRS AND TurboJPEG_LIBRARIES)
INCLUDE(CheckCSourceCompiles)
set(CMAKE_REQUIRED_INCLUDES ${TurboJPEG_INCLUDE_DIRS})
set(CMAKE_REQUIRED_LIBRARIES ${TurboJPEG_LIBRARIES})
check_c_source_compiles("#include <turbojpeg.h>\nint main(void) { tjhandle h=tjInitCompress(); return 0; }" TurboJPEG_WORKS)
set(CMAKE_REQUIRED_DEFINITIONS)
set(CMAKE_REQUIRED_INCLUDES)
set(CMAKE_REQUIRED_LIBRARIES)
ENDIF()

INCLUDE(FindPackageHandleStandardArgs)
FIND_PACKAGE_HANDLE_STANDARD_ARGS(TurboJPEG FOUND_VAR TurboJPEG_FOUND
  REQUIRED_VARS TurboJPEG_LIBRARIES TurboJPEG_INCLUDE_DIRS TurboJPEG_WORKS)
