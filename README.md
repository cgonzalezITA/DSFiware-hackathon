# DSFiware-hackathon
This repository contains a generic version of the Data Space infrastructure deployed at the [Decarbomile Hack](https://www.linkedin.com/feed/update/urn:li:activity:7266146265141301249/) that took place on _November 26-27 2024_ at the `ETSI Telecomunicación UPM Madrid`. The HOL was lead by [ITA](https://www.ita.es/) & [Capillar](https://capillarit.com) with the collaboration of the [UPM](https://www.upm.es) and [Fiware](https://www.fiware.org) under the umbrella of the [Decarbomile-Revolutionising last mile logistics in Europe](https://decarbomile.eu/).  
The content of this github can be used to deploy a generic data space using the [Fiware Data Space Components](https://github.com/FIWARE/data-space-connector) and hence, aligned with the [DSBA Technical Convergence recommendations](https://data-spaces-business-alliance.eu/wp-content/uploads/dlm_uploads/Data-Spaces-Business-Alliance-Technical-Convergence-V2.pdf) every organization participating in a data space should deploy.  
Once finalized the `Initial setup of the Dataspace`, you will be familiar with concepts related with:
-  The `deployment of infrastructures` (_Kubernetes and Helm commands_)
-  The `decentralized identity` (_DID, VC, VP, ..._) that any participant in a data space infrastructure must be familiar with.
- How `the access to the services` is achieved. 
- ...

Once deployed the whole infrastructure, this github can be used as a playground to play with the policies ODRL deployed, replace the provider's service by your own service, ...

- [DSFiware-hackathon](#dsfiware-hackathon)
  - [Organization](#organization)
  - [Step by step deployment guide](#step-by-step-deployment-guide)
    - [_Installation of the devop tools to ease the life during deployment_](#installation-of-the-devop-tools-to-ease-the-life-during-deployment)
    - [Deployment of apisix as gateway](#deployment-of-apisix-as-gateway)
    - [Deployment of the Verifiable Data Registry components (Trust-Anchor)](#deployment-of-the-verifiable-data-registry-components-trust-anchor)
    - [Consumer's infrastructure](#consumers-infrastructure)
    - [Provider's infrastructure](#providers-infrastructure)
    - [Initial setup of the Dataspace](#initial-setup-of-the-dataspace)
  - [Quick deployment from scratch](#quick-deployment-from-scratch)

## Organization
There are two methods to deploy the infrastructure:
- A [step by step guide](#step-by-step-deployment-guide) explaining the concepts introduced at every step and the commands to be run.
- A [quick deployment guide](#quick-deployment-from-scratch) with the same target, but focusing just on the commands.

**NOTE**: All commands run on these guidelines are executed from the github root folder.

The deployment is organized into phases, and depending on the complexity or the skills to be addressed, they can be split into steps.
At the beginning of each one of these sections, the first command to be run is a checkout to the tag matching the content of the repo at the end of the section. eg. 
```shell
git checkout phase01.step01
# The git will contain the documentation, configuration, files, etc. existing at the end of this phase01, step01 (Deploy a basic version of a helloWorld chart)
```
On the other side, the last comment of each section is the `git checkout <next phaseXX:stepYY>` of the next phase/step to be addressed.


## Step by step deployment guide
### [_Installation of the devop tools to ease the life during deployment_](./assets/docs/README-preparationGuide.md)
This section installs a set of tools used during the deployment of the components.  
See the [Preparation guide](./assets/docs/README-preparationGuide.md)

### [Deployment of apisix as gateway](./assets/docs/README-apisix.md)
This section describes the steps to test the kubernetes environment while deploying the Apisix Gateway that is used to expose the required endpoints.
See the [apisix deployment guide](./assets/docs/README-apisix.md)

### [Deployment of the Verifiable Data Registry components (Trust-Anchor)](./assets/docs/README-trustAnchor.md)
This section describes the setup to deploy the components of the Verifiable Data Registry.  
See the [trust-anchor deployment guide](./assets/docs/README-trustAnchor.md)

### [Consumer's infrastructure](./assets/docs/README-consumer.md)
Any participant willing to consume services provided by the data space will require a minimum infrastructure that will enable the management of Verifiable Credentials besides a Decentralized Identifier that will constitue the signing mechanism to authenticate any message, any request made by the consumer.   
This section describes the steps and the components to be deployed.  
See the [consumer deployment guide](./assets/docs/README-consumer.md)

### [Provider's infrastructure](./assets/docs/README-provider.md)
Any organization willing to market their data and or services in a dataspace will require an infrastructure to manage:
- The authentication phase: Analyze that any request made to their services are made by a known and verified participant.
- The authorization phase: Analyze that any request made to their services are made by a participant entitled to perform the requested action.
- The data and or services offered.  
This section describes the steps and the components to be deployed at the provider's side
See the [consumer deployment guide](./assets/docs/README-provider.md)

### [Initial setup of the Dataspace](README-initialSetUpOfTheDS.md) 
This phase will show the actions to register the participants in the dataspace and will continue the configuration to provide authentication and authorization mechanisms to the dataspace to comply with the  [DSBA Technical Convergence recommendations](https://data-spaces-business-alliance.eu/wp-content/uploads/dlm_uploads/Data-Spaces-Business-Alliance-Technical-Convergence-V2.pdf)

## Quick deployment from scratch
To speed up the deployment, this github contains a [folder with script files (./scripts/quickinstall)](./scripts/quickInstall/) to perform the following actions  
**NOTE**: _although these scripts have been tested in an `Ubuntu 20.04.6 LTS`, they may contain steps that require manual actions (such as editting a file with sudo permissions), so in case of failure, please review the logs and perform the steps manually (copying, pasting) for a better understanding of the whole process)_
1. In case you do not have a kubernetes cluster on hand, the [./scripts/quickInstall/installMicrok8s.sh](./scripts/quickInstall/installMicrok8s.sh)  contains the steps to quickly deploy a microK8s cluster on one node.
    ```shell
    . scripts/quickInstall/installMicrok8s.sh
    # This scripts opens a new shell so, to continue the installation, the same command with a "2" param has to be run (2nd phase)
    . scripts/quickInstall/installMicrok8s.sh 2
    ```
2. To deploy the devopTools, just run the [./scripts/quickInstall/installDevopTools.sh](./scripts/quickInstall/installDevopTools.sh)  
    ```shell
    # Syntax: installDevopTools.sh <DEVTOOLS_FOLDERNAME=devopTools>\
    #       <DDEVTOOLS_FOLDERBASE=$(pwd)>
    # eg The following command will create at the current terminal path a subfolder 'devopTools' with them
    . ./scripts/quickInstall/installDevopTools.sh devopTools
    ```
3. For each of the phases and steps of this guideline, there will be a file at the [./scripts/quickInstall](./scripts/quickInstall) folder that deploys the specified step:
    ```shell
    . scripts/quickInstall/dsQuickinstall-phase01.step01.sh
    . scripts/quickInstall/dsQuickinstall-phase01.step02.sh
    ...
    ```
