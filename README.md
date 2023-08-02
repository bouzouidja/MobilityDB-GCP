# Scaling moving object database on Google Kubernetes Engine
In this repository we define an API that allows scaling moving object database in Google Kubernetes Engine (GKE) within GCP. PostgreSQL server is used as an RDBMS accompanied with MobilityDB extension that support manipulation of moving object data efficiently. For more information about MobilityDB extension for PostgreSQL, you could view [here](https://github.com/MobilityDB) the implementation and the documention.
In addition Citus data extension for PostgreSQL is used in order to partitionning tables and distributing SQL queries over a group of PostgreSQL nodes efficiently. For more information about Citus extension, [here](https://github.com/citusdata/citus) you can find the entire implementation.    



# Get started
In this part, we will introduce the different steps needed in order to scaling moving object database in GCP by providing such a manual that describe the commands line in needed in each phase. We start first by creating our GKE cluster by allocating some GCP resources and then we deploy PostgreSQL server accomodated with MobilityDB and Citus extension, and then we proceed to initialize Citus cluster by setting up the connexions between the Citus nodes order to partitionning the big tables and distributing the partitions and the queries across several cluster's nodes. At the end we show the API commands needed to scaling-out or scaling-in Citus cluster in order to idealize the performance.  
## GKE cluster initialization
The first phase that need to be done, is the initialisation of the infrastructure that support our moving object database. GKE cluster is a product within the Google cloud platform included in the compute service.

- Create GKE cluster
```bash

gcloud container clusters create mobilitydb-cluster --zone europe-west1-c --node-pool mobilitydb-node-pool --machine-type e2-standard-4 --disk-type pd-balanced --num-nodes 4

## view clusters info
gcloud container clusters list --project YOUR_GCP_PROJECT_NAME

```
- install kubectl to manage GCP K8s cluster if it not found in my local machine 
```bash

sudo apt-get install google-cloud-sdk-gke-gcloud-auth-plugin

#kubectl version
gke-gcloud-auth-plugin --version

## update the kubectl env var
export USE_GKE_GCLOUD_AUTH_PLUGIN=True

source ~/.bashrc


```
- Interact with your cluster using Kubectl
```bash

#get the credential first in order to connect to you GKE 
gcloud container clusters get-credentials mobilitydb-cluster-1 --zone us-central1-c --project argon-system-263617

##view your GKE nodes
kubectl get node -o wide


```

## PostgreSQL deployment
After setting up the GKE cluster resources, we can proceed to deploying the PostgreSQL server with their extension needed, MobilityDB and Citus.



- Deploy on your GKE

```bash
kubectl create -f postgres-config.yaml
kubectl create -f postgres-secret.yaml
kubectl create -f postgres-deployment.yaml
```


- Delete Kubernetes ressources 
```bash
kubectl delete -f coordinator-deployment.yaml
```
- delete the cluster 

```bash

gcloud container clusters delete mobilitydb-cluster \
    --region europe-west1

```


- In order expose PostgreSQL as service from GKE, you may open a port 30001 for example
```bash


gcloud compute firewall-rules create mobilitydb-node-port   --project distributed-postgresql-82971  --allow tcp:30001

```


- Registry managment



```bash

# list images on container registry
gcloud container images list

## ls images on remote registry using gcrane
gcrane ls gcr.io/argon-system-263617

## copy images from 2 remote registry using gcrane
gcrane cp gcr.io/argon-system-263617/mobilitydb-cloud europe-west1-docker.pkg.dev/argon-system-263617/gcp-registry/mobilitydb-cloud

gcrane cp europe-west1-docker.pkg.dev/distributed-postgresql-82971/sidahmed-gcp-registry/mobilitydb-cloud
#view which registry i have access
cat ~/.docker/config.json

#tag an images
docker tag europe-west1-docker.pkg.dev/distributed-postgresql-82971/sidahmed-gcp-registry/mobilitydb-cloud/mobilitydb-cloud:latest


## push the tagged images to the registry
docker push europe-west1-docker.pkg.dev/distributed-postgresql-82971/sidahmed-gcp-registry/mobilitydb-cloud

# describe images on artifact registry
gcloud artifacts repositories describe gcp-registry --project=argon-system-263617 --location=europe-west1

### resize the clustr to stop all ressources

gcloud container clusters resize mobilitydb-cluster-1 --zone us-central1-c --node-pool mobilitydb-pool --num-nodes 0


kubectl get nodes --show-labels
# label the coordinator node 
kubectl label nodes gke-mobilitydb-cluste-mobilitydb-pool-fc867a69-1brb nodetype=worker

# view quota info for my region
https://console.cloud.google.com/iam-admin/quotas?usage=USED&project=argon-system-263617
gcloud compute regions describe us-central1

gcloud compute firewall-rules create test-node-port     --allow tcp:NODE_PORT
gcloud compute firewall-rules create mobilitydb-2-node-port     --allow tcp:30002

##
  metric: SSD_TOTAL_GB
  usage: 90.0
- limit: 100.0

gcloud compute project-info describe --project argon-system-263617

## copy container images remotely
gcrane cp GCR-LOCATION.gcr.io/PROJECT/IMAGE \
AR-LOCATION.pkg.dev/PROJECT/REPOSITORY/IMAGE

```


## Citus cluster initialization


```sql

## Add workers..

SELECT * from citus_add_node('$POD_IP', 5432);
SELECT create_distributed_table('edges', 'id');

SELECT citus_set_coordinator_host('10.0.1.7', 5432);
SELECT create_reference_table('trips');

## to remove local data form reference or distributed table
SELECT truncate_local_data_after_distributing_table($$public.trips$$)

## view linked workers
SELECT * from citus_get_active_worker_nodes();
## SHOW MORE DETAILS
SELECT * FROM pg_dist_node;


### Shards information 
SELECT * FROM citus_shards;


# Execute command on workers
SELECT run_command_on_workers($cmd$ SHOW work_mem; $cmd$);

# remove local data after distribution or referencing tables from disk 
SELECT truncate_local_data_after_distributing_table($$public.periods$$)
 
### update the pod ip in pg_dist_node table when the pod is created
select * from citus_update_node(123, 'new-address', 5432);
# or ..
select citus_update_node(nodeid, 'new-address', nodeport)
  from pg_dist_node
 where nodename = 'old-address';


```
- Rebalancing shards
```bash
psql -h citus-coordinator -U $POSTGRES_USER -d $POSTGRES_DB --command=\"SELECT citus_rebalance_start();\"


SELECT details FROM citus_rebalance_status();


## Querying the size of all distributed tables
SELECT table_name, table_size
  FROM citus_tables;


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

# GKE cluster management

- Create Kubernete cluster on GCP using gcloud command

```bash


# Create a project if no existing project
# Enable a billing plan and associated to the project
# Enable the GKE service on https://console.cloud.google.com/apis/enableflow?apiid=container.googleapis.com

# Authenticate to pulling up the credentials of your Google account in order to use the gcloud CLI 
gcloud auth login

```

- Pushing moblititydb-cloud image to the artifact registry in GCP  

We assume that an artifact registry is already created in GCP in a given region.
https://console.cloud.google.com/artifacts/docker.
After creating an artifact registry, you will get an ULR for your new registry for this format:LOCATION-docker.pkg.dev/PROJECT-ID/REPOSITORY/IMAGE:TAG
Where:


* LOCATION is the regional or multi-regional location of the repository where the image is stored, for example us-east1 or us.

* PROJECT-ID is your Google Cloud console project ID. If your project ID contains a colon (:), see Domain-scoped projects.

* REPOSITORY is the name of the repository where the image is stored.

* IMAGE is the image's name. It can be different than the image's local name.


- Pull mobilitydb-cloud locally from docker hub.
```bash

docker pull bouzouidja/mobilitydb-cloud:latest

```
- Tag mobilitydb-cloud with the URL of your new registry in GCP 


```bash
docker tag bouzouidja/mobilitydb-cloud LOCATION-docker.pkg.dev/PROJECT-ID/REPOSITORY/IMAGE:TAG

```

- Now we can push mobilitydb-cloud to the new registry


```bash

#First Authenticating to a repository
gcloud auth configure-docker LOCATION-docker.pkg.dev

docker push LOCATION-docker.pkg.dev/PROJECT-ID/REPOSITORY/IMAGE:TAG


```
For the full manual on how to push images on GCP artifact registry, use this doc
https://cloud.google.com/artifact-registry/docs/docker/pushing-and-pulling#cred-helper







```bash
#in a console:
# connect to your coordinator node 
# access postgres using kubectl
kubectl exec citus-coordinator-0 -i -t -- psql -U docker -d brussels-s1
psql -h 192.168.67.4 -U docker -p 30001 mobilitydb


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
osm2pgrouting -h 35.189.193.185  -U docker -W docker -p 30001 -f ../BerlinMod_Brussels/MobilityDB-BerlinMOD-develop/MobilityDB-BerlinMOD/BerlinMOD/brussels.osm --dbname brussels-s1 -c ../BerlinMod_Brussels/MobilityDB-BerlinMOD-develop/MobilityDB-BerlinMOD/BerlinMOD/mapconfig_brussels.xml

```


- Simulation
```bash


osm2pgsql -c -H 35.189.193.185  -U docker -W  -P 30001 -d brussels-s1 ../BerlinMod_Brussels/MobilityDB-BerlinMOD-develop/MobilityDB-BerlinMOD/BerlinMOD/brussels.osm
# loads all layers in the osm file, including the adminstrative regions
psql -h 35.189.193.185  -U docker -d brussels-s1 -p 30001 -f ../BerlinMod_Brussels/MobilityDB-BerlinMOD-develop/MobilityDB-BerlinMOD/BerlinMOD/brussels_preparedata.sql
# samples home and work nodes, transforms data to SRID 3857, does further data preparation
psql -h 35.189.193.185  -U docker -d brussels-s1  -p 30001 -f ../BerlinMod_Brussels/MobilityDB-BerlinMOD-develop/MobilityDB-BerlinMOD/BerlinMOD/berlinmod_datagenerator.sql
# adds the pgplsql functions of the simulation to the database


# or you can directely restore a pre-generated geo-spatial databases


```


- Running the generator

```bash

psql -h  35.189.193.185 -U docker -d brussels-s1 -p 30001 -c 'select berlinmod_generate(scaleFactor := 0.003)'
###dump your generated database

pg_dump -h 172.17.0.5  -U docker -p 5432 -d brussels-s1 -f Desktop/Thesis_Work/berlinmod_geo_1_backup.dump 
# calls the main pgplsql function to start the simulation


```

- Exploring the data generated>>> SQL queries

Before running the geo-spatial queries, we need first to distribute the data across the node using Citus queries




# Scaling Citus cluster

- Scaling pods 
```bash
kubectl scale statefulsets citus-workers --replicas=7
```

```bash
### Make sure that api-server service is installed without missing endpoint

kubectl get apiservices

# get the components file 
wget https://github.com/kubernetes-sigs/metrics-server/releases/download/v0.5.0/components.yaml

## edit the file and add the flag - --kubelet-insecure-tls
- --kubelet-insecure-tls
###
```

- Monitor the workload by watch command

```bash
kubectl get  hpa mobilitydb-cloud --watch

```
