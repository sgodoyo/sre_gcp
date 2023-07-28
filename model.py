import pandas as pd
import numpy as np
import time
import pickle

from sklearn.linear_model import LogisticRegression
from sklearn.metrics import confusion_matrix, classification_report

import xgboost as xgb
from xgboost import plot_importance

import warnings
warnings.filterwarnings('ignore')


x_train = pd.read_csv('datasets/x_train.csv', header = None).to_numpy()
y_train = np.ravel(pd.read_csv('datasets/y_train.csv', header = None).to_numpy())
x_test = pd.read_csv('datasets/x_test.csv', header = None).to_numpy()
y_test = np.ravel(pd.read_csv('datasets/y_test.csv', header = None).to_numpy())

# %%
print(x_train.shape, x_test.shape)
print(y_train.shape, y_test.shape)


logReg = LogisticRegression()
model = logReg.fit(x_train, y_train)


start = time.time()
y_pred = model.predict(x_test)
end = time.time()
print("Tiempo en predicción:", end - start, "[s]")


confusion_matrix(y_test, y_pred)

print(classification_report(y_test, y_pred))


modelxgb = xgb.XGBClassifier(random_state=1, learning_rate=0.01, objective='binary:logistic')
modelxgb = modelxgb.fit(x_train, y_train)


start = time.time()
y_predxgb = modelxgb.predict(x_test)
end = time.time()
print("Tiempo en predicción:", end - start, "[s]")


confusion_matrix(y_test, y_predxgb)


print(classification_report(y_test, y_predxgb))


logReg = LogisticRegression(class_weight = 'balanced')
model = logReg.fit(x_train, y_train)

start = time.time()
y_pred = model.predict(x_test)
end = time.time()
print("Tiempo en predicción:", end - start, "[s]")

confusion_matrix(y_test, y_pred)

print(classification_report(y_test, y_pred))


n_y0 = len(y_train[y_train == 0])
n_y1 = len(y_train[y_train == 1])
scale = n_y0/n_y1
print(scale)


modelxgb = xgb.XGBClassifier(random_state=1, learning_rate=0.01, objective='binary:logistic', scale_pos_weight = scale)
modelxgb = modelxgb.fit(x_train, y_train)

start = time.time()
y_predxgb = modelxgb.predict(x_test)
end = time.time()
print("Tiempo en predicción:", end - start, "[s]")

confusion_matrix(y_test, y_predxgb)

print(classification_report(y_test, y_predxgb))
