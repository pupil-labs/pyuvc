from posix.time cimport timeval,timespec,clock_gettime,CLOCK_MONOTONIC


cdef double get_sys_time_monotonic():
    cdef timespec t
    clock_gettime(CLOCK_MONOTONIC, &t)
    return t.tv_sec + <double>t.tv_nsec * 1e-9
