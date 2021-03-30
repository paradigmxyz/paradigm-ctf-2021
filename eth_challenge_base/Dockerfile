FROM ctf/challenge_base:latest

ENV HTTP_PORT=8545

RUN true \
    && curl -sL https://deb.nodesource.com/setup_current.x | bash - \
    && apt update \
    && apt install -y nodejs \
    && rm -rf /var/cache/apt/archives \
    && npm install -g ganache-cli \
    && pip install web3 flask flask_cors gunicorn \
    && true

COPY 98-start-gunicorn /startup

COPY eth_sandbox /usr/lib/python/eth_sandbox
ENV PYTHONPATH /usr/lib/python
