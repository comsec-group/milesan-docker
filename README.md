# MileSan Docker
This docker setup aims to facilitate usage and encourage further development of MileSan and RandOS, as introduced in [MileSan: Detecting Exploitable Microarchitectural Leakage via Differential Hardware-Software Taint Tracking at CCS'25](https://comsec-files.ethz.ch/papers/milesan_ccs25.pdf).

Build the docker image by running
```
./build.sh
```
By default, building the instrumented verilator targets is skipped. However, it can be enabled by setting the COMPILE_VERILATOR_TARGETS environment variable, e.g.:

```
COMPILE_VERILATOR_TARGETS=true ./build.sh
```
and run it with

```
docker run -it -v [path_to_mnt]:/mnt milesan-docker-ccs bash
```
where *[path_to_mnt]* is a directory to be shared between the host and the docker container. This is required when using ModelSim from the host system.

Finally, move all contents of */tmp_mnt* to */mnt* to make them available to ModelSim in the host system:
```
mv /tmp_mnt/* /mnt/
```
From there on, follow the instructions in *[/mnt/milesan-meta/README.md](https://github.com/comsec-group/milesan-meta)*.

