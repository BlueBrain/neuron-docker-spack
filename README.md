### Building NEURON with Dockerfile

```
docker build -t neuron-hbp .
```

### Run docker image

```
docker run -it neuron-hbp bash
```

Test NEURON

```
export PYTHONPATH=/home/kumbhar/install-7.7/lib/python/:$PYTHONPATH
python3 -c "from neuron import test; test()"
```


