### Spack Based Docker Image for NEURON Simulations

- Create SSH key-pair

    ```
    ssh-keygen -t rsa -N "" -f docker_rsa
    ```

- Add SSH public key to the server (bbpcode.epfl.ch)

- Clone repository

    ```
    https://github.com/pramodk/neuron-docker-spack.git
    cd neuron-docker-spack
    ```

- Build image

    ```
    docker build --build-arg username=kumbhar --build-arg password=kumbhar123 --build-arg git_name="Pramod Kumbhar" --build-arg git_email="pramod.s.kumbhar@gmail.com"  --build-arg ldap_username=kumbhar -t cellular .
    ```
This will build all neuron based simulation toolchain and also run test simulation.


- To run simulation within a container:

    ```
    docker run -i -t cellular:latest /bin/bash
    cd sim/build/circuitBuilding_1000neurons/
    module load neurodamus
    mpirun -n 4 special $HOC_LIBRARY_PATH/init.hoc -mpi
    ```

- Notes :
    * Do not push the image
    * Remove ssh key from server once the image is built
    * Need to squash all layes
