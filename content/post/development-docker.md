+++
Categories = ["Development", "GoLang"]
Description = ""
Tags = ["Development", "golang"]
date = "2015-04-12T23:42:00-04:00"
menu = "main"
title = "Using Docker for Development"

+++

Docker is the new kid on the block.  It is going to change how we develop software.
Over the past few months, I have been trying to fit Docker into my daily workflow.  I finally cracked the formula.  It is amazing how easy it is.  We are going to piece together make, docker, and docker-compose (formerly known as fig) to streamline the workflow.

For the purpose of this article, we are going to assume we have a webapp which needs a postgres database as the backend.  With the power of docker and docker compose, we can quickly spin up the database quickly.

Let's just say you already have the following Production Dockerfile configured.
```
FROM kennethzfeng/dockerize-python:2.7.8-onbuild


EXPOSE 8000

ENV APPLICATION_ENV Production

CMD ["gunicorn", "app:app", "--worker-class", "gevent", "-b", "0.0.0.0:8000"]

```
You need to create a development version of Dockerfile called it something like `Dockerfile.dev`.  Since, we are going to mirror the repository on the host machine to the web container instead of copying them over to the container during build time, this will serve as some sort of hot reload.

Namely, we mount the repository directory ```.``` on the host machine to ```/usr/src/app``` inside the web container.


```
FROM kennethzfeng/dockerize-python:2.7.8

RUN mkdir -p /usr/src/deps
WORKDIR /usr/src/deps
COPY requirements.txt /usr/src/deps/

RUN pip install -r requirements.txt

EXPOSE 8000

ENV APPLICATION_ENV Development
VOLUME /usr/src/app
WORKDIR /usr/src/app

CMD ["python", "run_dev.py"]
```

***Building the Image***

At the time of writing this, Docker Compose doesn't support building image using any file other than ```Dockerfile```.  (If you find a way to do this, please let me know.)  A workaround was using a Makefile goal to automate this.

```
...
docker_build_image:
    docker build -f Dockerfile.dev --name demo-app-dev .
...
```

***Docker-Compose***

Docker-Compose is very important to this whole workflow because it saves us from managing the container lifecycle.  Like, ```docker run --name abc; docker kill abc; docker rm abc```

```
web:
  image: demo-app-dev
  volumes:
    - .:/usr/src/app
  ports:
    - "80:8000"
  links:
    - db

db:
  image: postgres:9.3
  ports:
    - "5432:5432"
  environment:
    POSTGRES_USER: postgres
    POSTGRES_PASSWORD: ""
    PGPASSWORD: ""
```

With docker-compose,

```Makefile
app=demo-app

docker_dev_build:
    docker build -t $(app)-dev -f Dockerfile.dev .

docker_dev_up:
    docker-compose -f dev.yml up

docker_dev_rm:
    docker-compose -f dev.yml rm
```
