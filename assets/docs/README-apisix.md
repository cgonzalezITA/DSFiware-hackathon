# Apisix
- [Apisix](#apisix)
  - [step01: _Deploy a basic version of a helloWorld chart_](#step01-deploy-a-basic-version-of-a-helloworld-chart)

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
