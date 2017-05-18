
import time
#on windows

epoch = time.monotonic()-time.perf_counter()

def get_sys_time_monotonic():
    return time.perf_counter()+epoch

