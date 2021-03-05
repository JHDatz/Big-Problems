import keras
import tensorflow as tf
from keras.models import Sequential
from keras.layers import Dense
import numpy
from numpy import genfromtxt
from sklearn.preprocessing import LabelEncoder
from sklearn.preprocessing import OneHotEncoder
numpy.random.seed(42)

#Load in data
dataset = numpy.genfromtxt('pitch_train.csv', delimiter = ',', dtype=None, encoding=None)
numpy.random.shuffle(dataset[1:,:])
features = dataset[1:,1:18]
labels = dataset[1:,18]

#One-hot encode the labels
label_encoder = LabelEncoder()
integer_encoded = label_encoder.fit_transform(labels)
onehot_encoder = OneHotEncoder(sparse=False)
integer_encoded = integer_encoded.reshape(len(integer_encoded), 1)
onehot_encoded = onehot_encoder.fit_transform(integer_encoded)

#define the model
model = Sequential()
model.add(Dense(25,input_dim = 17, activation = 'relu'))
model.add(Dense(25, activation = 'relu'))
model.add(Dense(25, activation = 'relu'))
model.add(Dense(4,activation = 'softmax'))

# Compile model

model.compile(loss='categorical_crossentropy', optimizer="ADAM", metrics=['accuracy'])

model.fit(features, onehot_encoded, epochs = 15, batch_size = 5, shuffle=True)

# evaluate the model
scores = model.evaluate(features, onehot_encoded)
print("\n%s: %.2f%%" % (model.metrics_names[1], scores[1]*100))
