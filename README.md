# ick-deployment
Kubernetes deployment of the InfluxDB, Chronograf, and Kapacitor stack.

[InfluxDB](https://github.com/influxdata/influxdb) is an open source time series database. It's useful for recording metrics, events, and performing analytics.

[Chronograf](https://github.com/influxdata/chronograf) is an open-source web application written in Go and React.js that provides the tools to visualize your monitoring data and easily create alerting and automation rules.

[Kapacitor](https://github.com/influxdata/kapacitor) is an open-source framework written in Go for processing, monitoring, and alerting on time series data.

Create a cluster on GKE and make sure your `kubectl` client is connected to the right context:
```
kubectl config current-context
```

Deploy Tiller, the server portion of Helm (if not already deployed)

You can do that on the `kube-system` namespace, and create a service account with cluster-admin role, but see also [Helm and RBAC](https://docs.helm.sh/using_helm/#role-based-access-control) for more secure options.
```
kubectl create -f kubernetes/rbac-config.yaml
helm init --service-account tiller
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

Deploy Kapacitor
```
helm install stable/kapacitor -f kapacitor-values.yaml --name kapacitor
```

Create DNS records on AWS Route53. They will point to the ingress controller IP address, and will be routed to the corresponding service in the cluster based on the host name.

```
  influxdb-demo.lsst.codes --|                      |-> influxdb-influxdb:8086
                             | <LoadBalancer Ingress IP address> |  
chronograf-demo.lsst.codes --|                      |-> chronograf-chronograf:8888
```

Get the LoadBalancer Ingress IP address from `kubectl describe service nginx-ingress-controller`, and then use the following to create the DNS records:
```
cd terraform
make
source create_dns_record.sh influxdb demo <LoadBalancer Ingress>
source create_dns_record.sh chronograf demo <LoadBalancer Ingress>
cd ..
```

NOTE: this will produce hostnames like above, make sure the `ingress.hostname` is set accordingly in the helm chart for InfluxDB and Chronograf.

Finally create the TLS certs secret. This requires the wildcard certs made by SQuaRE, and shared through the `lsst-certs.git` repo.
```
make tls-certs
```

You should be able to connect to the UI at `https://chronograf-demo.lsst.codes`

## Configuring GitHub authentication

Chronograf supports using [GitHub OAuth 2.0 authentication](https://docs.influxdata.com/chronograf/v1.7/administration/managing-security/#configuring-github-authentication)

Set the corresponding values for `Token Secret`, `Client ID`, and `Client Secret` in `chronograf-values.yaml`.

By default, access is restricted to the following github orgs:

```
gh_orgs: "lsst-sqre,lsst-dm,lsst"
```

## Configuring Slack integration for Alerts

1. On the Chronograf configuration, add a new Kapacitor connection
2. Set the Kapacitor URL for this deployment: http://kapacitor-kapacitor.default:9092

3. Configure an alert endpoint for Slack
  - Create a new Slack App https://api.slack.com/apps/new
  - Enable Incoming Webhooks and set the Slack webhook URL and the Slack channel to the alert endpoint configuration

## Monitoring InfluxDB load (optional)

The Telegraf InfluxDB Input Plugin populates the `influxdb_*` measurements with several metrics that can be used to monitor the InfluxDB load.

Deploy Telegraf
```
helm install stable/telegraf -f telegraf-values.yaml --name telegraf
```

Import the `dashboards/influxdb_load.json` dashboard using the Chronograf UI.s
