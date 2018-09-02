FROM ubuntu:18.04
MAINTAINER Pramod Kumbhar <pramod.kumbhar@epfl.ch>
ENV DEBIAN_FRONTEND noninteractive

# default software required
RUN apt-get update \
    && apt-get -y install software-properties-common \
    && add-apt-repository ppa:ubuntu-toolchain-r/test \
    && apt-get update \
    && apt-get -y --force-yes install \
    aptitude \
    cmake \
    build-essential \
    git \
    software-properties-common \
    sudo \
    vim \
    zlib1g-dev \
    libbz2-dev \
    curl \
    gfortran \
    unzip \
    bison \
    flex \
    pkg-config \
    autoconf \
    automake \
    make \
    python2.7-dev \
    libncurses-dev \
    openssh-server \
    libmpich-dev \
    libhdf5-serial-dev \
    python-minimal \
    libtool \
    tcl-dev \
    && rm -rf /var/lib/apt/lists/*

# default arguments
ARG username=kumbhar
ARG password=kumbhar123
ARG git_name="Pramod Kumbhar"
ARG git_email="pramod.s.kumbhar@gmail.com"
ARG ldap_username=kumbhar

# username password
ENV USERNAME $username
ENV PASSWORD $password
ENV GIT_NAME $git_name
ENV GIT_EMAIL $git_email
ENV LDAP_USERNAME $ldap_username

# user setup (ssh login fix, otherwise user is kicked off after login)
RUN mkdir /var/run/sshd \
    && echo 'root:root' | chpasswd \
    && sed -ri 's/^#?PermitRootLogin\s+.*/PermitRootLogin yes/' /etc/ssh/sshd_config \
    && sed -ri 's/UsePAM yes/#UsePAM yes/g' /etc/ssh/sshd_config

# add USER
RUN useradd -m -s /bin/bash ${USERNAME} \
    && echo "${USERNAME}:${PASSWORD}" | chpasswd \
    && adduser ${USERNAME} sudo \
    && echo ${USERNAME}' ALL=(ALL) NOPASSWD: ALL' >> /etc/sudoers

ENV NOTVISIBLE "in users profile"
RUN echo "export VISIBLE=now" >> /etc/profile

# expose ssh port
EXPOSE 22
CMD ["/usr/sbin/sshd", "-D"]

# install rest of packages as normal user
USER $USERNAME

# create directories
ENV HOME /home/$USERNAME
ENV SOFTDIR $HOME/softwares
RUN mkdir -p $SOFTDIR
WORKDIR $SOFTDIR

# clone spack
RUN git clone https://github.com/BlueBrain/spack.git
ENV SPACK_ROOT $SOFTDIR/spack
ENV PATH $SPACK_ROOT/bin:$PATH

# setup spack variables
RUN echo "" >> $HOME/.bashrc
RUN echo "#Setup SPACK path" >> $HOME/.bashrc
RUN echo "export SPACK_ROOT=${SPACK_ROOT}" >> $HOME/.bashrc
RUN echo "export PATH=\$SPACK_ROOT/bin:\$PATH" >> $HOME/.bashrc
RUN echo "source \$SPACK_ROOT/share/spack/setup-env.sh" >> $HOME/.bashrc

# see this: http://stackoverflow.com/questions/20635472/using-the-run-instruction-in-a-dockerfile-with-source-does-not-work
RUN sudo rm /bin/sh && sudo ln -s /bin/bash /bin/sh
RUN . $SPACK_ROOT/share/spack/setup-env.sh

# check compilers
RUN spack compiler find
RUN spack compilers

# copy spack config
RUN mkdir -p $HOME/.spack/linux
ADD packages.yaml $HOME/.spack/linux/
ADD modules.yaml $HOME/.spack/linux/
ADD config.yaml $HOME/.spack/linux/

# install module
RUN spack bootstrap
RUN echo "#Setup MODULE path" >> $HOME/.bashrc
RUN echo "MODULES_HOME=`spack location -i environment-modules`" >> $HOME/.bashrc
RUN echo "source \$MODULES_HOME/Modules/init/bash" >> $HOME/.bashrc

# git config
RUN git config --global user.email "${GIT_EMAIL}"
RUN git config --global user.name "${GIT_NAME}"

# make ssh dir and add your private key (don't publish!)
ADD docker_rsa.pub $HOME/.ssh/docker_rsa.pub
ADD docker_rsa $HOME/.ssh/docker_rsa
RUN sudo chmod 400 $HOME/.ssh/docker_rsa
RUN sudo chown -R $USERNAME $HOME/.ssh
RUN ssh-keyscan bbpcode.epfl.ch >> $HOME/.ssh/known_hosts

RUN echo "Host bbpcode.epfl.ch" >> $HOME/.ssh/config
RUN echo "  HostName bbpcode.epfl.ch" >> $HOME/.ssh/config
RUN echo "  User ${LDAP_USERNAME}" >> $HOME/.ssh/config
RUN echo "  IdentityFile ~/.ssh/docker_rsa" >> $HOME/.ssh/config

# register external packages
RUN spack install autoconf automake bison cmake flex libtool mpich mpich ncurses pkg-config python

# install neuron
RUN spack spec -I neuron
RUN spack install neuron

# check available modules
RUN spack find

######## BBP Specific Software #########

# install neurodamus
RUN spack spec -I neurodamus@master~coreneuron
RUN spack install neurodamus@master~coreneuron

# clone test simulation
RUN git clone ssh://bbpcode.epfl.ch/user/kumbhar/simtestdata $HOME/sim
RUN mkdir $HOME/sim/build \
        && cd $HOME/sim/build \
        && cmake .. \
        && cd circuitBuilding_1000neurons \
        && sed -i "s/CircuitTarget.*/CircuitTarget mini50/g" BlueConfig \
        && sed -i "s/RunMode.*/RunMode RR/g" BlueConfig

# remove ssh keys
RUN rm -rf $HOME/.ssh/docker_rsa*

# run simulation
RUN cd $HOME/sim/build/circuitBuilding_1000neurons \
    && . $SPACK_ROOT/share/spack/setup-env.sh \
    && module load neurodamus \
    && mpirun -n 4 special -mpi $HOC_LIBRARY_PATH/init.hoc

# start in $HOME
WORKDIR $HOME
