# MileSan Docker
## Docker for *MileSan: Detecting Exploitable Microarchitectural Leakage via Differential Hardware-Software Taint Tracking, CCS'25*
## Overview
Welcome to MileSan!
This repository helps you with getting started with [MileSan](https://comsec.ethz.ch/research/hardware-design-security/milesan-detecting-exploitable-microarchitectural-leakage-via-differential-hardware-software-taint-tracking/), reproduce our results and further extend our codebase for your own research.
The easiest way to use MileSan is via the docker image.
Below we provide instructions to use our stock docker image, or build one from scratch.
## Using the existing docker image
You can pull the docker image using
```
docker pull docker.io/ethcomsec/milesan-artifacts
```
and start it with 
```
docker run -it docker.io/ethcomsec/milesan-artifacts
```
The docker comes with most utilities precompiled.
If you would rather create your own image, or make changes to it, you can alternatively build it from scratch.
## Building the docker image
### Using Questasim
To use Questasim, set QUESTASIM in **build.sh** accordingly.
```
QUESTASIM=[path-to-your-questasim]
```
The Dockerfile then copies the binary into the image.
### Building from scratch
Build the image by running
```
./build.sh
```
This will gather all required sources, build the toolchain and setup the environment.
## Usage
Start the container with
```
./start.sh
```
and follow the instructions in [milesan-meta/README.md](https://github.com/milesan-artifacts/milesan-meta).