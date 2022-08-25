cdef extern from "stdint.h":
    ctypedef unsigned long long uint64_t

cdef extern from "<mach/mach_time.h>":
    cdef struct mach_timebase_info:
        int    numer
        int    denom
    ctypedef mach_timebase_info mach_timebase_info_data_t
    ctypedef mach_timebase_info *mach_timebase_info_t
    int get_mach_timebase_info "mach_timebase_info" (mach_timebase_info_t info)
    uint64_t mach_absolute_time()



cdef double timeConvert = 0.0

cdef double get_sys_time_monotonic():
    cdef mach_timebase_info_data_t timeBase
    global timeConvert
    if timeConvert == 0.0:
        get_mach_timebase_info(&timeBase)
        timeConvert = <double>timeBase.numer /<double>timeBase.denom / 1000000000.0
    return mach_absolute_time( ) * timeConvert



