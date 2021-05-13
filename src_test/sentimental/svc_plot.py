import numpy as np
import pandas as pd
import sklearn
import sklearn.datasets as ds
import sklearn.cross_validation as cv
import sklearn.grid_search as gs
import sklearn.svm as svm
import matplotlib as mpl
mpl.use('Agg')
import matplotlib.pyplot as plt

X = np.random.randn(200, 2)
y = X[:,0] + X[:,1] > 1
print X.shape, X[0,0], X[0,1]
print y[0]

est = svm.LinearSVC()
est.fit(X, y)

# Generate a grid in the suqare [-3,3]^2
xx, yy = np.meshgrid(np.linspace(-3,3,500), np.linspace(-3,3,500))
# Flatten the meshgrid so we can apply the decision function
Z = est.decision_function(np.c_[xx.ravel(), yy.ravel()])
# Put the results back in the right 250x250 shape
Z = Z.reshape(xx.shape)

print xx.shape,Z.shape
print 'Two sample points in the grid, first the x-ordinates, then the y'

print xx[0,0], xx[1,0], xx[0,1],xx[1,1]
print yy[0,0], yy[1,0], yy[0,1],yy[1,1]

print 'Now the value of the decision function for those points.  It will be a high positive number for high-confidence positive decisions.'
print 'It will have a low absolute value (near 0) for low-confidence decisions.'
print 'It will change each time you run this notebook, because a new set of random points is chosen on each run.'
print Z[0,0], Z[0,1], Z[1,0], Z[1,1]
print 'The real shape of the data in table form is 250000 2 D points, a 250000x2 array'
print np.c_[xx.ravel(),yy.ravel()].shape
