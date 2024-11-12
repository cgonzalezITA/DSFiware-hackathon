# Apisix
- [Apisix](#apisix)
  - [Step01: _Deploy a basic version of a helloWorld chart_](#step01-deploy-a-basic-version-of-a-helloworld-chart)
  - [Step02: Deploy a functional version of apisix](#step02-deploy-a-functional-version-of-apisix)

[Apache APISIX](https://apisix.apache.org/) provides rich traffic management features like extension via plugins, Load Balancing, Dynamic Upstream, Canary Release, Circuit Breaking, Authentication, Observability, etc.


The following steps are focused in the deployment of the Helms Chart apisix to install an instance of this open source Apache API Gateway to help you manage the different components of the Fiware Data space. 

## Step01: _Deploy a basic version of a helloWorld chart_
This steps, using the components at the apisix Chart, deploys a basic version of a helloWorld chart (included inside apisix Helm Chart)
1. Decide the DNS to expose the consumer apisix proxy (Local or global DNS)
   eg. fiwaredsc-consumer.local, fiwaredsc-consumer.ita.es, ...
2. For Local DNS register them at the /etc/hosts (ubuntu) and/or C:\Windows\System32\drivers\etc\hosts (windows)
3. Create the TLS Certificate  
    a) Using Organization official certificates (issued by Certification authority companies such as Let’s encrypt, ZeroSSL, …) For every public TLS/SSL certificate, CAs must verify, at a minimum, the requestors' domain.e.g. Let’s encrypt.  
    b) Generate not trusted certificates just for testing:
    ```
    openssl req -x509 -nodes -days 365 -newkey rsa:2048 -keyout Helms/apisix/certs/tls-wildcard.key -out Helms/apisix/certs/tls-wildcard.crt -subj "/CN=*.local"
    ```
4. Create the TLS k8s secret generic based on the previously created certificate. Name it _wildcardlocal-tls_ and ensure the value files refers to this secret at the _utils.echo.ingress.tls.secretName_
  ```
  kubectl create secret tls wildcardlocal-tls -n apisix --key Helms/apisix/certs/tls-wildcard.key --cert Helms/apisix/certs/tls-wildcard.crt
  ```
  If the namespace does not exist yet, create it:
  ```
  kubectl create ns apisix
  ```
6. Customize the apisix values file  
For example, you can start enabling just the utils components activating the enabled flags for utils and deactivating it for the apisix component  
    ```
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
    ```
    hFileCommand apisix install
    # Will execute helm command: helm -n test install -f "./Helms/apisix/values.yaml" apisix "./Helms/apisix/"  --create-namespace
    ```
2. Test it. Does it work?
    ```
    curl https://fiwaredsc-consumer.local
    curl -k https://fiwaredsc-consumer.local
    ```

## Step02: Deploy a functional version of apisix  
NOTE to avoid refering to the namespace apisix at each command, the ENV VAR DEF_KTOOLS_NAMESPACE=apisix is set:
```
export DEF_KTOOLS_NAMESPACE=apisix
```

1. Modify the values to enable apisix and disable the util's ingress.
2. Deploy the changes
    ```
    hFileCommand apisix restart
    # Running CMD=[helm -n apisix install -f "./Helms/apisix/values.yaml" apisix "./Helms/apisix/"  --create-namespace]

    ```
3. After some seconds the deployments should be running
    ```
    $ kGet 
    ...
    #   Running command [kubectl get pod  -n apisix  ]
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
4. Test it. Does it work?
    ```
    curl -k https://fiwaredsc-consumer.local
    ```
