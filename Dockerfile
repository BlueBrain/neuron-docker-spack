FROM ubuntu:18.04
MAINTAINER Pramod Kumbhar <pramod.s.kumbhar@gmail.com>
ENV DEBIAN_FRONTEND noninteractive

# default softwares
RUN apt-get update \
    && apt-get -y install software-properties-common \
    && add-apt-repository ppa:ubuntu-toolchain-r/test \
    && apt-get update \
    && apt-get -y --allow-downgrades --allow-remove-essential --allow-change-held-packages install \
       aptitude \
       cmake \
       build-essential \
       git \
       software-properties-common \
       sudo \
       vim \
       curl \
       bison \
       flex \
       pkg-config \
       autoconf \
       automake \
       make \
       python2.7-dev \
       libncurses-dev \
       libncursesw5-dev \
       openssh-server \
       python-minimal \
       libtool \
       libpciaccess-dev \
       python3.7-dev \
       python3.6-dev \
       python3.8-dev \
       python2.7-dev \
       python-scipy \
       python-numpy \
       python3-scipy \
       python3-numpy \
       cython \
       cython3 \
       libopenmpi-dev \
       openmpi-bin \
    && rm -rf /var/lib/apt/lists/*

EXPOSE 22

RUN mkdir /home/kumbhar
WORKDIR /home/kumbhar

RUN git clone https://github.com/neuronsimulator/nrn.git nrn-master

RUN mkdir -p nrn-master/build \
    && cd nrn-master/build

# install and test neuron master
RUN cd /home/kumbhar/nrn-master \
    && ./build.sh \
    && cd build \
    && ../configure --without-iv --with-paranrn=dynamic --with-readline=yes --with-nrnpython=dynamic --prefix=/home/kumbhar/install-master \
    && make -j \
    && make install

RUN export PYTHONPATH=/home/kumbhar/install-master/lib/python/:$PYTHONPATH \
    && python3 -c "from neuron import test; test()"

# install and test neuron 7.7.2
RUN wget https://neuron.yale.edu/ftp/neuron/versions/v7.7/7.7.2/nrn-7.7.2.tar.gz \
    && tar -xvzf nrn-7.7.2.tar.gz \
    && cd nrn-7.7 \
    && ./configure --without-iv --with-paranrn=dynamic --with-readline=yes --with-nrnpython=dynamic --prefix=/home/kumbhar/install-7.7 \
    && make \
    && make install

RUN export PYTHONPATH=/home/kumbhar/install-7.7/lib/python/:$PYTHONPATH \
    && python3 -c "from neuron import test; test()"

CMD ["/usr/sbin/sshd", "-D"]
