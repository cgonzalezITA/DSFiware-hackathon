#!/bin/bash
SCRIPTNAME=$BASH_SOURCE
if [ "$0" == "$BASH_SOURCE" ]; then CALLMODE="executed"; else CALLMODE="sourced"; fi
BASEDIR=$(dirname "$SCRIPTNAME")
VERBOSE=true
SUBMODULE=""

. $BASEDIR/_base.sh
SCRIPTNAME=$BASH_SOURCE
[[ "$#" -gt 0 ]] && PHASE=$1; shift || PHASE="";
#---------------------------------------------- main program ------------------------
if [[ "${#PHASE}" -eq 0 ]] || [ "$PHASE" == "1" ]; then
    echo "Installing snapd ..." 
    sudo apt install snapd
    echo "Installing microk8s ..." 
    sudo snap install microk8s --classic

    echo "Adding user to group microk8s"
    sudo usermod -a -G microk8s $USER
    sudo chown -f -R $USER ~/.kube
    echo "Next step will open a new shell."
    echo ">>> To continue, run script \"$SCRIPTNAME 2\""
    exec newgrp microk8s
elif [ "$PHASE" == "2" ]; then
    echo "First test ..." 
    # microk8s kubectl get all --all-namespaces
    CMD="microk8s kubectl get pods"
    echo "Running CMD=[$CMD]"
    $($CMD)
    RC=$?
    if [[ "$RC" -ne 0 ]]; then
        echo "An error $RC has happened. Please, review the logs"
        return
    else
        echo "First test successful!"
    fi

    echo "Enable dashboard ..." 
    microk8s enable dashboard dns ingress

    echo "If something has failed, it may be due to an already existing installation of another k8s cluster?"

    # If you previously had minikube installed
    # minikube stop && minikube delete

    echo "Sets the KUBECONFIG env var"
    # https://discuss.kubernetes.io/t/use-kubectl-with-microk8s/5313/2
    microk8s.kubectl config view --raw > $HOME/.kube/microk8s.config
    # This command is just in case you had a previous minikube installed
    [ -f $HOME/.kube/config ] && cp $HOME/.kube/config $HOME/.kube/config.backup;
    microk8s.kubectl config view --raw > $HOME/.kube/config
    # Add next two lines to your ~/.bashrc
    export  KUBECONFIG=$HOME/.kube/config
    export  KUBECONFIG=$KUBECONFIG:$HOME/.kube/microk8s.config

    echo "Adds storage classic"
    # https://stackoverflow.com/questions/74741993/0-1-nodes-are-available-1-pod-has-unbound-immediate-persistentvolumeclaims"
    kubectl apply -f https://raw.githubusercontent.com/rancher/local-path-provisioner/master/deploy/local-path-storage.yaml
    kubectl patch storageclass local-path -p '{"metadata": {"annotations":{"storageclass.kubernetes.io/is-default-class":"true"}}}'


    # Next command exposes the dashboard.
    # Open a new terminal and leave the other just with the dashboard running
    # microk8s dashboard-proxy
    echo "Now, you new shells should have a running microk8s cluster"
    echo "Second test using syntax kubectl ..."  
    CMD="kubectl get pods"
    echo "Running CMD=[$CMD]"
    $($CMD)
    RC=$?
    if [[ "$RC" -ne 0 ]]; then
        echo "An error $RC has happened. Please, review the logs"
        return
    else
        echo "Second test successful!"
    fi
else
    echo "Unknown phase [$PHASE] specified, use 1 or 2"
fi