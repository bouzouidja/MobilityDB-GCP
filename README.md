# MobilityDB-GCP
Scaling MobilityDB in Google Cloud Plateform

use this command to run psql externally from minikube cluster, the ip address is the ip of the service, the port is NodePort in yaml file  
psql -h 192.168.58.2 -U docker -p 30100 mobilitydb


use this command to see the ip of the cluster
minikube profile list 