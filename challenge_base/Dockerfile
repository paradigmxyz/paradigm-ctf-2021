FROM python:3.9.1-buster

ENV PORT=31337

RUN true \
    && mkdir /var/log/ctf \
    && mkdir /startup \
    && apt update \
    && apt install -y xinetd tini \
    && rm -rf /var/cache/apt/archives \
    && useradd -m ctf \
    && true

COPY 00-create-xinetd-service /startup
COPY 99-start-xinetd /startup
COPY handler.sh /home/ctf/handler.sh
COPY entrypoint.sh /entrypoint.sh

ENTRYPOINT ["tini", "-g", "--"]
CMD ["/entrypoint.sh"]
