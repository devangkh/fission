#!/bin/bash

set -euo pipefail

ROOT=$(dirname $0)/../.. 

fn=nodejs-hello-$(date +%N)

# Create a hello world function in nodejs, test it with an http trigger
echo "NewDeploy Backend: Test"
echo "Creating nodejs env"
fission env create --name nodejs --image fission/node-env --mincpu 20 --maxcpu 100 --minmemory 128 --maxmemory 256
trap "fission env delete --name nodejs" EXIT

echo "Creating function"
fission fn create --name $fn --env nodejs --code $ROOT/examples/nodejs/hello.js --minscale 2 --maxscale 4 --backend newdeploy --eagercreate
trap "fission fn delete --name $fn" EXIT

echo "Creating route"
fission route create --function $fn --url /$fn --method GET

echo "Waiting for router & newdeploy deployment creation"
sleep 5

echo "Doing an HTTP GET on the function's route"
response=$(curl http://$FISSION_ROUTER/$fn)

echo "Checking for valid response"
echo $response | grep -i hello

# crappy cleanup, improve this later
kubectl get httptrigger -o name | tail -1 | cut -f2 -d'/' | xargs kubectl delete httptrigger

echo "NewDeploy Backend: All done."