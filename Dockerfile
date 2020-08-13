FROM ubuntu:18.04

RUN apt update && apt install -y sysstat fio

COPY entrypoint.sh /

ENTRYPOINT ["/entrypoint.sh"]
