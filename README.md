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
This will build neuron based simulation toolchain and prepare test simulation.


- To run a simulation within a container:

    ```
    docker run -i -t cellular:latest /bin/bash
    cd sim/build/circuitBuilding_1000neurons/
    module load neurodamus/master
    mpiexec -n 6 --host localhost:6 --allow-run-as-root special $HOC_LIBRARY_PATH/init.hoc -mpi
    ```
- To run a simulation by launching a container:

    ```
    docker run -i -t cellular:latest /bin/bash -c -i 'cd $HOME/sim/build/circuitBuilding_1000neurons && module load neurodamus/master && mpiexec -n 6 --host localhost:6 --allow-run-as-root special $HOC_LIBRARY_PATH/init.hoc -mpi'
    ```

- To run on multiple docker containers:
	- Update `docker-compose.yml` specification with appropriate number of compute nodes (`scale` parameter in `node` service)
	- Launch containers with `docker-compose`
	- Find compute nodes IP
	- Run simulation on the running containers

	    ```
	    # start cluster
	    $ docker-compose up -d

	    # check cluster running
	    $ docker ps
		CONTAINER ID        IMAGE               COMMAND               CREATED             STATUS              PORTS                   NAMES
		0b2b5386ce12        cellular:latest     "/usr/sbin/sshd -D"   8 minutes ago       Up 3 minutes        0.0.0.0:32770->22/tcp   neurondockerspack_login_1
		1643c10a96af        cellular:latest     "/usr/sbin/sshd -D"   8 minutes ago       Up 3 minutes        22/tcp                  neurondockerspack_node_1
		7ac4b751c574        cellular:latest     "/usr/sbin/sshd -D"   8 minutes ago       Up 3 minutes        22/tcp                  neurondockerspack_node_3
		60ec8d0e7052        cellular:latest     "/usr/sbin/sshd -D"   8 minutes ago       Up 3 minutes        22/tcp                  neurondockerspack_node_2

		# find ip of compute node
		$ PROC_PER_NODE=2
		$ COMPUTE_NODES=`docker ps -q --filter "name=node_" | xargs docker inspect --format "{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}" | xargs echo | sed -e $"s/ /:$PROC_PER_NODE,/g"`:$PROC_PER_NODE

		# make sure nodes are connected (username used inside container)
		$ USERNAME=kumbhar
		$ docker-compose exec --user $USERNAME --privileged login /bin/bash -c -i "\$MPIEXEC -n 6  --host $COMPUTE_NODES \$HOME/test/hello"
		Hello world from processor 1643c10a96af, rank 0 out of 6 processors
		Hello world from processor 1643c10a96af, rank 1 out of 6 processors
		Hello world from processor 60ec8d0e7052, rank 2 out of 6 processors
		Hello world from processor 60ec8d0e7052, rank 3 out of 6 processors
		Hello world from processor 7ac4b751c574, rank 4 out of 6 processors
		Hello world from processor 7ac4b751c574, rank 5 out of 6 processors

		# run simulation using multiple containers
		$ docker-compose exec --user $USERNAME --privileged login /bin/bash -c "cd \$HOME/sim/build/circuitBuilding_1000neurons && . \$SPACK_ROOT/share/spack/setup-env.sh && module load neurodamus/master && \$MPIEXEC -x HOC_LIBRARY_PATH -n 6 --host $COMPUTE_NODES \$SPECIAL \$HOC_LIBRARY_PATH/init.hoc -mpi"
		....
		numprocs=6
		NEURON -- VERSION + master (9f36b13+) 2018-08-28
		Duke, Yale, and the BlueBrain Project -- Copyright 1984-2018
		See http://neuron.yale.edu/neuron/credits
		Additional mechanisms from files
		....
		create file ./out.dat
					  Event Label  Node  MinTime  Node  MaxTime
		accum                    Synapse init     4     0.00     5     0.04
		accum                       file read     0     0.00     0     0.00
		accum                     Replay init     0     0.00     0     0.00
		accum                         stdinit     2     0.13     4     0.18
		accum                          psolve     4     9.79     3     9.82
		 memusage node 0 according to nrn_mallinfo:
			 59.289062MB

		# remove containers
		$ docker-compose stop && docker-compose down
	    ```

- Notes :
    * Do not push the image
    * Remove ssh key from server once the image is built
    * Todo : need to squash all layes
