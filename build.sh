#!/bin/bash

image=7a6163/geminabox
geminabox_version=1.4.1

docker build -t $image:$geminabox_version . --no-cache
docker tag $image:$geminabox_version $image:latest
