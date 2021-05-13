import statsmodels.tsa.stattools as ts
import numpy as np
import pandas as pd
import pandas.io.data as web

data1 = web.DataReader('FB', data_source='yahoo',start='4/4/2015', end='4/4/2016')
data2 = web.DataReader('AAPL', data_source='yahoo',start='4/4/2015', end='4/4/2016')

data1['key']=data1.index
data2['key']=data2.index

result = pd.merge(data1, data2, on='key')

x1=result['Close_x']
y1=result['Close_y']

coin_result = ts.coint(x1, y1) 
print coin_result
