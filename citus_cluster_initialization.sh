#!/bin/bash
kubectl create -f "./postgres-secret.yaml"
kubectl create -f "./coordinator-deployment.yaml"
kubectl create -f "./workers-deployment.yaml"
