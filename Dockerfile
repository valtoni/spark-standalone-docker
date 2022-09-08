FROM ubuntu:22.10

#RUN echo "deb mirror://mirrors.ubuntu.com/mirrors.txt kinetic main restricted" > /etc/apt/sources.list
#RUN apt-get install --reinstall ca-certificates

RUN sed -i -e 's/http:\/\/security/mirror:\/\/mirrors/' -e 's/http:\/\/archive/mirror:\/\/mirrors/' -e 's/\/ubuntu\//\/mirrors.txt/' /etc/apt/sources.list && \
    apt update && \
    apt install -y curl wget

RUN apt install -y openjdk-8-jre-headless && \
    apt install -y scala

RUN apt install -y openssh-server openssh-client

RUN APACHE_MIRROR=$(curl 'https://www.apache.org/dyn/closer.cgi' | grep -o '<strong>[^<]*</strong>' | sed 's/<[^>]*>//g' | head -1) &&\
    wget ${APACHE_MIRROR}spark/spark-3.3.0/spark-3.3.0-bin-hadoop3.tgz && \
    mkdir -p /usr/local/spark && \
    export SPARK_HOME=/usr/local/spark && \
    export PATH=${SPARK_HOME}:${PATH} &&\
    #echo "export PATH=/usr/local/spark/bin:＄PATH" >> ~/.profile && \
    tar xvfz spark-3.3.0-bin-hadoop3.tgz && \
    mv spark-3.3.0-bin-hadoop3/* /usr/local/spark && \
    rm -Rf spark-3.3.0-bin-hadoop3 && \
    rm spark-3.3.0-bin-hadoop3.tgz

#COPY spark-env.sh /usr/local/spark/conf

COPY custom-run-worker.sh /usr/local/spark/sbin

#ENTRYPOINT sh /usr/local/spark/sbin/start-all.sh
