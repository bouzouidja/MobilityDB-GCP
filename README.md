# MobilityDB-GCP
Scaling MobilityDB in Google Cloud Plateform

use this command to run psql externally from minikube cluster, the ip address is the ip of the service, the port is NodePort in yaml file  
psql -h 192.168.58.2 -U docker -p 30100 mobilitydb




# Configuration commands
use this command to get the ip of a running docker container  
docker inspect -f '{{range.NetworkSettings.Networks}}{{.IPAddress}}{{end}}' container_name_or_id


- start the minikube Kubernetes command on single node:


use this command to see the ip of the single node cluster
```bash


minikube profile list 
minikube profile mobilitydb-gcp
minikube start mobilitydb-gcp  ### start the cluster

####create K8scluster with multi node
minikube start --nodes 3 -p multinode-gcp
### stop minikube with it name
minikube  stop -p mobilitydb-gcp 
### delete a cluster with it name using -profile option
minikube delete -p multinode-demo 

### inspect ressources
kubectl get nodes -o wide
kubectl get pods -o wide

## create postgres instance

docker run -d -e POSTGRES_USER=postgres -e POSTGRES_PASSWORD=postgres -e POSTGRES_DB=postgres --name dimit dimitris007/mobilitydb:citus10
```

- TO delete Kubernetes ressources 
```bash
kubectl delete -f coordinator-deployment.yaml
```
- postgresql connection and psql client

```bash
minikube -p mobilitydb-gcp ip  ## this command show the ip of the host 
kubectl get service postgres-service -o jsonpath='{.spec.ports[0].nodePort}' ### this command give you the port or NodePort
psql -h 192.168.58.2 -U docker -p 30001 mobilitydb  # runu psql from extern 


###change docker image refgistry from local to minikube cluster 
eval $(minikube -p mobilitydb-gcp docker-env)
## pull images inside the minikube image registry
minikube -p mobilitydb-single-node ssh docker pull bouzouidja/mobilitydb-cloud:latest
```

- psql command for all postgresql server within the cluster (minikube-gcp)
```bash
psql -h 192.168.67.2 -U docker -p 30001 mobilitydb
psql -h 192.168.67.3 -U docker -p 30001 mobilitydb
psql -h 192.168.67.4 -U docker -p 30001 mobilitydb
```
psql -h 192.168.67.4 -U docker -p 30001 brussels SELECT * from citus_add_node('10.244.1.9', 5432);


- Debug and logs :

```bash
#Use this 3 command to debug pods error  
kubectl describe pod podname

kubectl logs podname –all-containers

kubectl get events --field-selector involvedObject.name=podname
### watch Horizontal Pod Autoscaling
kubectl get hpa citus-workers --watch

### see docker images within the minikube node
minikube -p mobilitydb-multi-node ssh docker images
### access inside the minikube machine (node)
minikube -p mobilitydb-single-node ssh


### access inside docker container within a pods 
kubectl exec -it pod_name bash

```



- Kubernetes cluster on multi-nodes


```bash

# deploy secret and configMap on the coordinator
minikube -p mobilitydb-multi-node kubectl -- create -f postgres-secret.yaml 
minikube -p mobilitydb-multi-node kubectl -- create -f postgres-config.yaml 


# Deploy mobilitydb-cloud storage, pods and service on the coordinator 

minikube -p mobilitydb-multi-node kubectl -- create -f coordinator-storage.yaml 

minikube -p mobilitydb-multi-node kubectl -- create -f coordinator-deployment.yaml 

## Deploy mobilitydb-cloud storage, pods and service on the workers


```




















############################ GCP##############################
- Create Kubernete cluster on GCP using gcloud command

```bash

# Create K8s cluster

gcloud container clusters create-auto mobilitydb-cluster \
    --region=europe-west1

## view clusters info
gcloud container clusters list

#install kubectl to manage GCP K8s cluster if it not found in my local machine  
sudo apt-get install google-cloud-sdk-gke-gcloud-auth-plugin

#kubectl version
gke-gcloud-auth-plugin --version

## update the kubectl env var
export USE_GKE_GCLOUD_AUTH_PLUGIN=True

source ~/.bashrc

#get the credential 
gcloud container clusters get-credentials mobilitydb-cluster     --region europe-west1

# create ConfigMap and secret 
```bash
kubectl create -f postgres-config.yaml
kubectl create -f postgres-secret.yaml




## delete the cluster 
gcloud container clusters delete mobilitydb-cluster \
    --region europe-west1

```




## create hello world deployment
kubectl create deployment hello-server \
    --image=us-docker.pkg.dev/google-samples/containers/gke/hello-app:1.0

#expose the hello world app 
kubectl expose deployment hello-server --type LoadBalancer --port 80 --target-port 8080

#view the app in the browser
http://EXTERNAL_IP_APP_SERVICE:EXPOSED_PORT

http://34.76.6.249:80

Hello, world!
Version: 1.0.0
Hostname: hello-server-7cc77d5467-q62td


## BerlinMOD experiments


run a docker MobilityDB Cloud using the develop version (MEOS) 1.1
```bash
docker run --name dist-mobilitydb -d -e POSTGRES_USER=docker -e POSTGRES_PASSWORD=postgres  bouzouidja/mobilitydb-cloud:latest 
```
To build a Dockerfile use:
```bash
docker build . -t bouzouidja/mobilitydb-gcp:latest
```


## Documentation 

In order to generate pdf file from xml document we need to use dblatex command

```bash
 dblatex -s texstyle.sty -T native -t pdf -o mobilitydb-berlinmod.pdf mobilitydb-berlinmod.xml
 ```




 # Experiments: single node use case:


```bash
#in a console:
createdb -h localhost -p 5432 -U dbowner brussels
# replace localhost with your database host, 5432 with your port,
# and dbowner with your database user
psql -h localhost -p 5432 -U dbowner -d brussels -c 'CREATE EXTENSION hstore'
# adds the hstore extension needed by osm2pgsql
psql -h localhost -p 5432 -U dbowner -d brussels -c 'CREATE EXTENSION MobilityDB CASCADE'
# adds the PostGIS and the MobilityDB extensions to the database
psql -h localhost -p 5432 -U dbowner -d brussels -c 'CREATE EXTENSION pgRouting'
# adds the pgRouting extension
```


We should have all the following extensions in order to run the experiments

![](/docs/prerequisite_extensions.png)

- Loading the Map of Brussels

```bash
# in a console, go to the generatorHome then:
osm2pgrouting -h 172.17.0.2  -U docker -W -f brussels.osm --dbname brussels \
-c mapconfig_brussels.xml
```


- Simulation
```bash


osm2pgsql -c -H 172.17.0.2  -U docker -W  -d brussels brussels.osm
# loads all layers in the osm file, including the adminstrative regions
psql -h 172.17.0.2  -U docker -d brussels -f ./BerlinMod_Brussels/MobilityDB-BerlinMOD/BerlinMOD/brussels_preparedata.sql
# samples home and work nodes, transforms data to SRID 3857, does further data preparation
psql -h 172.17.0.2  -U docker -d brussels -f ./BerlinMod_Brussels/MobilityDB-BerlinMOD/BerlinMOD/berlinmod_datagenerator.sql
# adds the pgplsql functions of the simulation to the database


# or you can directely restore a pre-generated geo-spatial databases


```


- Running the generator

```bash

psql -h 172.17.0.2  -U docker -d brussels -c 'select berlinmod_generate(scaleFactor := 0.005)'
# calls the main pgplsql function to start the simulation
```

- Exploring the data generated>>> SQL queries

Before running the geo-spatial queries, we need first to distribute the data across the node using Citus queries






SELECT * from citus_add_node('$POD_IP', 5432);
SELECT create_distributed_table('trips', 'tripid');

SELECT citus_set_coordinator_host('10.244.1.2', 5432);

## Add workers..


## view linked workers
SELECT * from citus_get_active_worker_nodes();
## SHOW MORE DETAILS
SELECT * FROM pg_dist_node



## Auto scaling pods

```bash
### Make sure that api-server service is installed without missing endpoint

kubectl get apiservices

# get the components file 
wget https://github.com/kubernetes-sigs/metrics-server/releases/download/v0.5.0/components.yaml

## edit the file and add the flag - --kubelet-insecure-tls
- --kubelet-insecure-tls
###
```




```sql

---Run the stress test 

do $$
begin
   for counter in 1..5 loop
    raise notice 'counter: %', counter;
   end loop;
end; $$
```
- Monitor the workload by watch command


```bash
kubectl get  hpa mobilitydb-cloud --watch

```



kubectl delete pod citus-workers-0
kubectl delete statefulset web --cascade=orphan
```





## Other possible solution

- YgabytyDB is a tool that manages Cloud native PostgreSQL application
https://docs.yugabyte.com/preview/explore/ysql-language-features/pg-extensions/

https://hub.docker.com/r/yugabytedb/yugabyte






## Auto scaling spatio-temporal reads and writes using Horizontal Pod AutoScaler:
- we need to autoscale on reads operations. The reads takes muchtime than the writes because the writes is routed by Citus extension..

### Tasks to do the next time
Main goals>>>
- Auto scaling the solution using K8s YAML configuration using metrics..
CPU utilisation, replicas... >>> Done
- AUtoscaling, try active database principle for rebalancing shard across the cluster
- Test the Kubernetes YAML configuration on GCP...
- GCP ressource initialization (GKE, K8s, nodes)...
- Meet Zimanyi..

Optional>>>
- add pg_stat_statements to shared preload library in coordinator
- See if it necessary to install osm and berlinMod generator within the docker container mobilitydb-cloud:latest
- Add PgBouncer into mobilitydb-cloud:latest image
- Add KEDA autoscaler see https://keda.sh/, Kubernetes Event Driven Autoscaling

