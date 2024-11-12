# Apisix
- [Apisix](#apisix)
  - [Step01: _Deploy a basic version of a helloWorld chart_](#step01-deploy-a-basic-version-of-a-helloworld-chart)

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
