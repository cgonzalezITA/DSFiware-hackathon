# DSFiware-hackathon

- [DSFiware-hackathon](#dsfiware-hackathon)
  - [Organization of the repository](#organization-of-the-repository)
    - [Prerequisites](#prerequisites)
      - [Min hardware requirements:](#min-hardware-requirements)
      - [Software requirements:](#software-requirements)
  - [Step by step deployment guide](#step-by-step-deployment-guide)
    - [_Preparation of the working environment_](#preparation-of-the-working-environment)
    - [Deployment of apisix as gateway](#deployment-of-apisix-as-gateway)
    - [Deployment of the Verifiable Data Registry components (Trust-Anchor)](#deployment-of-the-verifiable-data-registry-components-trust-anchor)
    - [Consumer's infrastructure](#consumers-infrastructure)
    - [Provider's infrastructure](#providers-infrastructure)
    - [Final setup of the Dataspace](#final-setup-of-the-dataspace)
  - [Quick deployment from scratch](#quick-deployment-from-scratch)

This repository contains a generic version of the Data Space infrastructure deployed at the [Decarbomile Hands on Lab (HOL)](https://www.linkedin.com/feed/update/urn:li:activity:7266146265141301249/) that took place on _November 26-27 2024_ at the `ETSI Telecomunicación UPM Madrid`. The HOL was lead by [ITA](https://www.ita.es/) & [Capillar](https://capillarit.com) with the collaboration of the [UPM](https://www.upm.es) and [Fiware](https://www.fiware.org) under the umbrella of the [Decarbomile-Revolutionising last mile logistics in Europe](https://decarbomile.eu/).  
The content of this github can be used to deploy a generic data space using the [Fiware Data Space Components](https://github.com/FIWARE/data-space-connector) and hence, aligned with the [DSBA Technical Convergence recommendations](https://data-spaces-business-alliance.eu/wp-content/uploads/dlm_uploads/Data-Spaces-Business-Alliance-Technical-Convergence-V2.pdf) every organization participating in a data space should deploy.  
Once finalized, you will be familiar with concepts related with:
-  The `deployment of infrastructures` (_Kubernetes and Helm commands_)
-  The `decentralized identity` (_DID, VC, VP, ..._) that any participant in a data space infrastructure must be familiar with.
- How `the access to the services` is achieved. 
- How to manage DNSs to access the infrastucture, both local DNSs for testing (eg: _fiwaredsc-provider.local_) and global DNS for production (eg: _fiwaredsc-provider.ita.es_)
- How to identify and tailor the blocks you will need to participate in a data space depending on your role in it: Just as a Consumer?, as a Provider?, both as a Consumer and a Provider?
- ...


## Organization of the repository
There are two methods to deploy the infrastructure:
- A [step by step guide](#step-by-step-deployment-guide) explaining the concepts introduced at every step, the commands to be run and the configurations used. Besides, different variants are explained at the documentation not covered by the quick deployment guide. eg: _use of global DNSs_.
- A [quick deployment guide](#quick-deployment-from-scratch) with the same target, but focusing just on the commands and just on a local deployment of the infrastructure (no global DNSs are used on the references scripts).

**NOTE**: All commands run on these guidelines are executed from the github root folder. eg: _/projects/DSFiware-hackathon_

### Prerequisites
This HOL has been deployed on servers running OSs
- Ubuntu 20.04.6 LTS
- Ubuntu 24.04.1 LTS
- Debian GNU/Linux 12
#### Min hardware requirements:
```
RAM: 8Gi
Cores: 8
HD: 32GB (Smaller sizes could result in errors similar to the [0/1 nodes are available: 1 node(s) had untolerated taint {node.kubernetes.io/disk-pressure: }])
# Just as a reference, the details of the CPUs running the HOL are:
  ...
  CPU(s):                 8
  Vendor ID:              GenuineIntel
  Model name:             Intel(R) Xeon(R) Gold 5218 CPU @ 2.30GHz
  Model name:             Intel(R) Xeon(R) CPU E5-2670 v2 @ 2.50GHz
  ...
```


#### Software requirements: 
- Kubernetes: minikube, microk8s, use latests versions although no incompatibilities have been found. 
- Helm version min v3.16.4 (previous give problems with the oci protocol)

## Step by step deployment guide
The deployment is organized into phases, and depending on the complexity of the task to be addressed, they can be split into steps.  

The phases are the following:
### [_Preparation of the working environment_](./assets/docs/README-preparationGuide.md)
This section prepares the host to be ready for the deployment of the components.  
See the [Preparation guide](./assets/docs/README-preparationGuide.md).

### [Deployment of apisix as gateway](./assets/docs/README-apisix.md)
This section describes the steps to test the kubernetes environment while deploying the Apisix Gateway that is used to expose the required endpoints.
See the [apisix deployment guide](./assets/docs/README-apisix.md).

### [Deployment of the Verifiable Data Registry components (Trust-Anchor)](./assets/docs/README-trustAnchor.md)
This section describes the setup to deploy the components of the Verifiable Data Registry.  
See the [trust-anchor deployment guide](./assets/docs/README-trustAnchor.md).

### [Consumer's infrastructure](./assets/docs/README-consumer.md)
Any participant willing to consume services provided by the data space will require a minimum infrastructure that will enable the management of Verifiable Credentials besides a Decentralized Identifier that will constitue the signing mechanism to authenticate any message, any request made by the consumer.   
This section describes the steps and the components to be deployed.  
See the [consumer deployment guide](./assets/docs/README-consumer.md).

### [Provider's infrastructure](./assets/docs/README-provider.md)
Any organization willing to market their data and or services in a dataspace will require an infrastructure to manage:
- The authentication phase: Analyze that any request made to their services are made by a known and verified participant.
- The authorization phase: Analyze that any request made to their services are made by a participant entitled to perform the requested action.
- The data and or services offered.  

This section describes the steps and the components to be deployed at the provider's side
See the [consumer deployment guide](./assets/docs/README-provider.md).

### [Final setup of the Dataspace](./assets/docs/README-finalSetUpOfTheDS.md) 
This phase will show the actions to register the participants in the dataspace and will continue the configuration of the provider's service to enable authentication and authorization mechanisms to comply with the  [DSBA Technical Convergence recommendations](https://data-spaces-business-alliance.eu/wp-content/uploads/dlm_uploads/Data-Spaces-Business-Alliance-Technical-Convergence-V2.pdf)

See the [final setup of the dataspace guide](./assets/docs/README-finalSetUpOfTheDS.md).

## Quick deployment from scratch
This repository contains a generic version of the Fiware Data Space infrastructure.  The repo organizes the deployment of the different parties in phases and steps explained at the [step by step guide](#step-by-step-deployment-guide) that you can review to understand the components and their configurations. Some of the concepts explained are:
- The deployment of infrastructures (Kubernetes and Helm commands)
- The decentralized identity (DID, VC, VP, ...) that any participant in a data space infrastructure must be familiar with.
- How the access to the services is achieved.
- How to manage DNSs to access the infrastucture, both local DNSs for testing (eg: fiwaredsc-provider.local) and global DNS for production (eg: fiwaredsc-provider.ita.es)
- How to identify and tailor the blocks you will need to participate in a data space depending on your role in it: Just as a Consumer?, as a Provider?, both as a Consumer and a Provider?
...


This `quick` approach offers a set of scripts focused on the deployment of all the phases.  All these scripts use local DNSs (eg: fiwaredsc-consumer.local); to learn how to setup the components using global DNS (eg: fiwaredsc-consumer.ita.es) check the [Step by step deployment guide](#step-by-step-deployment-guide).

Each script is standalone and does not require the execution of any other previous script. eg: Script [qInstall-phase05.04-FinalSetup-AccessTheServiceWithAValidVC](./scripts/quickInstall/qInstall-phase05.04-FinalSetup-AccessTheServiceWithAValidVC.sh) deploys the whole infrastructure and does not depend on any other script.  

  **NOTE**: _although these scripts have been tested in different  Ubuntu versions (See [Prerequisites](#prerequisites)), they may contain steps that require manual actions (such as editting a file with sudo permissions), althought they have been tried to be automated, so in case of failure, please review the logs and perform these steps manually (copying, pasting) for a better understanding of the whole process)_  
  **TIP**: It is recommended to launch the scripts from the main branch as it contains the latests versions.  
Before the quick deployment can be run, a number of previous steps have to be satisfied at the [folder with the script files (./scripts/quickinstall)](./scripts/quickInstall/):  
1. To grant the proper execution permissions to the scripts at the HOL, run the following command.
**NOTE**: Remember that all commands run on these guidelines are executed from the github base folder. eg: _/projects/DSFiware-hackathon_
    ```shell
    cd /projects/DSFiware-hackathon
    echo "# add exec permissions to the Script files"
    find ./ -name "*.sh" -type f -exec chmod +x {} +
    ```
2. In case you do not have a kubernetes cluster on hand, the [./scripts/quickInstall/installMicrok8s.sh](./scripts/quickInstall/installMicrok8s.sh)  contains the actions to quickly deploy a microK8s cluster on one node.
    ```shell
    . scripts/quickInstall/installMicrok8s.sh
    # This scripts opens a new shell so, to continue the installation, the same command with a "2" param has to be run (2nd phase)
    . scripts/quickInstall/installMicrok8s.sh 2
    ```
3. To deploy the devopTools, run the [./scripts/quickInstall/installDevopTools.sh](./scripts/quickInstall/installDevopTools.sh) script.  
    ```shell
    # Syntax: installDevopTools.sh <DEVTOOLS_FOLDERNAME=devopTools> <DDEVTOOLS_FOLDERBASE=$(pwd)>
    # eg The following command will deploy them at the 'devopTools' subfolder
    ./scripts/quickInstall/installDevopTools.sh devopTools
    ```
4. Registration of the local DNSs: The scripts require to access a number of local DNS that have to be registered at the '/etc/hosts' file (ubuntu). Root access is required to modify it. The [dsQuickinstall-dnsRegistration](./scripts/quickInstall/qInstall-dnsRegistration.sh) script can be run (as sudo) to register them
    ```shell
    sudo ./scripts/quickInstall/dsQuickinstall-dnsRegistration.sh
        # Registers the DNSs used by the dsQuickInstall* scripts at the '/etc/hosts' file to map them with the host IP address
        QUESTION: (timeout=30s. def=y)--># To use the local DNSs at the host, it is required to add the following line to the '/etc/hosts' file:
        
        1.1.1.1  fiwaredsc-trustanchor.local fiwaredsc-consumer.local fiwaredsc-provider.local

        Do you want to insert it automatically? (y*|n)
        y
        To access them from a windows browser, add the same line to the 'C:\Windows\System32\drivers\etc\hosts' file.
        (timeout=5s)Press any key to review the /etc/hosts file
            ...
            # local DNS used by the https://github.com/cgonzalezITA/DSFiware-hackathon repository
            1.1.1.1  fiwaredsc-trustanchor.local fiwaredsc-consumer.local fiwaredsc-provider.local
    ```

5. For each of the phases and steps of this guideline, there is a script file at the [./scripts/quickInstall](./scripts/quickInstall) folder that deploys the specified phase/step:  
**NOTE**: Just in case the previous step (_4. Registration of the local DNSs:_)  was not run, the scripts still try to register the local DNSs at the /etc/hosts file. If you have already registered them, just answer 'n' (default answer) to avoid trying its registration:  
    ```shell
    ...
    QUESTION: (timeout=15s. def=n)--># To use the local DNSs at the host, it is required to add a few lines to the '/etc/hosts' file:
    
    193.144.226.86  fiwaredsc-trustanchor.local fiwaredsc-consumer.local fiwaredsc-provider.local
    Do you want to insert it automatically? (y|n*)
    n
    ```
    **NOTE**: _Remember that each script is standalone and does not require the execution of any other previous script. eg: Script [qInstall-phase05.04-FinalSetup-AccessTheServiceWithAValidVC](./scripts/quickInstall/qInstall-phase05.04-FinalSetup-AccessTheServiceWithAValidVC.sh) deploys the whole infrastructure and does not depend on any other script_.  


    ```shell
    # Standalone scripts to deploy and test the different phases/steps of the HOL.
    qInstall-full.sh
    # Phase 1 testing dev environment and correct deployment of Apisix
    qInstall-phase01.01-KubernetesTesting-DeployABasicVersionOfHelloworld.sh
    qInstall-phase01.02-Apisix-HelmDeployFirstFunctionalVersionOfApisix.sh
    qInstall-phase01.03-Apisix-AddNewRoutesToApisix.sh
    qInstall-phase01.04-Apisix-UseAdminAPIToManageRoutes.sh
    # Phase 2 Deployment of the Trust Anchor
    qInstall-phase02.01-TrustAnchor-HelmDeployTrustAnchor.sh
    # Phase 3 Deployment of the Consumer components
    qInstall-phase03.01-Consumer-HelmDeployDID.sh
    qInstall-phase03.02-Consumer-HelmDeployVCIssuerKeycloak_withDIDKEY.sh
    qInstall-phase03.04-Consumer-IssuanceOfVerifiableCredentials.sh
    # Phase 4 Deployment of the Provider and Service components
    qInstall-phase04.02-Provider-DeployAuthenticationComponents.sh
    qInstall-phase04.05-Provider-DeployProviderApisixRoutes.sh
    qInstall-phase05.03-FinalSetup-RegistrationOfTheParticipantsIntoTheDS.sh
    qInstall-phase05.04-FinalSetup-AccessTheServiceWithAValidVC.sh
    ```

6- The qInstall-full.sh script deploys the latest version of the different components, useful if you want to modify the values and try the complete deployment from scratch. 

These quickInstall scripts may take several minutes to finalize as the whole infrastructure has to be recreated from scratch and some components have to be downloaded from the internet. The scripts are split in three different sections:
- Removal of any previously existing component.
- Deployment and configuration: Deployment of the components (helm charts, secrets, apisix routes, ...)
- Verification: A curl command tests the proper response is returned once the complete infrastructure required for the specific phase and step is deployed (eg: _whereas the [qInstall-phase01.01-DeployABasicVersionOfHelloworld](./scripts/quickInstall/qInstall-phase01.01-KubernetesTesting-DeployABasicVersionOfHelloworld.sh) only requires the deployment the apisix helm chart (besides a secret)_.

The final [qInstall-phase05.04-FinalSetup-AccessTheServiceWithAValidVC](./scripts/quickInstall/qInstall-phase05.04-FinalSetup-AccessTheServiceWithAValidVC.sh) deploys the complete data space infrastructure as shown in the bottom image. Among the multiple logs printed out at the console, the final ones -the verification of the correct deployment- should look something similar to:
```shell
 . qInstall-phase05.04-FinalSetup-AccessTheServiceWithAValidVC.sh
    ...
    # Verification
    # First of all, a VC is issued to the user with ORDERCONSUMER role
    DATA_SERVICE_ACCESS_TOKEN=eyJhbGciOi...H0Q
    # Now, this VC is used to retrieve the JWT validated to access the service
    DATA_SERVICE_ACCESS_TOKEN=eyJhbGciO...xWw
    # Access to the service (with both authentication and authorization enabled):

    RC=200
    (timeout=5s)"curl -s -k https://fiwaredsc-provider.local/services/hackathon-service/ngsi-ld/v1/entities?type=Order     --header "Accept: application/json"     --header "Authorization: Bearer eyJhbGciOiJSUzI1NiIsImtpZCI6ImpWX3YxYmsxMDRFWFVyRG5aZFBBYXhRNWNXZ1R5UUREdXpuWlAxNEJncjAiLCJ0eXAiOiJKV1QifQ.eyJhdWQiOlsiaGFja2F0aG9uLXNlcnZpY2UiXSwiY2xpZW50X2lkIjoiZGlkOmtleTp6RG5hZVVuWkhkUFJxQTViR0J0aGtNSnB1RVNxRTlwaEZNMWpnU3A2ZmRzUFZaZ0REIiwiZXhwIjoxNzM0NTE1MDQ5LCJpc3MiOiJkaWQ6a2V5OnpEbmFlVW5aSGRQUnFBNWJHQnRoa01KcHVFU3FFOXBoRk0xamdTcDZmZHNQVlpnREQiLCJraWQiOiJqVl92MWJrMTA0RVhVckRuWmRQQWF4UTVjV2dUeVFERHV6blpQMTRCZ3IwIiwic3ViIjoiIiwidmVyaWZpYWJsZUNyZWRlbnRpYWwiOnsiQGNvbnRleHQiOlsiaHR0cHM6Ly93d3cudzMub3JnLzIwMTgvY3JlZGVudGlhbHMvdjEiLCJodHRwczovL3d3dy53My5vcmcvbnMvY3JlZGVudGlhbHMvdjEiXSwiY3JlZGVudGlhbFN1YmplY3QiOnsiZW1haWwiOiJvcmRlcmNvbnN1bWVydXNlckBjb25zdW1lci5vcmciLCJmaXJzdE5hbWUiOiJPcmRlckNvbnN1bWVyIiwibGFzdE5hbWUiOiJVc2VyIiwicm9sZXMiOlt7Im5hbWVzIjpbIk9SREVSX0NPTlNVTUVSIl0sInRhcmdldCI6ImRpZDprZXk6ekRuYWVhUUR0UGFWNTkyUzl2b1pxTHVlbmJDQW5qeDFleTR0UThhMzZVMnNyblY2aCJ9XX0sImlkIjoidXJuOnV1aWQ6ZGE2MzA1YzEtYjBjOS00ZTliLTlhYjUtNDZkY2U1Zjg1MDRlIiwiaXNzdWFuY2VEYXRlIjoiMjAyNC0xMi0xOFQwOToxMzo1N1oiLCJpc3N1ZXIiOiJkaWQ6a2V5OnpEbmFlYVFEdFBhVjU5MlM5dm9acUx1ZW5iQ0FuangxZXk0dFE4YTM2VTJzcm5WNmgiLCJ0eXBlIjpbIk9wZXJhdG9yQ3JlZGVudGlhbCJdfX0.sLsR8ioqQHBg3QVUyceSkqfzJt4wgjn8_tAptcXdjesWQwLD4BE7oF6ZvJNyZTlvEU5aUQm_PDig1D1xFozEIKt3RyRPfLoym0irwb8bLxHcGv9StvwvQDRNUQg1nwjE_FUosvk9jI0c6UKdYrFTRo0rbhNBB_83JjVstGDj9KhZ2Fp1t0ksEOhjEoBPpWxClDr1JgM2srmVw4KPF7vfJgQh2au7C8fPq1nmXypagvCykJJN5ReK6NakV914KNOnWl_csDIhjWK2_vzTKMdPaCA-uf2FOqvFQj-dqhJ5M5oBUhtOCAigR9S67fDCpuXjJP5OxB9r21vk_SeOPmsxWw"" 
    returns a valid json. It has worked! Congrats!.
```

<p style="text-align:center;font-style:italic;font-size: 75%"><img src="./assets/images/Fiware-DataSpaceGlobalArch-phase05.png"><br/>
Architecture after the whole Data Space infrastructure is deployed</p>
