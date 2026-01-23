FROM ubuntu:24.04@sha256:cd1dba651b3080c3686ecf4e3c4220f026b521fb76978881737d24f200828b2b

ENV container=docker
ENV DEBIAN_FRONTEND=noninteractive

RUN apt install -y wget && rm -rf /**var**/lib/apt/lists/*

WORKDIR /app

COPY src src
#RUN dos2unix src/*
RUN cp /app/src/install.sh /usr/bin/install
RUN echo -e "#\!/bin/bash \n echo \"$(lsb_release -a)\"" > /usr/bin/lsb_release
RUN echo -e "#\!/bin/bash \n echo \"$(hostnamectl)\"" > /usr/bin/hostnamectl
RUN chmod a+x /usr/bin/install
RUN chmod a+x /usr/bin/hostnamectl /usr/bin/lsb_release

RUN bash /app/src/setup.sh && rm -r /app/src

VOLUME [ "/etc/earnapp" ]

CMD ["install"]
