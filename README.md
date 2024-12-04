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
