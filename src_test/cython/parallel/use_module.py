import sumsquare
from time import time

t0 = time()
print(sumsquare.sumsquare(1000), sumsquare.sumsquare(5000))
print("done in %0.5fs." % (time() - t0))

