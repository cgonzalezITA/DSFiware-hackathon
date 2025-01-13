# Step00: Deployment of devops tools

- [Step00: Deployment of devops tools](#step00-deployment-of-devops-tools)
  - [Introduction](#introduction)
  - [Kubernetes](#kubernetes)
  - [DevopTools](#devoptools)
  - [Notes](#notes)

## Introduction
This section installs the software tools used during the deployment of the fiware Data Space components.  

## Kubernetes 
This guideline uses Kubernetes and Helm to deploy the infrastructure.  
- In case you do not have a kubernetes cluster on hand, the [./scripts/quickInstall/installMicrok8s.sh](./scripts/quickInstall/installMicrok8s.sh)  contains the steps to quickly deploy a [microK8s](https://microk8s.io/) cluster on the host server.
    ```shell
    . scripts/quickInstall/installMicrok8s.sh
    # This scripts opens a new shell so, to continue the installation, the same command with a "2" param has to be run (2nd phase)
    . scripts/quickInstall/installMicrok8s.sh 2
    ```
- You can also follow the [Helm install documentation](https://helm.sh/docs/intro/install/) to install the Helm tool.
## DevopTools
There are a set of tools that based on clues, ease the life of people working with different devops tools: git, docker, k8s or helm.  
**NOTE**: These tools are designed to work on Ubuntu based systems.

Clone the [devopTools](https://github.com/cgonzalezITA/devopsTools) repository and follow its [README.md](https://github.com/cgonzalezITA/devopsTools/blob/master/README.md) to deploy the tools.  
The repository contains a [quick deploy script to make the devopTools usable](https://github.com/cgonzalezITA/devopsTools/blob/master/quickDeployment/deployDevopTools.sh) from CLI.

```shell
git clone https://github.com/cgonzalezITA/devopsTools.git
cd devopsTools
. quickDeployment/deployDevopTools.sh 
  # add exec permissions to the devopTools
  QUESTION: (timeout=15s. def=y)--># To use aliases, the ~/.bash_aliases file must contain a few aliases. Do you want to add them? (y*|n)
  y
  # Review the ~/.bash_aliases file to check the content is not duplicated nor contains errors.  

  # Activating the aliases...
  Check yq is installed
  ✅🆗
  Checking jq is installed
  ✅🆗
```

This guideline uses the devoptTools commands to execute the  required actions during the deployment, although the kubernetes or helm equivalent commands are also shown as comments in case you do not have an Ubuntu OS or do not want to install these tools. eg:
```shell
kGet -n consu
  #   Running command [kubectl get pod  -n consumer  ]
  ...
```

## Notes
- To get familiar with some Helm basic commands, you can visit the section [_Helm Repo operations_](https://github.com/cgonzalezITA/devopsTools/tree/master/hTools#readme) of the [devop Tools](https://github.com/cgonzalezITA/devopsTools).  
- Before a Helm chart can be used, a command to update the referenced dependencies has to be executed. The hFileCommand provides the -b flag to run this command. his process will create inside the Helm chart folder a subfolder named ./chart with the charts used in the specific Helm.  
Next scripts show the deployment of the provider service helm chart:
  ```shell
  # Deployment of a Helm chart without the dependencies installed.
  hFileCommand service 
      # Running CMD=[helm -n provider install -f "./Helms/provider/services(dataplane)/values.yaml" services "./Helms/provider/services(dataplane)/"  --create-namespace]
      Error: INSTALLATION FAILED: An error occurred while checking for chart dependencies. You may need to run `helm dependency build` to fetch missing dependencies: found in Chart.yaml, but missing in charts/ directory: scorpio, postgresql

  # Deployment of a Helm chart 'building' the dependencies installed.
  hFileCommand service -b
      # Running command [helm -n provider dependency update './Helms/provider/services(dataplane)/' ]
      Hang tight while we grab the latest from your chart repositories...
      ...Successfully got an update from the "bitnami" chart repository
      Update Complete. ⎈Happy Helming!⎈
      # Running command [helm -n provider dependency build './Helms/provider/services(dataplane)/' ]
      ...
      # Running CMD=[helm -n provider install -f "./Helms/provider/services(dataplane)/values.yaml" services "./Helms/provider/services(dataplane)/"]
      ...      
  ```