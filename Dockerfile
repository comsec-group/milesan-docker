# Copyright 2024 Tobias Kovats, Flavien Solt ETH Zurich.
# Licensed under the General Public License, Version 3.0, see LICENSE for details.
# SPDX-License-Identifier: GPL-3.0-only

FROM ubuntu:latest
ENV DEBIAN_FRONTEND=noninteractive
RUN apt-get update && apt-get install -y curl gnupg apt-utils && \
    apt-get install -y apt-transport-https curl gnupg git perl python3 make autoconf g++ flex bison ccache libgoogle-perftools-dev numactl perl-doc libfl2 libfl-dev zlib1g zlib1g-dev \
    autoconf automake autotools-dev libmpc-dev libmpfr-dev libgmp-dev gawk build-essential \
    bison flex texinfo gperf libtool patchutils bc zlib1g-dev git perl python3 python3-venv make g++ libfl2 \
    libfl-dev zlib1g zlib1g-dev git autoconf flex bison gtkwave clang \
    tcl-dev libreadline-dev jq libexpat-dev device-tree-compiler vim \
    software-properties-common default-jdk default-jre gengetopt patch diffstat texi2html subversion chrpath wget libgtk-3-dev gettext python3-pip python3-dev rsync libguestfs-tools expat \
    libexpat1-dev libusb-dev libncurses5-dev cmake help2man && \
    apt-get install apt-transport-https curl gnupg -yqq

RUN add-apt-repository -y ppa:openjdk-r/ppa && \
    apt-get install -y openjdk-8-jre && update-alternatives --install /usr/bin/java java /usr/lib/jvm/java-8-openjdk-amd64/jre/bin/java 111111 && \
    apt-get install -y openjdk-8-jdk && update-alternatives --install /usr/bin/javac javac /usr/lib/jvm/java-8-openjdk-amd64/bin/javac 111111 && \
    echo "deb https://repo.scala-sbt.org/scalasbt/debian all main" | tee /etc/apt/sources.list.d/sbt.list && \
    echo "deb https://repo.scala-sbt.org/scalasbt/debian /" | tee /etc/apt/sources.list.d/sbt_old.list && \
    curl -sL "https://keyserver.ubuntu.com/pks/lookup?op=get&search=0x2EE0EA64E40A89B84B2DF73499E82A75642AC823" | gpg --no-default-keyring --keyring gnupg-ring:/etc/apt/trusted.gpg.d/scalasbt-release.gpg --import && \
    chmod 644 /etc/apt/trusted.gpg.d/scalasbt-release.gpg && \
    apt-get update && apt-get install sbt libjsoncpp-dev

# install oh-my-bash
RUN bash -c "$(wget https://raw.githubusercontent.com/ohmybash/oh-my-bash/master/tools/install.sh -O -)"
RUN sed 's/OSH_THEME="font"/OSH_THEME="half-life"/g' ~/.bashrc

# Some environment variables
ENV HOME=/root
ENV TMP_MNT=/tmp_mnt
ENV LOCAL_MNT=$TMP_MNT
ENV PREFIX_MILESAN=$HOME/prefix-milesan
ENV CARGO_HOME=$PREFIX_MILESAN/.cargo
ENV RUSTUP_HOME=$PREFIX_MILESAN/.rustup
ENV RISCV=$PREFIX_MILESAN/riscv
ENV MILESAN_DESIGNS=$TMP_MNT/milesan-designs

ENV RUSTEXEC=$CARGO_HOME/bin/rustc
ENV RUSTUPEXEC=$CARGO_HOME/bin/rustup
ENV CARGOEXEC=$CARGO_HOME/bin/cargo
ENV PATH=$PATH:$PREFIX_MILESAN/bin
ENV PATH=$PATH:$RISCV/bin
# Install RISC-V toolchain
RUN apt-get install -y autoconf automake autotools-dev curl python3 libmpc-dev libmpfr-dev libgmp-dev gawk build-essential bison flex texinfo gperf libtool patchutils bc zlib1g-dev libexpat-dev ninja-build
RUN git clone https://github.com/riscv/riscv-gnu-toolchain
RUN cd riscv-gnu-toolchain && git checkout 2023.06.09 && ./configure --prefix=$RISCV --with-arch=rv32gc --with-abi=ilp32d --enable-multilib && make -j 200

# Install spike
RUN git clone https://github.com/riscv-software-src/riscv-isa-sim.git
RUN cd riscv-isa-sim && mkdir build && cd build && ../configure --prefix=$RISCV && make -j 200 && make install

RUN git clone https://github.com/milesan-artifacts/milesan-yosys.git $TMP_MNT/milesan-yosys --recursive
RUN cd $TMP_MNT/milesan-yosys && git submodule update --init && make -j 200 && make install

# Install Rust
RUN curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y

# Install Morty
RUN $CARGOEXEC install --force morty --root $PREFIX_MILESAN

# Install Bender
RUN $CARGOEXEC install --force bender --root $PREFIX_MILESAN

# Install fusesoc
RUN pip3 install fusesoc --break-system-packages --no-deps --force-reinstall

# Install stack
RUN curl -sSL https://get.haskellstack.org/ | sh

# Install sv2v
RUN git clone https://github.com/zachjs/sv2v.git && cd sv2v && git checkout v0.0.11 && make -j 200 && mkdir -p $PREFIX_MILESAN/bin/ && cp bin/sv2v $PREFIX_MILESAN/bin

# Install some Python dependencies
RUN pip3 install tqdm --break-system-packages


# Install miniconda
RUN mkdir -p miniconda && wget https://repo.anaconda.com/miniconda/Miniconda3-latest-Linux-x86_64.sh -O miniconda/miniconda.sh \
		&& cd miniconda/ && bash miniconda.sh -u -b -p $PREFIX_MILESAN/miniconda \
        && $PREFIX_MILESAN/miniconda/bin/conda tos accept --override-channels --channel https://repo.anaconda.com/pkgs/main \
        && $PREFIX_MILESAN/miniconda/bin/conda tos accept --override-channels --channel https://repo.anaconda.com/pkgs/r \
		&& $PREFIX_MILESAN/miniconda/bin/conda update -y -n base -c defaults conda \
		&& $PREFIX_MILESAN/miniconda/bin/conda config --add channels conda-forge \
		&& $PREFIX_MILESAN/miniconda/bin/conda config --set channel_priority strict
ENV PATH=$PREFIX_MILESAN/miniconda/bin:$PATH

# Install Verilator
RUN git clone https://github.com/verilator/verilator && cd verilator && git checkout 77fc771ed00ab699d549efb9fac99eb5a4b22254 && autoconf && ./configure CXXFLAGS="-std=c++14" && make -j 200 && make install


##
# Design repositories
##

RUN echo "Cloning the repositories!"
RUN mkdir -p $MILESAN_DESIGNS
RUN cd $MILESAN_DESIGNS && git clone  https://github.com/milesan-artifacts//milesan-chipyard.git
RUN cd $MILESAN_DESIGNS/milesan-chipyard && MILESAN_JOBS=250 scripts/init-submodules-no-riscv-tools.sh -f
COPY config-mixins.scala $MILESAN_DESIGNS/milesan-chipyard/generators/boom/src/main/scala/common

RUN cd $MILESAN_DESIGNS && git clone https://github.com/milesan-artifacts/milesan-pt-chipyard.git
RUN cd $MILESAN_DESIGNS/milesan-pt-chipyard && MILESAN_JOBS=250 scripts/init-submodules-no-riscv-tools.sh -f
# COPY config-mixins.scala $MILESAN_DESIGNS/phantomtrails-chipyard/generators/boom/src/main/scala/common


RUN cd $MILESAN_DESIGNS && git clone https://github.com/milesan-artifacts/milesan-cva6.git --recursive
RUN cd $MILESAN_DESIGNS && git clone https://github.com/milesan-artifacts/milesan-kronos.git --recursive
RUN cd $MILESAN_DESIGNS && git clone https://github.com/milesan-artifacts/milesan-openc910.git --recursive

RUN cd $TMP_MNT &&  git clone https://github.com/comsec-group/cellift-meta.git
RUN echo "Cloning meta"
RUN cd $TMP_MNT && git clone  https://github.com/milesan-artifacts/milesan-meta.git
RUN ln -s /usr/bin/python3 /usr/bin/python
RUN python -m venv $PREFIX_MILESAN/python-venv
ENV PATH=$PREFIX_MILESAN/python-venv/bin:$PATH
RUN cd $TMP_MNT/milesan-meta && cat requirements.txt | xargs -n 1 pip3 install || true

RUN pip install setuptools

# Install makeelf in the milesan python-venv
RUN git clone https://github.com/flaviens/makeelf && cd makeelf && git checkout finercontrol && python setup.py install

# copy cached results
RUN mkdir -p $TMP_MNT/milesan-data
COPY trans-ttes.pickle $TMP_MNT/milesan-data/
COPY ct-ttes.pickle $TMP_MNT/milesan-data/
COPY perf.pickle $TMP_MNT/milesan-data/

# # make run_* will naturally fail since no SIMLEN etc. are provided.
RUN bash -c "source /$TMP_MNT/milesan-meta/env.sh && cd $MILESAN_DESIGNS/milesan-cva6/milesan && rm -f run*.core && make run_vanilla_notrace"|| true
RUN bash -c "source /$TMP_MNT/milesan-meta/env.sh && cd $MILESAN_DESIGNS/milesan-cva6/milesan && rm -f run*.core && make run_drfuzz_mem_notrace" || true
RUN bash -c "source /$TMP_MNT/milesan-meta/env.sh && cd $MILESAN_DESIGNS/milesan-cva6/milesan && rm -f run*.core && make run_drfuzz_mem_trace" || true

# RUN conda install -c conda-forge conda-lock

RUN bash -c "source /$TMP_MNT/milesan-meta/env.sh && cd $MILESAN_DESIGNS/milesan-chipyard/milesan-rocket && rm -f run*.core && make run_vanilla_notrace" || true
RUN bash -c "source /$TMP_MNT/milesan-meta/env.sh && cd $MILESAN_DESIGNS/milesan-chipyard/milesan-rocket && rm -f run*.core && make run_drfuzz_mem_notrace" || true
RUN bash -c "source /$TMP_MNT/milesan-meta/env.sh && cd $MILESAN_DESIGNS/milesan-chipyard/milesan-rocket && rm -f run*.core && make run_drfuzz_mem_trace" || true

RUN bash -c "source /$TMP_MNT/milesan-meta/env.sh && cd $MILESAN_DESIGNS/milesan-chipyard/milesan-boom && rm -f run*.core && make run_vanilla_notrace" || true
RUN bash -c "source /$TMP_MNT/milesan-meta/env.sh && cd $MILESAN_DESIGNS/milesan-chipyard/milesan-boom && rm -f run*.core && make run_drfuzz_mem_notrace" || true
RUN bash -c "source /$TMP_MNT/milesan-meta/env.sh && cd $MILESAN_DESIGNS/milesan-chipyard/milesan-boom && rm -f run*.core && make run_drfuzz_mem_trace" || true

RUN bash -c "source /$TMP_MNT/milesan-meta/env.sh && cd $MILESAN_DESIGNS/phantomtrails-chipyard/milesan-boom && rm -f run*.core && make run_vanilla_notrace" || true
RUN bash -c "source /$TMP_MNT/milesan-meta/env.sh && cd $MILESAN_DESIGNS/phantomtrails-chipyard/milesan-boom && rm -f run*.core && make run_drfuzz_mem_notrace" || true
RUN bash -c "source /$TMP_MNT/milesan-meta/env.sh && cd $MILESAN_DESIGNS/phantomtrails-chipyard/milesan-boom && rm -f run*.core && make run_drfuzz_mem_trace" || true

RUN bash -c "source /$TMP_MNT/milesan-meta/env.sh && cd $MILESAN_DESIGNS/milesan-kronos/milesan && rm -f run*.core && make run_vanilla_notrace" || true
RUN bash -c "source /$TMP_MNT/milesan-meta/env.sh && cd $MILESAN_DESIGNS/milesan-kronos/milesan && rm -f run*.core && make run_drfuzz_mem_notrace" || true
RUN bash -c "source /$TMP_MNT/milesan-meta/env.sh && cd $MILESAN_DESIGNS/milesan-kronos/milesan && rm -f run*.core && make run_drfuzz_mem_trace" || true

RUN bash -c "source /$TMP_MNT/milesan-meta/env.sh && cd $MILESAN_DESIGNS/milesan-openc910/milesan && rm -f run*.core && make run_vanilla_notrace" || true
RUN bash -c "source /$TMP_MNT/milesan-meta/env.sh && cd $MILESAN_DESIGNS/milesan-openc910/milesan && rm -f run*.core && make run_drfuzz_mem_notrace" || true
RUN bash -c "source /$TMP_MNT/milesan-meta/env.sh && cd $MILESAN_DESIGNS/milesan-openc910/milesan && rm -f run*.core && make run_drfuzz_mem_trace" || true
