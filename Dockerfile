FROM node:8.15.0

# Install VS Code's deps. These are the only two it seems we need.
RUN apt-get update && apt-get install -y \
	libxkbfile-dev \
	libsecret-1-dev

# Ensure latest yarn.
RUN npm install -g yarn@1.13

WORKDIR /src
COPY . .

# In the future, we can use https://github.com/yarnpkg/rfcs/pull/53 to make yarn use the node_modules
# directly which should be fast as it is slow because it populates its own cache every time.
RUN yarn && yarn task build:server:binary

# We deploy with ubuntu so that devs have a familiar environment.

FROM nvidia/cuda:10.0-devel-ubuntu16.04
LABEL maintainer "NVIDIA CORPORATION <cudatools@nvidia.com>"

WORKDIR /root/project
COPY --from=0 /src/packages/server/cli-linux-x64 /usr/local/bin/code-server
EXPOSE 8443

ENV CUDNN_VERSION 7.5.0.56
LABEL com.nvidia.cudnn.version="${CUDNN_VERSION}"

RUN apt-get update && apt-get install -y --no-install-recommends \
            libcudnn7=$CUDNN_VERSION-1+cuda10.0 \
            libcudnn7-dev=$CUDNN_VERSION-1+cuda10.0 && \
    apt-mark hold libcudnn7 && \
    rm -rf /var/lib/apt/lists/*

RUN apt-get update && apt-get install -y \
	openssl \
	net-tools \
	git \
	locales
RUN locale-gen en_US.UTF-8
# We unfortunately cannot use update-locale because docker will not use the env variables
# configured in /etc/default/locale so we need to set it manually.
ENV LANG=en_US.UTF-8
ENTRYPOINT ["code-server"]
