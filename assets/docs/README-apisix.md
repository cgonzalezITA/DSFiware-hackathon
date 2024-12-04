# Apisix
- [Apisix](#apisix)
  - [step01: _Deploy a basic version of a helloWorld chart_](#step01-deploy-a-basic-version-of-a-helloworld-chart)
  - [step02: Deploy a functional version of apisix](#step02-deploy-a-functional-version-of-apisix)
  - [step03: Deploy a new route via the Apisix.yaml file](#step03-deploy-a-new-route-via-the-apisixyaml-file)

[Apache APISIX](https://apisix.apache.org/) provides rich traffic management features like extension via plugins, Load Balancing, Dynamic Upstream, Canary Release, Circuit Breaking, Authentication, Observability, etc.


The following steps are focused in the deployment of the Helm Chart of Apisix to install an instance of this open source Apache API Gateway. At this HOL, it will be used by all the  Fiware Data space parties. 

## step01: _Deploy a basic version of a helloWorld chart_
```shell
# To show the structure of the github after the completion of this step
git checkout phase01.step01
kubectl create namespace apisix
```
This step uses the components at the apisix Chart, deploys a basic version of a helloWorld chart (included inside apisix Helm Chart)
1. Decide the DNS to expose the consumer apisix proxy (Local or global DNS)
   eg. fiwaredsc-consumer.local, fiwaredsc-consumer.ita.es, ...
2. For Local DNS register them as root at the '/etc/hosts' file (ubuntu) and/or 'C:\Windows\System32\drivers\etc\hosts' file (windows)
3. Create the TLS Certificate  
    a) For local DNSs, generating not trusted certificates just for testing:
    ```shell
    mkdir -p Helms/apisix/.certs
    openssl req -x509 -nodes -days 365 -newkey rsa:2048 -keyout Helms/apisix/.certs/tls-wildcard.key -out Helms/apisix/.certs/tls-wildcard.crt -subj "/CN=*.local"
    ```
    b) For global DNS, using Organization official certificates (issued by Certification authority companies such as Let’s encrypt, ZeroSSL, …) For every public TLS/SSL certificate, CAs must verify, at a minimum, the requestors' domain.e.g. Let’s encrypt.  
4. Create the TLS k8s secret generic based on the previously created certificate. Name it _wildcardlocal-tls_ and ensure the value files refers to this secret at the _utils.echo.ingress.tls.secretName_
  ```shell
  kubectl create secret tls wildcardlocal-tls -n apisix --key Helms/apisix/.certs/tls-wildcard.key --cert Helms/apisix/.certs/tls-wildcard.crt
  ```

6. Customize the [Apisix values file](../../Helms/apisix/values.yaml)  
For example, you can start enabling just the utils components activating the enabled flags for utils and deactivating it for the Apisix component:  
    ```yaml
    utils:
      enabled: true
      echo:
        enabled: true
        ingress: 
          enabled: true
    ...
    apisix:
      enabled: false
    ```
1. Deploy the helm
    ```shell
    hFileCommand apisix install -b
    # Will execute helm command: helm -n apisix install -f "./Helms/apisix/values.yaml" apisix "./Helms/apisix/"  --create-namespace
    ```
2. Test it. Does it work?
    ```shell
    curl https://fiwaredsc-consumer.local # It should fail
    curl -k https://fiwaredsc-consumer.local # It should work
      Hostname: echo-767d576b65-t84j4
      Pod Information:
      node name:      v23040
      pod name:       echo-767d576b65-t84j4
      ...
    ```
At this stage, we know that we have a kubernetes cluster with the ingress working properly and the helm tool doing a great job.  

```shell
# To show the structure of the github after the completion of the next step
git checkout phase01.step02
```
## step02: Deploy a functional version of apisix  
```shell
# To show the structure of the github after the completion of this step
git checkout phase01.step02
# NOTE to avoid refering to the namespace apisix at each command, the ENV VAR DEF_KTOOLS_NAMESPACE=apisix is set:
export DEF_KTOOLS_NAMESPACE=apisix
```
At this step, we will setup the apisix to serve as the official gateway of the HOL in which the different routes that have to be exposed on the internet will be registered. At this stage statically, but later dinamically.

1. Modify the values file (Helms/apisix/values.yaml) to enable apisix and disable the util's ingress.
2. Deploy the changes
    ```shell
    hFileCommand apisix restart
    # Running CMD=[helm -n apisix install -f "./Helms/apisix/values.yaml" apisix "./Helms/apisix/"  --create-namespace]
    ```
3. After some seconds the deployments should be running
    ```shell
    kGet 
    #   Running command [kubectl get pod  -n apisix]
    ---
    NAME                                         READY   STATUS    RESTARTS   AGE
    apisix-control-plane-7ffd9fdc4c-2jpw5        1/1     Running   0          5h23m
    apisix-dashboard-78d68bf7c5-cmb28            1/1     Running   0          5h23m
    apisix-data-plane-8488664577-4t7lg           1/1     Running   0          5h23m
    apisix-etcd-0                                1/1     Running   0          5h23m
    apisix-ingress-controller-5b8f85878d-vpggm   1/1     Running   0          5h23m
    echo-588c888c78-r2d7d                        1/1     Running   0          5h23m
    netutils-65cd7b88b8-fwn5h                    1/1     Running   0          5h23m
    ```
4. Test it. Does it work? It should
    ```shell
    curl -k https://fiwaredsc-consumer.local
    ```
The changes that introduce the use of the Apisix in order to define new routes are two:
1. The ingress section of the data plane at the apisix values file contains the ingress configuration: DNSs, TlSs, ...  
For this initial use, just one DNS and one TLS secret are required:
    ```yaml
    apisix:
      ...
      ingress:
        enabled: true
        hostname: fiwaredsc-consumer.local
        tls: true
        extraTls:
          - hosts: [fiwaredsc-consumer.local]
            secretName: wildcard_local-tls
      ...
    ```

2. The route `https://fiwaredsc-consumer.local` has been defined at the [apisix-routes.yaml file](../../Helms/apisix/apisix-routes.yaml).  
This file is used to statically specify the routes the Apisix gateway will manage.
```shell
cat Helms/apisix/apisix-routes.yaml
  routes:
  - 
    uri: /*
    host: fiwaredsc-consumer.local
    methods: 
      - GET    
    upstream:
      type: roundrobin
      nodes:
        echo-svc:8080: 1
  ...
```

```shell
# To show the structure of the github after the completion of the next step
git checkout phase01.step03
```
## step03: Deploy a new route via the Apisix.yaml file
```shell
# To show the structure of the github after the completion of this step
git checkout phase01.step03
# NOTE to avoid refering to the namespace apisix at each command, the ENV VAR DEF_KTOOLS_NAMESPACE=apisix is set:
export DEF_KTOOLS_NAMESPACE=apisix
```
As you have seen, there is a dashboard component deployed, but just one DNS managed by the Apisix ingress. This step will modify the [apisix-routes.yaml file](../../Helms/apisix/apisix-routes.yaml) to include a new route to expose the dashboard to be consumed via browser.
1. Decide the DNS to expose the Apisi dashboard (Local or global DNS)
eg. fiwaredsc-api6dashboard.local ...
1. For Local DNS register at the /etc/hosts (ubuntu) and/or C:\Windows\System32\drivers\etc\hosts (windows)
2. Modify the apisix values file to manage the new DNS and the TLS certificate:
    ```yaml
    apisix:
      ...
      ingress:
        enabled: true
        hostname: fiwaredsc-consumer.local
        tls: true
        extraHosts:
          - name: fiwaredsc-api6dashboard.local
            path: /
        extraTls:
          - hosts: [fiwaredsc-consumer.local, fiwaredsc-api6dashboard.local]
            secretName: wildcard_local-tls
      ...
    ```
3. Modify the [apisix-routes.yaml file](../../Helms/apisix/apisix-routes.yaml) to add the route for the Apisi dashboard:
      ```yaml
      routes:
      - 
        uri: /*
        host: fiwaredsc-api6dashboard.local
        methods: 
          - GET    
          - POST
          - PUT
          - HEAD
          - CONNECT
          - OPTIONS
          - PATCH
          - DELETE
        upstream:
          type: roundrobin
          nodes:
            apisix-dashboard:80: 1
      #END
      ```
4. Redeploy the helm chart:
    ```shell
    hFileCommand api upgrade
    # Running CMD=[helm -n apisix upgrade -f "./Helms/apisix/./values.yaml" apisix "./Helms/apisix/./"  --create-namespace]
    Release "apisix" has been upgraded. Happy Helming!
    ```
5. Test it. It should work.
    ```shell
    curl -k https://fiwaredsc-api6dashboard.local
    ```
    <p style="text-align:center;font-style:italic;font-size: 75%"><img src="./../images/apisix-dashboard.PNG"><br/>
    APISIX Dashboard</p>
6. To login at a browser, you need to retrieve the password to login in.  
If you visit the values file, the secret and the key used to store the dashboard user's password are defined:
    ```yaml
    apisix:
      dashboard:
        ...
        existingSecret: apisix-dashboard-secrets
        existingSecretPasswordKey: apisix-dashboard-secret
        ...
    ```
    So, use kubectl command to retrieve the password:  
    ```shell
    kSecret-show dashboard-secrets -f apisix-dashboard-secret -v
    Running CMD=[kubectl get -n apisix secrets apisix-dashboard-secrets -o jsonpath='{.data.apisix-dashboard-secret}' | base64 -d]
    ```
    <p style="text-align:center;font-style:italic;font-size: 75%"><img src="./../images/apisix-dashboard-routes.png"><br/>
    APISIX Routes</p>

    You may notice that none of the routes defined at the apisix.yaml file appear here. This is because the dashboard displays routes created via the Admin API because it directly interacts with APISIX's etcd storage. When you load configuration from a YAML file (the [apisix-routes.yaml file](../../Helms/apisix/apisix-routes.yaml)), APISIX typically treats it as static configuration, so it doesn’t get recorded at the etcd in a way that the dashboard can view.  

```shell
# To show the structure of the github after the completion of the next step
git checkout phase01.step04
```
