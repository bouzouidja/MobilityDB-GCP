#!/bin/bash
kubectl delete -f "./postgres-secret.yaml"
kubectl delete -f "./coordinator-deployment.yaml"
kubectl delete -f "./workers-deployment.yaml"
