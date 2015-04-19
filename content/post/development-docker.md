+++
Categories = ["Development", "GoLang"]
Description = ""
Tags = ["Development", "golang", "Docker", "Docker-Compose", "make"]
date = "2015-04-12T23:42:00-04:00"
menu = "main"
title = "Using Docker for Development"

+++

<br/>
Docker is the new kid on the block.  I believe it is going to change how we develop software.
Over the past few months, I have been trying to fit Docker into my daily workflow.  I finally cracked the formula.  It is amazing how easy it is.  We are going to piece together make, docker, and docker-compose (formerly known as fig) to streamline the workflow.

For the purpose of this article, we are going to assume we have a web application which needs a postgres database as the backend.  With the power of docker and docker compose, we can quickly spin up the database quickly.

Let's just say you already have the following Production Dockerfile configured.
```
FROM kennethzfeng/dockerize-python:2.7.8-onbuild


EXPOSE 8000

ENV APPLICATION_ENV Production

CMD ["gunicorn", "app:app", "--worker-class", "gevent", "-b", "0.0.0.0:8000"]

```
You need to create a development version of Dockerfile called it something like `Dockerfile.dev`.  Since we are going to mount the repository on the host machine to the web container instead of copying them over to the container on every signle build, this not only will save us tons Of time when building images, but also will serve as our hot reload.

Specifically, we mount the repository directory ```.``` on the host machine to ```/usr/src/app``` inside the web container.


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

At the time of writing this, Docker Compose doesn't support building image using any file other than the default ```Dockerfile```.  (If you find a way to do this, please let me know.)  A workaround was using a Makefile goal to automate this.

```
docker_build_image:
    docker build -f Dockerfile.dev --name demo-app-dev .
```

***Docker-Compose***

Docker-Compose is very important to this whole workflow because it saves us from managing the container lifecycle ourselves.  

For example:

```
# create the container
docker run --name abc demo-app-dev

# done with the container
# kill the container and remove the container
docker kill abc
docker rm abc
```
This is just for managing the web container.  We are not even couting all of the other work you need to do with the database container and linking them together.

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

With docker-compose, you can build up a quite a bit of automation with make which you can then treat the entire stack as a service that you can just do service up and service down.

```Makefile
app=demo-app

docker_dev_build:
    docker build -t $(app)-dev -f Dockerfile.dev .

docker_dev_up:
    docker-compose -f dev.yml up

docker_dev_rm:
    docker-compose -f dev.yml rm
```

***Initial Setup***

For initializing the database for the first time, we can set up have docker-compose execute the psql utility to create some databases for development and testing.  In addition, I added the psql goal to give me quick access to the psql utility inside the container.

```
create_db:
	docker-compose -f dev.yml run db sh -c \
		'psql -h "$$DB_PORT_5432_TCP_ADDR" -p "$$DB_PORT_5432_TCP_PORT" -U "$$DB_ENV_POSTGRES_USER" -c "CREATE DATABASE core"'
	docker-compose -f dev.yml run db sh -c \
		'psql -h "$$DB_PORT_5432_TCP_ADDR" -p "$$DB_PORT_5432_TCP_PORT" -U "$$DB_ENV_POSTGRES_USER" -c "CREATE DATABASE test"'

psql:
	docker-compose -f dev.yml run db sh -c \
		'psql -h "$$DB_PORT_5432_TCP_ADDR" -p "$$DB_PORT_5432_TCP_PORT" -U "$$DB_ENV_POSTGRES_USER"'
```


Once we have all of the databases created, we can execute the init script from Python which will create all the tables.  Also, I can run my unit test within the same environment.

```
init_db:
	docker-compose -f dev.yml run web python manage.py init

test:
	docker-compose -f dev.yml run web nosetests -v
```

***Conclusion***

With this approach, we can produce a reproducible environment for development and testing.  Instead of using a different database such as SQLite, or setting up a local instance of Postgres which will like to change over time, we can reproduce the same environment rapidly using make, docker, and docker-compose.
