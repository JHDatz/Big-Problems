# Joe Datz
# Written in Jupyter Notebook.

import pandas as pd

path = 'C:\\Users\\jhd15\\Desktop\\programming\\Data_Final.csv'

df = pd.read_csv(path)
df = df.reindex(df.PatientID)
df = df.drop('PatientID', axis=1)
df = df[~df.readmitted.isnull()] # gets rid of any undefined row columns specific to readmittance.
df = df.fillna(0) # fills any remaining undefined numbers to 0.

# Import Cell

from sklearn.neighbors import KNeighborsClassifier
from sklearn.model_selection import StratifiedShuffleSplit
from sklearn.model_selection import GridSearchCV
from sklearn.model_selection import RandomizedSearchCV
from sklearn.model_selection import cross_val_predict
from sklearn.decomposition import PCA
from sklearn.svm import SVC
from sklearn.naive_bayes import BernoulliNB
from sklearn.ensemble import RandomForestClassifier
from sklearn.metrics import confusion_matrix
from sklearn.metrics import precision_score
from sklearn.metrics import recall_score
from scipy.stats import randint

# Stratified Shuffle Split Cell, stratified for better model training.

split = StratifiedShuffleSplit(n_splits=1, test_size=0.3, random_state=42)

for train_index, test_index in split.split(df, df.readmitted):
    strat_train_set = df.iloc[train_index]
    strat_test_set = df.iloc[test_index]

y_strat_train = strat_train_set.readmitted
x_strat_train = strat_train_set.drop('readmitted', axis=1)

y_strat_test = strat_test_set.readmitted
x_strat_test = strat_test_set.drop('readmitted', axis=1)

# PCA Module, necessary for models with heavy computation requirements. Reduces data set to approximately 1400 column vectors.

pca = PCA(n_components=0.95)
x_strat_train_reduced = pca.fit_transform(x_strat_train)

# K Nearest Neighbors Cell, requires use of PCA for computation.
# Achieved 96.8% Total Accuracy but 4.9% Accuracy on Readmitted Patients; searching parameters unlikely to help.
# Didn't bother with test set accuracy.

kNN_clf = KNeighborsClassifier(weights='distance', n_neighbors = 2)
#kNN_clf.fit(x_strat_train_reduced, y_strat_train)

y_pred = cross_val_predict(kNN_clf, x_strat_train_reduced, y_strat_train, cv=5)
print('Total Accuracy: ' + str(sum(y_pred == y_strat_train)/len(y_strat_train)))
print('Precision Score with K=5: ' + str(precision_score(y_strat_train, y_pred)))
print('Recall Score with K=5: ' + str(recall_score(y_strat_train, y_pred)))
confusion_matrix(y_strat_train, y_pred)

# Random Forest Cell, PCA is necessary for extended searching.
# 98.6% Total Accuracy but 8.3% on readmitted in CV, with max_depth of 76 and min_samples_split of 22.
# Searching for parameters more unlikely to provide substantial help.
# Didn't bother with test set accuracy.

forest_clf = RandomForestClassifier()

forest_search_area = {'n_estimators': [100], 'max_depth': randint(5,250), 'min_samples_split': randint(2,50),}

forest_rand_search = RandomizedSearchCV(forest_clf, param_distributions = forest_search_area, n_iter=20, cv=3,
                                       random_state=42, scoring='recall', verbose=2)
forest_rand_search.fit(x_strat_train_reduced, y_strat_train)

print('Best Parameters: ' + str(forest_rand_search.best_params_))
print('Accuracy of Random Forest: ' + str(sum(y_strat_train == forest_rand_search.best_estimator_.predict(x_strat_train_reduced))/len(y_strat_train)))
print('Best Recall Score: ' + str(forest_rand_search.best_score_))

# SVM Cell. For linear kernel, does not require supercomputer or PCA. For gaussian kernel, Supercomputer is needed.
# In CV, attained 100% Accuracy largely independent of C parameter. This is definitely a case of overfitting from high dims.
# Achieved 95.6% total accuracy, 42.1% readmitted accuracy in test set.

svc_clf = SVC()

search_area = {'kernel': ['linear'], 'C':[125, 150, 175, 200],}

grid_search = GridSearchCV(svc_clf, search_area, cv=3, scoring='recall', verbose=2)
grid_search.fit(x_strat_train_reduced, y_strat_train)

print('Best Parameters Found: ' + str(grid_search.best_params_))
print('Accuracy of Linear SVM: ' + str(sum(y_strat_train == grid_search.best_estimator_.predict(x_strat_train_reduced))/len(y_strat_train)))
print('Best Recall Score: ' + str(grid_search.best_score_))

# Bernoulli Naive Bayes Cell; no need to use PCA set. Assumes data is in boolean table instead of high-dimensional linear space.
# Achieved 88% total accuracy, 73.7% Accuracy in CV; 88.72% total, 74.0% accuracy in test.

bernoulli_clf = BernoulliNB()

bernoulli_grid = {'alpha': [0.01, 0.02, 0.03, 0.04, 0.05, 0.06, 0.07, 0.08, 0.09, 0.1]}

bernoulli_grid_search = GridSearchCV(bernoulli_clf, bernoulli_grid, scoring='recall', cv=5, verbose=2)
bernoulli_grid_search.fit(x_strat_train, y_strat_train)

print('Best Parameters: ' + str(bernoulli_grid_search.best_params_))
print('Accuracy of Bernoulli Classifier: ' + str(sum(y_strat_train == bernoulli_grid_search.best_estimator_.predict(x_strat_train_reduced))/len(y_strat_train)))
print('Best Recall Score: ' + str(bernoulli_grid_search.best_score_))

# Test Set Accuracy Cell

y_test_pred_svm = grid_search.best_estimator_.predict(pca.transform(x_strat_test))
y_test_pred_bernoulli = bernoulli_grid_search.best_estimator_.predict(x_strat_test)

print('Total Accuracy of SVM: ' + str(sum(y_strat_test == y_test_pred_svm)/len(y_strat_test)))
print('Recall Score: ' + str(recall_score(y_strat_test, y_test_pred_svm)))
print('Total Accuracy of Bernoulli Classifier: ' + str(sum(y_strat_test == y_test_pred_bernoulli)/len(y_strat_test)))
print('Recall Score: ' + str(recall_score(y_strat_test, y_test_pred_bernoulli)))

# Overall best model: Bernoulli Naive Bayes, using an alpha value of 0.09. 88% Total Accuracy, 74.0% Readmitted Accuracy in test.
#
# For the future:
#      Neural Network using tensorflow
#      SVM using Gaussian Kernel; extra dimensionality reduction
#      Using t-Distributed Schochastic Neighbor Embedding to see if any natural clusters form
#      Isolated Forest Anomaly Detection Technique among others
#      Using joblib to store built models
#      Ensemble Modeling