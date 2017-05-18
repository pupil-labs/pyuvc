cdef extern from "Windows.h":
   unsigned int timeGetTime()

cdef double get_sys_time_monotonic():

    return timeGetTime() * 1e-3
