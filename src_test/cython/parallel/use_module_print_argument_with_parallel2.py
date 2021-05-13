from print_argument_with_parallel2 import print_argument

from time import time

t0 = time()

print_argument(9)

print("done in %0.3fs." % (time() - t0))
