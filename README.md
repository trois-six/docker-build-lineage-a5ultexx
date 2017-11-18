docker-build-lineage-a5ultexx
===============

Image to build LineageOS rom for Galaxy A5 2015

Edit your settings (github email, github username, uid/gid to match your current uid/gid, MAKEFLAGS) in the Dockerfile and in the entrypoint.sh (ccache size, Xmx for jack)

## Build
    mkdir -p ~/src/lineage && cd ~/src
    git clone https://github.com/Trois-Six/docker-build-lineage-a5ultexx && cd docker-build-lineage-a5ultexx
    docker build -t docker-build-lineage-a5ultexx:latest .

## Run
    mkdir -p $(pwd)/../lineage/{android,ccache} && MAKEFLAGS=-j32 docker run -v $(pwd)/../lineage/android:/home/builder/android -v $(pwd)/..lineage/ccache:/home/builder/ccache --name lineage_a5ultexx_$(date "+%s") docker-build-lineage-a5ultexx:latest

## Cleanup old exited containers
    docker rm -v `docker ps -q -f status=exited`

## Cleanup old images
    docker rmi `docker images -q -f dangling=true`
