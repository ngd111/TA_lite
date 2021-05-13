from numthreads_with_parallel import testpar

from time import time

t0 = time()

print testpar(4)

print("done in %0.3fs." % (time() - t0))
