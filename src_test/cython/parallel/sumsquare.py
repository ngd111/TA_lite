from time import time

def sumsquare(n):
    return sum(i*i for i in range(n))

t0 = time()
print(sumsquare(1000), sumsquare(5000))
print("done in %0.5fs." % (time() - t0))
