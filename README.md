# ick-deployment
Kubernetes deployment of the InfluxDB, Chronograf and Kapacitor stack.

[InfluxDB](https://github.com/influxdata/influxdb) is an open source time series database. It's useful for recording metrics, events, and performing analytics.

[Chronograf](https://github.com/influxdata/chronograf) is an open-source web application written in Go and React.js that provides the tools to visualize your monitoring data and easily create alerting and automation rules.

[Kapacitor](https://github.com/influxdata/kapacitor) is an open-source framework written in Go for processing, monitoring, and alerting on time series data.

Create a cluster on GKE, using your preferred method. Make sure your `kubectl` client is connected to that cluster, and returns the expected context:
```
kubectl config current-context
```

Deploy Tiller, the server portion of Helm

You can do that on the `kube-system` namespace, and create a service account with cluster-admin role, but see [Helm and RBAC](https://docs.helm.sh/using_helm/#role-based-access-control) for other options.
```
kubectl create -f kubernetes/rbac-config.yaml
helm init --service-account tiller
```

Create a specific namespace for the ick-deployment and modify the current context to use it by default:
```
kubectl create namespace demo
kubectl config set-context $(kubectl config current-context) --namespace=demo
```

Deploy the nginx ingress controller
```
helm install stable/nginx-ingress --name nginx-ingress
```

Deploy InfluxDB
```
helm install stable/influxdb -f influxdb-values.yaml --name influxdb
```

Deploy Chronograf
```
helm install stable/chronograf -f chronograf-values.yaml --name chronograf
```

Create DNS records on AWS Route53. They will point to the ingress controller IP address, and will be routed to the corresponding service in the cluster based on the host name.

```
  influxdb-demo.lsst.codes --|                      |-> influxdb-influxdb:8086
                             | <Ingress IP address> |  
chronograf-demo.lsst.codes --|                      |-> chronograf-chronograf:8888
```

Get the ingress IP address using `kubectl get services` or directly:

```
INGRESS_IP=$(kubectl get ingress -o jsonpath --template='{.items[0].status.loadBalancer.ingress[0].ip}')
```
and then use this script to create the DNS records:

```
cd terraform
make
source create_dns_record.sh influxdb demo $INGRESS_IP
source create_dns_record.sh chronograf demo $INGRESS_IP
cd ..
```

Finally create the TLS certs secret. This requires the wildcard certs made by SQuaRE are sahred through the `lsst-certs.git` repo.

```
make tls-certs
```

You should be able to connect to the UI at `https://chronograf-demo.lsst.codes`
