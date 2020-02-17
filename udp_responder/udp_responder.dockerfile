FROM python:2-alpine
# Since it's a simple app, use the lighter alpine version of the docker image

LABEL maintainer = "Gabriele Gambotto <gambotto@leva.io>"

WORKDIR /usr/src/app

# Port listening for UDP messages, it's overwritten in the docker compose
ENV UDP_PORT 4001

# Code with the UDP server
ADD udp_responder.py ./

# Launch UDP server, -u is to print the logs
CMD [ "python", "-u", "./udp_responder.py" ]

EXPOSE ${UDP_PORT}
EXPOSE ${UDP_PORT}/udp