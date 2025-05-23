#!/bin/bash
SCRIPTNAME=$BASH_SOURCE
if [ "$0" == "$BASH_SOURCE" ]; then CALLMODE="executed"; else CALLMODE="sourced"; fi
BASEDIR=$(dirname "$SCRIPTNAME")
VERBOSE=true
SUBMODULE=""

. $BASEDIR/_base.sh
SCRIPTNAME=$BASH_SOURCE

function installDevopTools() {
    MSG="# Do you want to install the devopsTools (a mandatory set of tools used at this repository)?";
    REPLY=$(readAnswer "$MSG (y*|n)" 'y' 25)
    if [ $REPLY == 'y' ]; then
        # installDevopTools <DEVTOOLS_FOLDERNAME=devopTools> \
        #       <DDEVTOOLS_FOLDER=$(pwd)>
        DEVTOOLS_GH_HTTPS="https://github.com/cgonzalezITA/devopsTools.git"
        if [[ "$#" -gt 0 ]]; then DEVTOOLS_FOLDERNAME=$1 shift; else DEVTOOLS_FOLDERNAME="devopTools"; fi
        if [[ "$#" -gt 0 ]]; then DEVTOOLS_FOLDERBASE=$1 shift; else DEVTOOLS_FOLDERBASE="$(pwd)"; fi
        DEVTOOLS_FOLDER=$DEVTOOLS_FOLDERBASE/$DEVTOOLS_FOLDERNAME;
        echo "DEVTOOLS_FOLDER=[$DEVTOOLS_FOLDER]"
        REPLY='y'
        if [[ ! -d $DEVTOOLS_FOLDERBASE ]]; then
            echo "ERROR: Folder '$DEVTOOLS_FOLDERBASE' must exist";
            [ "$CALLMODE" == "executed" ] && exit -1 || return -1;
        fi
        if [[ -d $DEVTOOLS_FOLDER ]]; then
            REPLY=$(readAnswer "Folder $DEVTOOLS_FOLDER already exists. Do you want to delete it to reinstall the devopTools? (Y|n*)" \
                    'n')
            if [ $REPLY == 'y' ]; then
                sudo rm $DEVTOOLS_FOLDER -R
            else
                CURRENT_FOLDER=$(pwd)
                git pull
                cd $CURRENT_FOLDER
            fi
        fi
    
        CMD="git clone $DEVTOOLS_GH_HTTPS \"$DEVTOOLS_FOLDER\""
        bash -c "$CMD"
        echo "# add exec permissions to the devopTools"
        CMD="find \"$DEVTOOLS_FOLDER\" -name \"*.sh\" -type f -exec chmod +x {} +"
        eval "$CMD"
            
        MSG="# To use aliases, the ~/.bash_aliases file must add a few aliases. Do you want to add them?"
        if [ $(readAnswer "$MSG (y*|n)" 'y') == 'y' ]; then
            cat <<EOF >> ~/.bash_aliases

# --- devopTools aliases (Visit $DEVTOOLS_GH_HTTPS)
export _TOOLSFOLDER="$DEVTOOLS_FOLDER"
alias _fGetFile='\$_TOOLSFOLDER/fTools/_fGetFile.sh'
alias gPushAll='\$_TOOLSFOLDER/gTools/gPushAll.sh'
alias gFreeze='\$_TOOLSFOLDER/gTools/gFreeze.sh'
alias gCommit='\$_TOOLSFOLDER/gTools/gCommit.sh'
alias gInfo='\$_TOOLSFOLDER/gTools/gInfo.sh'
alias _dGetContainers='\$_TOOLSFOLDER/dTools/_dGetContainers.sh'
alias dLogs='\$_TOOLSFOLDER/dTools/dLogs.sh'
alias dCompose='\$_TOOLSFOLDER/dTools/dCompose.sh'
alias dExec='\$_TOOLSFOLDER/dTools/dExec.sh'
alias dGet='\$_TOOLSFOLDER/dTools/dGet.sh'
alias dInspect='\$_TOOLSFOLDER/dTools/dInspect.sh'
alias dRemove='\$_TOOLSFOLDER/dTools/dRemove.sh'
alias kSecret-show='\$_TOOLSFOLDER/kTools/kSecret-show.sh'
alias kExec='\$_TOOLSFOLDER/kTools/kExec.sh'
alias kGet='\$_TOOLSFOLDER/kTools/kGet.sh'
alias kFileCommand='\$_TOOLSFOLDER/kTools/kFileCommand.sh'
alias _kGetNamespace='\$_TOOLSFOLDER/kTools/_kGetNamespace.sh'
alias kSecret-create4Domain='\$_TOOLSFOLDER/kTools/kSecret-create4Domain.sh'
alias kDescribe='\$_TOOLSFOLDER/kTools/kDescribe.sh'
alias kLogs='\$_TOOLSFOLDER/kTools/kLogs.sh'
alias _kGetArtifact='\$_TOOLSFOLDER/kTools/_kGetArtifact.sh'
alias kSecret-createGeneric='\$_TOOLSFOLDER/kTools/kSecret-createGeneric.sh'
alias kRemoveRestart='\$_TOOLSFOLDER/kTools/kRemoveRestart.sh'
alias hFileCommand='\$_TOOLSFOLDER/hTools/hFileCommand.sh'

EOF
            $(readAnswer "Review the ~/.bash_aliases file to check the content is not duplicated nor contains errors.\n\
                Press a key to continue" '' 15 false false);        
        fi

        echo "# Activating the aliases..."
        shopt -s expand_aliases
        . ~/.bash_aliases
    fi

    echo "Check yq is installed"
    VERSION=$(yq --version 2>/dev/null)
    if [[ "$?" -ne 0 ]]; then
        echo -e "❌\ninstall yq"
        wget https://github.com/mikefarah/yq/releases/latest/download/yq_linux_amd64 -O ./yq && chmod +x ./yq && sudo mv ./yq /usr/bin
    else
        echo ✅🆗
    fi
    echo "Checking jq is installed"
    VERSION=$(jq --version 2>/dev/null)
    if [[ "$?" -ne 0 ]]; then
        echo -e "❌\ninstall yq"
        sudo apt-get install jq -y
    else
        echo ✅🆗
    fi

    # Installs helm
    if ! command -v helm &> /dev/null; then
        echo "❌ Helm not found. Installing..."
        curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash
    fi
    if command -v helm &> /dev/null; then
        echo "✅🆗 Helm is already installed: $(helm version --short)"
    else
        echo "❌ Helm could not be installed"
    fi

    if ! command -v kubectl &> /dev/null; then
        echo "❌ kubectl not found. Installing latest version..."
        curl -LO "https://dl.k8s.io/release/$(curl -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
        chmod +x kubectl
        sudo mv kubectl /usr/local/bin/
    fi
    if command -v kubectl &> /dev/null; then
        echo "✅🆗 kubectl is already installed: $(kubectl version --client --short)"
    fi
}

#---------------------------------------------- main program ------------------------
[[ "$#" -gt 0 ]] && DEVTOOLS_FOLDERNAME=$1; shift || DEVTOOLS_FOLDERNAME="devopTools";
[[ "$#" -gt 0 ]] && DEVTOOLS_FOLDERBASE=$1; shift || DEVTOOLS_FOLDERBASE="$(pwd)";
installDevopTools "$DEVTOOLS_FOLDERNAME" "$DEVTOOLS_FOLDERBASE"