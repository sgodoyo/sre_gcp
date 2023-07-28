FROM python:3.9

MAINTAINER Sebastian Godoy Olivares <shackleton@riseup.net>

ENV PYTHONDONTWRITEBYTECODE 1
ENV PYTHONUNBUFFERED 1

WORKDIR /app

COPY requirements.txt .

COPY pickle_model.pkl .

RUN pip install --upgrade pip

COPY . .

RUN pip install scikit-learn

RUN pip install -r requirements.txt

EXPOSE 8000

CMD ["uvicorn", "main:app", "--host", "0.0.0.0", "--port", "8000"]
