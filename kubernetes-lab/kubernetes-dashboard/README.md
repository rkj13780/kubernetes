# Kubernetes Dashboard Installation

Kubernetes Dashboard is a general purpose, web-based UI for Kubernetes clusters. It allows users to manage applications running in the cluster and troubleshoot them, as well as manage the cluster itself.

Installtion:

Method: 1

To access Dashboard directly (without kubectl proxy) valid certificates should be used to establish a secure HTTPS connection

Step 1 - Create certificate

openssl can manually generate certificates for your cluster.

    1. Generate a dashboard.key with 2048bit:

        mkdir ~/certs
        cd ~/certs/
        openssl genrsa -out dashboard.key 2048

    2. Generate a dashboard.crt using dashboard.key:

        openssl req -x509 -new -nodes -key dashboard.key -subj "/CN=${MASTER_IP}" -days 10000 -out dashboard.crt

    3. Generate a server.key with 2048bit:

        openssl genrsa -out server.key 2048

    4. Create a config file for generating a Certificate Signing Request (CSR). Be sure to substitute the values marked with angle brackets (e.g. <MASTER_IP>) with real values before saving this to a file (e.g. csr.conf). Note that the value for MASTER_CLUSTER_IP is the service cluster IP for the API server as described in previous subsection.

        wget https://raw.githubusercontent.com/narenchandrak/kubernetes/master/kubernetes-lab/kubernetes-dashboard/csr.conf

    5. Generate the certificate signing request based on the config file:

        openssl req -new -key server.key -out dashboard.csr -config csr.conf

    6. Generate the server certificate using the dashboard.key, dashboard.crt and dashboard.csr:

        openssl x509 -req -in dashboard.csr -CA dashboard.crt -CAkey dashboard.key -CAcreateserial -out dashboard.crt -days 10000 -extensions v3_ext -extfile csr.conf

    7. View the certificate:

        openssl x509  -noout -text -in ./dashboard.crt

Step 2 - Import CA:

    Custom certificates have to be stored in a secret named kubernetes-dashboard-certs in kube-system namespace. Assuming that you have dashboard.crt and dashboard.key files stored under $HOME/certs directory, you should create secret with contents of these files:

        kubectl create secret generic kubernetes-dashboard-certs --from-file=$HOME/certs -n kube-system

Step 3 - Deploy Heapster, Grafana & InfluxDB:

        kubectl create -f https://raw.githubusercontent.com/kubernetes/heapster/master/deploy/kube-config/influxdb/influxdb.yaml

        kubectl create -f https://raw.githubusercontent.com/kubernetes/heapster/master/deploy/kube-config/influxdb/grafana.yaml

        kubectl create -f https://raw.githubusercontent.com/kubernetes/heapster/master/deploy/kube-config/influxdb/heapster.yaml

        kubectl create -f https://raw.githubusercontent.com/kubernetes/heapster/master/deploy/kube-config/rbac/heapster-rbac.yaml

        Note: Wait for few minates to start starts.

Step 4 - Deploy Dashboard:

        kubectl apply -f https://raw.githubusercontent.com/kubernetes/dashboard/master/src/deploy/recommended/kubernetes-dashboard.yaml

        kubectl apply -f https://raw.githubusercontent.com/narenchandrak/kubernetes/master/kubernetes-lab/kubernetes-dashboard/dashboard-admin.yaml

Step 4 - Modify kubernetes dashboard service:

    kubectl -n kube-system get service kubernetes-dashboard

    kubectl -n kube-system edit service kubernetes-dashboard

    Note: Change value for spec.type from "ClusterIP" to "NodePort" . Then save the file (:wq)

Step 5 - Check port on which Dashboard was exposed:

    kubectl -n kube-system get service kubernetes-dashboard

Method: 2

Step 1 - Deploy Heapster, Grafana & InfluxDB

For our charts and graphs to show up in our dashboard, we'll need to deploy charting tools to enabled the kubernetes dashboard display them.

        kubectl create -f https://raw.githubusercontent.com/kubernetes/heapster/master/deploy/kube-config/influxdb/influxdb.yaml
        kubectl create -f https://raw.githubusercontent.com/kubernetes/heapster/master/deploy/kube-config/influxdb/grafana.yaml
        kubectl create -f https://raw.githubusercontent.com/kubernetes/heapster/master/deploy/kube-config/influxdb/heapster.yaml
        kubectl create -f https://raw.githubusercontent.com/kubernetes/heapster/master/deploy/kube-config/rbac/heapster-rbac.yaml

        Note: Wait for few minates to start starts.

Step 2 - Deploy Dashboard

Deploy the dashboard containers to your cluster.

    kubectl apply -f https://raw.githubusercontent.com/kubernetes/dashboard/master/src/deploy/recommended/kubernetes-dashboard.yaml

Step 3 - Create Admin User

    kubectl apply -f https://raw.githubusercontent.com/narenchandrak/kubernetes/master/kubernetes-lab/kubernetes-dashboard/dashboard-admin.yaml

Step 4 - Get Service Account Token and Login

    kubectl -n kube-system describe secret $(kubectl -n kube-system get secret | grep admin-user | awk '{print $1}')

Step 5 - Enabling the Proxy

    From the master server, execute the below command to run the kubernetes proxy command in the background.

        nohup kubectl proxy --address="<master-ip>" -p 443 --accept-hosts='^*$' &

Update:

    Once installed, the deployment is not automatically updated. In order to update it you need to delete the deployment's pods and wait for it to be recreated. After recreation, it should use the latest image.

    Delete all Dashboard pods (assuming that Dashboard is deployed in kube-system namespace):

        $ kubectl -n kube-system delete $(kubectl -n kube-system get pod -o name | grep dashboard)
