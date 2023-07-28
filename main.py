# importación de las librerías necesarias
import json
import numpy as np
from fastapi import FastAPI
from pydantic import BaseModel
import joblib
from typing import List
from rich import print
from datetime import datetime


# carga del modelo
model = joblib.load("pickle_model.pkl")

# definición de la entrada de datos
class DataInput(BaseModel):
    data: List[int]

    def to_dict(self):
        return {"data": self.input1}

# creación de la aplicación
app = FastAPI()

# ruta para realizar predicciones
@app.get("/")
def hola():
#    input_data = [[data.input1, data.input2]]
#    prediction = model.predict(input_data)[0]
    return {"message": "API REST MODEL"}

# ruta para realizar predicciones
@app.post("/predict")
def predict(data_input: DataInput):
    X = np.array(data_input.data).reshape(-1, 1).T
    prediction = [int(v) for v in model.predict(X)]
    return {"prediction": prediction}

def convert(elem: DataInput):
    return np.array(elem.data).reshape(-1, 1).T


@app.post("/predict_array")
def predict(data_input: List[DataInput]):
    X = np.array(
        # lista comprensiva de array data
        [elem.data for elem in data_input])
    prediction = [int(v) for v in model.predict(X)]
    fecha = datetime.utcnow().isoformat()
    return {"prediction": prediction, "datetime": fecha}
