cdef extern from "Windows.h":
   unsigned int GetTickCount()

cdef double get_sys_time_monotonic():

    return GetTickCount() * 1e-3
