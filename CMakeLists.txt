cmake_minimum_required(VERSION 3.10)
project(uvc)

# Add custom cmake modules to the cmake module search paths
LIST(APPEND CMAKE_MODULE_PATH "${CMAKE_CURRENT_SOURCE_DIR}/cmake")

# Find dependencies
find_package(PythonExtensions REQUIRED)
find_package(Cython REQUIRED)
find_package(NumPy REQUIRED)
find_package(LibUSB REQUIRED)
find_package(LibUVC REQUIRED)

include_directories(${NumPy_INCLUDE_DIRS})
include_directories(${LibUSB_INCLUDE_DIRS})
include_directories(${LibUVC_INCLUDE_DIRS})

add_cython_target(uvc PY3 OUTPUT_VAR _uvc_sources)
add_library(_uvc MODULE ${_uvc_sources})
python_extension_module(_uvc)

# Link external libraries
target_link_libraries(_uvc ${LibUSB_LIBRARIES})
target_link_libraries(_uvc ${LibUVC_LIBRARIES})

install(TARGETS _uvc LIBRARY DESTINATION uvc)
# TODO: Install DLLs into destination for Windows
