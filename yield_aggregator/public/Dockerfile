FROM ctf/eth_challenge_base:latest

COPY deploy/ /home/ctf/

RUN python3 -m pip install -r /home/ctf/requirements.txt 

# install hh
WORKDIR /home/hh
RUN npm init -y
RUN npm i hardhat
RUN touch hardhat.config.js
