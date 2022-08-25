project(pyuvc)
cmake_minimum_required(VERSION 3.3)

add_subdirectory(../libuvc-source skbuild-libuvc)

# find skbuild cmake packages
find_package(PythonExtensions REQUIRED)
find_package(Cython REQUIRED)

# find external cmake packages
find_package(NumPy REQUIRED)

find_package(PkgConfig)
pkg_check_modules(libturbojpeg REQUIRED libturbojpeg)
pkg_check_modules(LIBUSB REQUIRED libusb-1.0)
pkg_check_modules(libuvc REQUIRED libuvc)

# include cpp folder for finding headers
include_directories(".")

# include numpy headers
include_directories(${NumPy_INCLUDE_DIRS})
include_directories(${libuvc_INCLUDE_DIRS})
include_directories(${libturbojpeg_INCLUDE_DIRS})
include_directories(${LIBUSB_INCLUDE_DIRS})

link_directories(${libuvc_LIBRARY_DIRS} ${libturbojpeg_LIBRARY_DIRS})

# Note: add_cython_target does not actually add a target, but fills a variable with the
# corresponding compiled source file, e.g. here 'pupil_detection_3d.cxx'. If only the
# name is specified, it will look for a cython file with the same base name:
# 'pupil_detection_3d.pyx' in this case.
add_cython_target(uvc CXX PY3)

# Create a module library from the source file and wrap it with settings for
# creating a python extension.
add_library(uvc MODULE ${uvc})
python_extension_module(uvc)

# libuvc_LIBRARIES includes `uvc` which cannot be passed to `target_link_libraries`
# as it will attempt to link to itself and fail. By prepending `-l`, we avoid the
# ambiguity
list(TRANSFORM libuvc_LIBRARIES PREPEND -l)

# link against external libraries
target_link_libraries(uvc ${libuvc_LIBRARIES} ${libturbojpeg_LIBRARIES})

# install here
install(TARGETS uvc LIBRARY DESTINATION ".")