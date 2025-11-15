FROM ubuntu:24.04@sha256:c35e29c9450151419d9448b0fd75374fec4fff364a27f176fb458d472dfc9e54

ENV container=docker
ENV DEBIAN_FRONTEND=noninteractive

RUN apt update && apt install -y wget && apt clean && apt autoremove -y && rm -rf /**var**/lib/apt/lists/*

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
