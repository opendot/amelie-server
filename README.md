# Amelie
 Amelie Suite is a set of software co-designed for people suffering from Rett's syndrome characterized by an innovative way of interaction between care-giver and care-receiver, both equipped with an instrument on their own device, and through the use of an eyetracker (which allows you to track the look of the subject and to determine which point on the screen is watching).


Amelie is an open source software and accessible to everyone, co-designed by designers, developers, university researchers, families and therapists. Amelie promotes communication and cognitive enhancement for learning and improving interaction and understanding skills.
The system integrates different technologies (mobile applications, cloud services and adaptive algorithms) to provide an innovative, comprehensive and easy-to-use service. 


The software was born from an idea of Associazione Italiana Rett - AIRETT Onlus and Opendot S.r.l., and was designed and developed by Opendot S.r.l., with the essential contribution of Associazione Italiana Rett - AIRETT Onlus.

This repository hosts the server component of the system, providing all the core functionalities.

# Amelie Rails Server

Ruby on Rails 5 API-server of the Amelie system.
It's the core of the system, it:
- stores the contents and the sessions created
- allows the [mobile app](https://github.com/opendot/amelie-mobile), the [desktop webapp](https://github.com/opendot/amelie-communicator) and the eyetracker to communicate
- allows users the share contents of the same patient
- allows researchers to obtain informations and statistics about the patients

## Table of Contents
- [Setup](#Setup)
- [Usage](#Usage)
- [Background](#Background)

## Setup
The project is configured as a micro-services multi-container architecture, where each container is focused on a specific task; these containers are linked together via a `docker network`.

You must have Docker installed in your computer, [download](https://www.docker.com/get-started) and [install](https://docs.docker.com/docker-for-windows/install/) it.

Next you have to choose the environment you want to use. The available environments are:
- staging_local: if you want to use Amelie on your computer
- multiple: used for development

First you have to build all the docker images, this requires an internet connection.
```
docker-compose -f docker-compose.staging_local.yml build
```
Replace `docker-compose.staging_local.yml` with the `docker-compose.*.yml` file of the environment that you want.<br>
This will download and build the docker images from their online repositories and build the custom ones. It will take some minutes.

To launch the api server, we created some `.sh` scripts that do all the necessary operations. Enter in the folder from the terminal and execute the one with the correct environment:
```
sh start_and_reset_staging_local.sh
```

For every environment we have 2 scripts:
- start: run rails migrations and start the server
- start_and_reset: reset and initialize the database, run migrations and start the server

The first time you launch the server you must use `start_and_reset` to initialize the database.

### Running Docker on Virtual Machine (Windows)
If you installed Docker with [Docker Toolbox](https://docs.docker.com/toolbox/overview/) on a virtual machine, you must forward the ports used inside Docker to make the server accessible. You must forwards the ports:
- 3001: for the _local_ server
- 3002: if the _remote_ server is running
- 4001: for the udp server
More information about ports in the [Ports](#ports) section.


## Usage
To start the server you can use the sh script
```
sh start_staging_local.sh
```
The script starts all the containers and shows their logs, the server is fully started when the containers `api` and `sidekiq` are started and the console stops printing logs.

If you are using only the _remote_ environment you're ready to go.

If you are using the _local_ environment, you have to start the node server that connects to the eyetracker.

Now the server is ready, to start using Amelie you have to activate the eyetracker and start the [desktop webapp](https://github.com/opendot/amelie-communicator) in your browser at full screen.

Now you can use the [mobile app](https://github.com/opendot/amelie-mobile) to create contents and start sessions. The phone **must be in the same network of the computer** running the local server and the desktop webapp.

**IMPORTANT** the first time you use a patient, you should start a synchronization to download from the _remote_ server all existing contents related to that patient.

### About internet connection
You always need a network to allow communication between the different parts of the system, but internet connection is not always required.

The _remote_ server is an online server used to connect many _local_ server, so it needs internet connection.

The _local_ server requires a network to communicate with the mobile app, but most of the times it doesn't require an internet connection. The desktop webapp and the eyetracker are supposed to be in the same computer of the _local_ server, but they communicate through a network.

The local server is _offline first_, it does most of it's work without requiring an internet connection. This allows to work with the Amelie system by using the mobile tethering of your phone.

The internet connection is required:
- when a user first login: users and patients are created in the _remote_ server, they must be retrieved
- when starting a synchronization: to upload and download contents from the _remote_ server

When working with development _multiple_, both the _local_ and _remote_ servers are on the same computer, so internet connection is not required.

## Background
This project uses
- [docker](https://www.docker.com/) as containerization engine
- [docker compose](https://docs.docker.com/compose/) as multi container orchestration
- [passenger](https://www.phusionpassenger.com/) as application server (subscription required for multi-threading support.)
- [rails](http://rubyonrails.org/) as web application framework
- [nginx](http://rubyonrails.org/) as webserver
- [sidekiq container](http://sidekiq.org/) as for background processing (it's a clone of the rails container)
- [redis container](https://hub.docker.com/_/redis/) as queue manager
- [mysql container](https://store.docker.com/images/3083290a-203f-4c04-b2de-cc057959d2c9?tab=description) as staging and developemnt dbms

### Local and Remote environments
This server can work as a local or remote server:
- local: the server installed in the personal computer of the user
- remote: the online server that centralize the Amelie system

For every environment of _development_, _staging_ and _production_ we have a __local_ and a __remote_ version. Each version has a different role and provide different routes.

#### Local
The local server is used to manage the comunication between the [mobile app](https://github.com/opendot/amelie-mobile), the [desktop webapp](https://github.com/opendot/amelie-communicator) and the eyetracker.<br>
Through the mobile app the user can create contents and start sessions, controlling the desktop webapp used by the patient.
When first installed, the local server is empty. It requires an Internet connection to retrieve the users and patients from the remote server, after the first login the user can signin without an internet connection.<br>
The local server can synchronize the contents created by the user with the remote server, this allows to share them with all the users that interact with the patient.

#### Remote
The remote server is used to share informations between users and collect the data of the sessions for research.<br>
Users, patients, preset contents and contents for cognitive enhancement are created only in the remote server, then retrieved by the local server through synchronization.<br>Researchers use the remote server to obtain statistics about the patients.

#### Multiple
This is not an environment, but we have a `docker-compose.multiple.yml`. By using docker, we launch both the _local_ and the _remote_ server in the same machine. This is used for development purpose, when we don't have a _remote_ server available.

### Docker Compose
We use [docker compose](https://docs.docker.com/compose/) as multi container orchestration. The containers we use are:
- **api**: the container that runs the rails api server, which contains the logic of the Amelie system. By setting the environment, it can run as a _local_ or _remote_ server
- **db**: the container that holds the mySQL database for development and staging environments
- **sidekiq**: the container that runs [sidekiq](http://sidekiq.org/), it's where the background jobs are executed. It's spawned from the same image of the rails container so it possess a _local_ or _remote_ environment: it doesn't change its behaviour, but it should be the same environment of the _api_ container
- **redis**: the container that runs redis, the queue manager
- **udp_responder**: an udp server in python, it allows the mobile app to check if there is an Amelie server in the network it's connected to. Used only for _local_ server.

### Ports
The server is formed by many micro-services and uses many ports to communicate:
- 3000: used by the [desktop webapp](https://github.com/opendot/amelie-communicator), it's used by the node server that builds ReactJS
- 3001: used by the _local_ rails api server
- 3002: used by the _remote_ rails api server
- 4000: used by the node server of the eyetracker
- 4001: used by the udp server
- 6379: used by redis

The ports used inside the docker network are forwarded on the same port of the computer.

### Remote Server Deploy
Staging environment is running on [Amazon Web Services](https://aws.amazon.com/).

Production environment is not yet configured. 

Since the system is containerised, the remote server can be deployed on any docker compatible infrastructure. A properly configured EC2 instance or ECS can be used to deploy the software tier.

The software is designed to be ephemeral and stateless therefore media and DB storage is external to the software tier.

For media storage we use [Carrierwave](https://github.com/carrierwaveuploader/carrierwave) and [Fog](http://fog.io/), which support [different storage services](http://fog.io/storage/). We are using [Amazon S3](https://aws.amazon.com/s3/). A rule to handle the lifecycle of files is highly recommanded, we use a rule to automatically delete  after few days packages used to let researchers download recorded data of sessions.

DB storage require Mysql DBMS that can be installed on a EC2 instance or provided by RDS managed service.

All the secrets are defined in a configuration file not versioned.

This is a list of the minimum necessary services used with AWS:

- VPC: Networking
- EC2: Computing power
- S3: Media storage
- Route 53: DNS
- ECR: Container registry
- IAM: Identity and access management
- SES: Mailer
- RDS: DBMS
- ELB: Load balancing
