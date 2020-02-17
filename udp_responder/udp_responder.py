import socket
import os

# UDP Server used to pair mobile and desktop app
# When receive a message "Airett Mobile App", respond with "Airett Local Server"
# from the message, the mobile app will discover the IP of the local server
# WARNING to apply changes you have to run docker-compose build

UDP_IP = "0.0.0.0"
UDP_PORT = int(os.environ['UDP_PORT'])

print "Airett UDP Responder on port", UDP_PORT

serversocket = socket.socket(socket.AF_INET, # Internet
                     socket.SOCK_DGRAM) # UDP
serversocket.bind((UDP_IP, UDP_PORT))

while True:
    data, addr = serversocket.recvfrom(1024) # buffer size is 1024 bytes
    print data
    print addr
    # Send a generic response message to mobile, from the message it will obtain the address
    if data == "Airett Mobile App":
        response = "Airett Local Server"
        serversocket.sendto(response.encode(), addr)

