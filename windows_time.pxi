
import time
#on windows
from libc.stdint cimport uint64_t, int64_t

cdef extern from "Windows.h":
    int QueryPerformanceCounter(int64_t *)
    int QueryPerformanceFrequency(int64_t *)
cdef double get_sys_time_monotonic():
    cdef int64_t ts
    cdef int64_t freq
    cdef int64_t t_us
    cdef int64_t fullsecs
    cdef int64_t us_left
    QueryPerformanceCounter(&ts)
    QueryPerformanceFrequency(&freq)
    t_us = (ts * 1000000 )  / freq
    
    fullsecs = t_us / 1000000
    us_left = t_us - fullsecs*1000000

    cdef double secs = <double> fullsecs + <double>us_left/1000000.0
    return secs
