# Provider's infrastructure
- [Provider's infrastructure](#providers-infrastructure)
  - [step04.1- _Deployment of the common components_](#step041--deployment-of-the-common-components)
  - [step04.2- _Deployment of the authentication components_](#step042--deployment-of-the-authentication-components)
    - [Verification of the deployment so far](#verification-of-the-deployment-so-far)
  - [step04.3- _Deployment of the authorization components_](#step043--deployment-of-the-authorization-components)
  - [Step 4.4- _Deployment of the service components_](#step-44--deployment-of-the-service-components)
  - [Step 4.5-Addition of the service routes to the Apisix without security](#step-45-addition-of-the-service-routes-to-the-apisix-without-security)
  - [Bottom line](#bottom-line)

    
The objective of this phase is to deploy the following infrastructure.
<p style="text-align:center;font-style:italic;font-size: 75%"><img src="./../images/provider-components.png"><br/>
    Provider components</p>

Any organization willing to market their data and or services in a dataspace will require such infrastructure to manage:
- **The authentication phase**: Its components are represented by the yellow blocks at the *Provider components diagram*.  
  They analyze that any request made to the provider's services are made by a known and verified participant.
- **The authorization phase**: Its components are represented by the green blocks at the *Provider components diagram*.  
  They analyze that any request made to their services are made by a participant entitled to perform the requested action.
- **The access to the data and or services offered**. These components are represented by the purple blocks at the *Provider components diagram*.  
  This walkthrough shows the deployment of a [Context Data broker Scorpio](https://scorpio.readthedocs.io/en/latest/) to provide NGSI-LD data access.
    
To split the deployment of the provider's components, this phase has been split into 4 interrelated Helm charts:
- A **_common helm chart_** with the components used by the other charts. e.g. the _did generator_ (white components of the diagram).
- The **_authentication helm chart_** (yellow components of the diagram)
- The **_authorization helm chart_** (green components of the diagram)
- The **_services helm chart_** (purple components of the diagram)
- 
## step04.1- _Deployment of the common components_
This Helm chart contains two value files:
- values-did.key.yaml: Values to generate a did:key identifier.
- values-did.web.yaml: Values to generate a did:web identifier.

This guideline will use the `values-did.key.yaml` but the `did.web` is also available as a reference. It will deploy de following components:
- A did:key `did:key:...` component to provide a decentralized identifier to the provider, used to sign the messages generated at the provider's side.
- The already seen utilities pods.
```shell
hFileCommand provider/common -b
    # Running CMD=[helm -n provider install -f "./Helms/provider/common/values.yaml" provider-common "./Helms/provider/common/"  --create-namespace]
export DEF_KTOOLS_NAMESPACE=provider
kGet -w
    Every 2.0s: kubectl get pod -n provider                                                                                                                            V22088: Tue Nov 19 23:45:58 2024

    NAME                              READY   STATUS    RESTARTS   AGE
    did-key-7789dd6dc7-9zj9b          1/1     Running   0          25s
    utils-echo-6ff8f87546-tx5gw       1/1     Running   0          25s
    utils-nettools-8554c96795-c9j96   1/1     Running   0          25s
```
## step04.2- _Deployment of the authentication components_
```shell
# To show the structure of the github after the completion of this step
git checkout phase04.step02
```

This Helm chart contains the following components:
<p style="text-align:center;font-style:italic;font-size: 75%"><img src="./../images/provider-components-authentication.png"><br/>
    Authentication components</p>

- A MySql DB server to provide storage to the _Fiware Trusted Issuer List_ and the _Credential Config Service_ as shown in the diagram.
- [Fiware Trusted Issuers List](https://github.com/FIWARE/trusted-issuers-list), It is the same component than the _Fiware Trusted Issuers List_ deployed at the trustAnchor. It plays the role of providing a [Trusted Issuers List API](https://github.com/FIWARE/trusted-issuers-list/blob/main/api/trusted-issuers-list.yaml) to manage the issuers in the provider.
- A [Credential Config Service](https://github.com/FIWARE/credentials-config-service): This service manages the Trusted issuer registries and the Trusted issuer local registries to be used to permorm the credential authentication. It enables the use of multiple trust anchors.
- A [VCVerifier](https://github.com/FIWARE/VCVerifier) that provides the necessary endpoints(see [API](https://github.com/FIWARE/VCVerifier/blob/main/api/api.yaml)) to offer [SIOP-2](https://openid.net/specs/openid-connect-self-issued-v2-1_0.html#name-cross-device-self-issued-op)/[OIDC4VP](https://openid.net/specs/openid-4-verifiable-presentations-1_0.html#request_scope) compliant authentication flows to request and present VC credentials as an extension to the well-established [OpenID Connect](https://openid.net/connect/). It exchanges VerfiableCredentials for JWT, that can be used for authorization and authentication in down-stream components.

```shell
hFileCommand provider/authentication -b
    # Running CMD=[helm -n provider install -f "./Helms/provider/authentication(verif+credentConfigSvc+til)/values.yaml" provider-authentication "./Helms/provider/authentication(verif+credentConfigSvc+til)/"  --create-namespace]
kGet -w
    Every 2.0s: kubectl get pod -n provider                                                                                                                            V22088: Tue Nov 19 23:48:38 2024

    NAME                              READY   STATUS    RESTARTS      AGE
    cconfig-6f88d6f88f-p9z29          1/1     Running   2 (58s ago)   67s
    did-key-7789dd6dc7-9zj9b          1/1     Running   0             3m5s
    mysql-0                           1/1     Running   0             67s
    til-5bb9996596-24chf              1/1     Running   2 (58s ago)   67s
    utils-echo-6ff8f87546-tx5gw       1/1     Running   0             3m5s
    utils-nettools-8554c96795-c9j96   1/1     Running   0             3m5s
    verifier-64965b55f9-qktrq         1/1     Running   0             67s
```

The VCVerifier's routes have to be exposed at the apisix to enable the OIDC protocol with clients to be available.   
The endpoint will be `https://fiwaredsc-provider.local/.well-known/openid-configuration`. The DNS has to be registered at the Apisix, and also the new routes have to be added to the apisix data plane, using the same steps that in previous additions using one of the manageAPI6Routes options (script of jupyterhub).

1- Update the apisix data plane to manage the new fiwaredsc-provider.local dns.
```yaml
# Ensure the apisix value files registers the fiwaredsc-provider.local dns
apisix:
  enabled: true
  ...
  dataPlane:
    ingress:
      enabled: true
      hostname: fiwaredsc-consumer.local
      tls: true
      extraHosts:
        ...
        - name: fiwaredsc-provider.local
          path: /
      extraTls:
        - hosts: [fiwaredsc-consumer.local, 
                  fiwaredsc-api6dashboard.local,
                  fiwaredsc-trustanchor.local,
                  fiwaredsc-provider.local]
          secretName: wildcardlocal-tls
```

```script
# Upgrade the apisix configuration
kRemoveRestart -n apisix data-plane
hFileCommand apisix upgrade
```
2- Register the local DNS `fiwaredsc-provider.local` at the `/etc/hosts` (ubuntu) and/or `C:\Windows\System32\drivers\etc\hosts` (windows)

3- Registration of the new apisix routes
```script
. scripts/manageAPI6Routes.sh insert -r ROUTE_WELLKNOWN_OIDC_fiwaredsc_vcverifier_local

. scripts/manageAPI6Routes.sh insert -r ROUTE_WELLKNOWN_JWKS_fiwaredsc_vcverifier_local

. scripts/manageAPI6Routes.sh insert -r ROUTE_WELLKNOWN_OIDC_Service_fiwaredsc_vcverifier_local
```

### Verification of the deployment so far
Besides checking that the pods have been properly deployed, a number of curl requests can be made to verfy the set:
```json
export DEF_KTOOLS_NAMESPACE=provider
kGet
    NAME                              READY   STATUS    RESTARTS      AGE
    cconfig-65c848fb4d-n8gbq          1/1     Running   2 (16m ago)   17m
    did-key-596d4576c-nrjxg           1/1     Running   0             26m
    mysql-0                           1/1     Running   0             17m
    til-5495699659-m2k97              1/1     Running   3 (17m ago)   17m
    utils-echo-6cd758785-wv2vq        1/1     Running   0             26m
    utils-nettools-597b8ddbfb-glzwm   1/1     Running   0             26m
    verifier-554b4b7d64-hf4xz         1/1     Running   0             17m

# Checks the trusted issuer list:
kExec net -- curl http://til:8080/v4/issuers/
  {"self":"/v4/issuers/","items":[],"total":0,"pageSize":0,"links":null}

# Checks the credential config service:
kExec net -- curl http://cconfig:8080/service
  {"total":0,"pageNumber":0,"pageSize":0,"services":[]}

# Checks the verifier
kExec net --curl http://verifier:3000/health -v
  {"status":"OK","component":{"name":"vcverifier","version":"" } }

# Checks the well known OpenID endpoint
curl -k https://fiwaredsc-provider.local/.well-known/openid-configuration
    {
      "issuer": "https://fiwaredsc-provider.local",
      "authorization_endpoint": "https://fiwaredsc-provider.local",
      "token_endpoint": "https://fiwaredsc-provider.local/services/hackathon-service/token",
      "jwks_uri": "https://fiwaredsc-provider.local/.well-known/jwks",
      "scopes_supported": [],
      "response_types_supported": [
        "token"
      ],
      "response_mode_supported": [
        "direct_post"
      ],
      "grant_types_supported": [
        "authorization_code",
        "vp_token"
      ],
      "subject_types_supported": [
        "public"
      ],
      "id_token_signing_alg_values_supported": [
        "EdDSA",
        "ES256"
      ]
    }
```
```shell
# To show the structure of the github after the completion of the next step
git checkout phase04.step03
```

## step04.3- _Deployment of the authorization components_
```shell
# To show the structure of the github after the completion of this step
git checkout phase04.step03
```
This Helm chart will deploy the following components:
<p style="text-align:center;font-style:italic;font-size: 75%"><img src="./../images/provider-components-authorization.png"><br/>
    Authorization components</p>

  - The _**PEP (Policy Enforcement Point)**_ has two main tasks.  
    - First, it is the entry point for enforcement, meaning it is the point where data or metadata is stopped and transferred to the Policy Decission Point (PDP), the PDP makes a decision regarding the right of the request to be accepted and returns it to the PEP.  
    - Secondly, the PEP will subsequently manipulate or lock the data according to the decision.  
  
    This role is played by the [Apache APISIX](https://apisix.apache.org/). This component has been already deployed in previous phases, but at this stage, it is setup to enable its role as PEP for the routes bound to the access to the provider's data or services enabling the interactions shown in the _Provider authorization components and interactions_ diagram shown below.

  - A **PDP (Policy Decision Point)**: Entity responsible for evaluating access requests and determining whether to permit or deny them based on predefined policies.  
  This role is played by the [**Styra OPA (Open Policy Agent**)](https://www.openpolicyagent.org/) is an open source, general-purpose policy engine that unifies policy enforcement across the stack. OPA provides a high-level declarative language that lets you specify policy as code and simple APIs to offload policy decision-making from your software.

  - The [**ODRL-PAP**](https://github.com/wistefan/odrl-pap) is used to configure policies written in [ODRL](https://www.w3.org/TR/odrl-model/) language to be consumed by the Open Policy Agent(OPA). Therefore it translates the ODRL policies into [Rego language](https://www.openpolicyagent.org/docs/latest/policy-language/). These policies will be later used to check if the incoming requests are authorized. 
  - A **PostgreSql DB server** to support the storage of these ODRL policies.  

    <p style="text-align:center;font-style:italic;font-size: 75%"><img src="../images/provider-authorization.png"><br/>
      Provider authorization components and interactions</p>

The diagram shows the interactions on this block. In it, the _Administrator_ is responsible for creating the ODRL policies that are used by the OPA when required.  
On the other side, requests to access the provider's data or services made by the _user_ are forwarded to the OPA to evaluate if they are authorized based on the ODRL policies and the credentials (Verifiable Credentials) presented by the user.  
Finally, the request is forwarded to the requested endpoint or rejected.

To deploy the authorization components:
```shell
hFileCommand provider/authorization -b
    # Running CMD=[helm -n provider install -f "./Helms/provider/authorization(odrlpap+opa)/./values.yaml" provider-authorization "./Helms/provider/authorization(odrlpap+opa)/./"  --create-namespace]
kGet -n provider
    #   Running command [kubectl get pod  -n provider  ]
    # Showing pod in namespace [provider]
    NAME                              READY   STATUS    RESTARTS      AGE
    cconfig-6f88d6f88f-fd65f          1/1     Running   2 (10h ago)   10h
    did-key-7789dd6dc7-8h477          1/1     Running   0             10h
    mysql-0                           1/1     Running   0             10h
    odrl-pap-588c44bc47-nsw47         1/1     Running   0             11h
    postgresql-0                      1/1     Running   0             11h
    til-5bb9996596-h5wq8              1/1     Running   2 (10h ago)   10h
    verifier-64965b55f9-w4762         1/1     Running   0             10h
```

```shell
# To show the structure of the github after the completion of the next step
git checkout phase04.step04
```

## Step 4.4- _Deployment of the service components_
```shell
# To show the structure of the github after the completion of this step
git checkout phase04.step04
```

This Helm chart will deploy the following components into the new namespace `services` to isolate it from the provider infrastructure:

<p style="text-align:center;font-style:italic;font-size: 75%"><img src="./../images/provider-components-services.png"><br/>
    Service components (Will vary depending on the offered services)</p>

- **Target Service**: This walkthrough will deploy a [Context Data broker Scorpio](https://scorpio.readthedocs.io/en/latest/) to provide NGSI-LD data access. The DNS `fiwaredsc-provider.local` will route requests to this service.  
- A **Data space configuration service**: to expose information related to the exposed service at the well known url `/.well-known/data-space-configuration`.
- A **Job to initialize data**: In this scenario, it just inserts some data into de Scorpio CB
- A **Job to register the service** into the credential config service. This job will be explained in next phase ([Initial setup of th Data space](README-initialSetUpOfTheDS.md))
- A **Postgis DB server** to support the storage of the NGSI-LD records. Postgis is used by the Scorpio Context Broker because it can manage spatial data.
  
```shell
hFileCommand provider/service -b
    # Running CMD=[helm -n service install -f "./Helms/provider/services(dataplane)/values.yaml" services "./Helms/provider/services(dataplane)/"  --create-namespace]
kGet -n service
    #   Running command [kubectl get pod  -n service  ]
    # Showing pod in namespace [service]
    NAME                          READY   STATUS      RESTARTS   AGE
    ds-scorpio-57889c6cc8-95ht7   1/1     Running     0          23m
    ds-scorpio-init-data-42kqk    0/1     Completed   0          21m
    postgis-0                     1/1     Running     0          23m
```
```shell
# To show the structure of the github after the completion of the next step
git checkout phase04.step05
```
## Step 4.5-Addition of the service routes to the Apisix without security
```shell
# To show the structure of the github after the completion of this step
git checkout phase04.step05
```

 This step exposes the service without any authentication nor authorization process. It is just created for testing and should be replaced as soon as possible by the route managed by the Data Space Connector (authentication and authorization processes enabled).
 This step also exposes a well known endpoint to show details about the service. 
 

To enable it, just register a new route to access the URL `https://fiwaredsc-provider.local/ngsi-ld/...`. This route redirects the requests to the scorpio context broker
```json
# https://fiwaredsc-provider.local/ngsi-ld/...
ROUTE_PROVIDER_SERVICE_fiwaredsc_provider_local_0auth='{
  "uri": "/services/hackathon-service/ngsi-ld/*",
  "name": "hackathon_service",
  "host": "fiwaredsc-provider.local",
  "methods": ["GET"],
  "upstream": {
    "type": "roundrobin",
    "scheme": "http",
    "nodes": {
      "ds-scorpio.service.svc.cluster.local:9090": 1
    }
  },
  "plugins": { 
    "proxy-rewrite": { "regex_uri": ["^/services/hackathon-service/ngsi-ld/(.*)", "/ngsi-ld/$1"] }
  }
}',
"ROUTE_PROVIDER_fiwaredsc_provider_local_dataSpaceConfiguration": {
    "uri": "/.well-known/data-space-configuration",
    "name": "fiwaredsc_provider_dataSpaceConfiguration",
    "host": "fiwaredsc-provider.local",
    "methods": [ "GET" ],
    "upstream": {
        "type": "roundrobin",
        "scheme": "http",
        "nodes": {
            "dsconfig.service.svc.cluster.local:3002": 1
        }
    },
    "plugins": {
        "proxy-rewrite": {
            "uri": "/.well-known/data-space-configuration/data-space-configuration.json"
        }
    }
},
```

```shell
. ./scripts/manageAPI6Routes.sh insert -r ROUTE_PROVIDER_SERVICE_fiwaredsc_provider_local_0auth
. ./scripts/manageAPI6Routes.sh insert -r ROUTE_PROVIDER_fiwaredsc_provider_local_dataSpaceConfiguration
```
To test it, just run
```shell
# Test the service
curl -k https://fiwaredsc-provider.local/services/hackathon-service/ngsi-ld/v1/entities?type=Order
    [ {
      "id" : "urn:ngsi-ld:Order:SDBrokerId-Spain.2411331.000003",
      "type" : "Order",
      "dateCreated" : {
        "type" : "Property",
    ...
    
# Test the well known data space configuration
curl -k https://fiwaredsc-provider.local/.well-known/data-space-configuration
{
  "supported_models": ["https://raw.githubusercontent.com/cgonzalezITA/smart-data-models-incubated/refs/heads/master/SMARTLOGISTICS/GS1/Order/schema.json"],
  "supported_protocols": ["http","https"],
  "authentication_protocols": ["oid4vp"]
}
```
**NOTE**: The order shown has been inserted by the job created to initialize the data at the [Step 4.4- _Deployment of the service components_](#step-44--deployment-of-the-service-components).

```shell
# To show the structure of the github after the completion of the next step
git checkout phase05.step01
```

## Bottom line
The deployment of the provider components leaves the data space ready to be setup and used. The next phase [Initial setup of the Dataspace](README-initialSetUpOfTheDS.md) will show the actions to register the participants in the dataspace and will continue the configuration to provide authentication and authorization mechanisms to the dataspace to comply with the  [DSBA Technical Convergence recommendations](https://data-spaces-business-alliance.eu/wp-content/uploads/dlm_uploads/Data-Spaces-Business-Alliance-Technical-Convergence-V2.pdf):

   <p style="text-align:center;font-style:italic;font-size: 75%"><img src="./../images/Fiware-DataSpaceGlobalArch-phase04.png"><br/>
    Architecture after the provider components deployment is completed</p>