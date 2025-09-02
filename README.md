# MileSan Docker
Build the docker by running
```
./build.sh
```
and run it with
```
docker run -it -v [path_to_mnt]:/mnt milesan-docker-ccs bash
```
where *[path_to_mnt]* is a directory to be shared between the host and the docker. This is required when using ModelSim from the host system.
Finally, move all contents of */tmp_mnt* to */mnt* to make them available to ModelSim in the host system:
```
mv /tmp_mnt/* /mnt/
```
From there on, follow the instructions in */mnt/milesan-meta/README.md*.
