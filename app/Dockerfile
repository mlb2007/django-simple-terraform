# pull official base image
FROM python:3.11.1-slim-buster

WORKDIR /app

# Open http port
EXPOSE 8000
EXPOSE 80

#ENV PYTHONUNBUFFERED 1
#ENV PYTHONDONTWRITEBYTECODE 1
#ENV DEBIAN_FRONTEND noninteractive
#
## Install pip and gunicorn web server
#RUN pip install --no-cache-dir --upgrade pip
#RUN pip install gunicorn==20.1.0
#
## Install requirements.txt
#COPY requirements.txt /
#RUN pip install --no-cache-dir -r /requirements.txt

# Moving application files
#WORKDIR /app
#COPY . /app


# set environment variables
ENV PYTHONDONTWRITEBYTECODE 1
ENV PYTHONUNBUFFERED 1

# install dependencies
RUN pip install --upgrade pip
COPY ./requirements.txt .
RUN pip install -r requirements.txt

# copy project
COPY . .

