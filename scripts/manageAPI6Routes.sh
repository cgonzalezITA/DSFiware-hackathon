#!/bin/bash
#********************************************************************************
# DevopsTools
# Version: 1.0.0 
# Copyright (c) 2024 Instituto Tecnologico de Aragon (www.ita.es)
# Date: October 2024
# Authors: 
#          Carlos Gonzalez Muñoz                    cgonzalez@ita.es
# All rights reserved 
#********************************************************************************
############################
## Variable Initialization #
############################
SCRIPTNAME=$BASH_SOURCE
if [ "$0" == "$BASH_SOURCE" ]; then CALLMODE="executed"; else CALLMODE="sourced"; fi
BASEDIR=$(dirname "$SCRIPTNAME")


# ACTION: One of [ info | list | insert* | delete | update ]
ACTION=""
# [ -r | --route ] ROUTE: Mandatory for insert and update. ENVVAR NAME of the route to execute the action on. It has to be defined inside the manageAPI6Routes.sh
ROUTE=""
# [ -rid | --routeId ] ROUTE_ID: Mandatory for delete and update
ROUTE_ID=""

unset ROUTE_JSON;
#############################
## Functions               ##
#############################
function help() {
    if test "$#" -ge 1; then
        HELP="${1}\n"     
    fi
    HELP="$HELP\nHELP: USAGE: $SCRIPTNAME [optArgs] <ACTION> \n
            \t-h: Show help info \n
            \t [ -r | --route ] <ROUTE>: Mandatory for insert and update. ENVVAR NAME of the route to execute the action on. It has to be defined inside this script \n
            \t [ -rid | --routeId ] <ROUTE_ID>: Mandatory for delete and update\n
            \t <ACTION>: One of [ info | list | insert* | delete | update ] "
    echo $HELP
}

##############################
## Main code                ##
##############################

# getopts arguments
while true; do
    [[ "$#" -eq 0 ]] && break;
    case "$1" in
        -h | --help ) 
            echo -e $(help);
            [ "$CALLMODE" == "executed" ] && exit -1 || return -1; 
            break ;;
        -r | --route ) 
            # \t [ -r | --route ] <ROUTE>: Mandatory for insert and update. ENVVAR NAME of the route to execute the action on. It has to be defined inside this script \n
            ROUTE=$2
            shift ; shift ;;
        -rid | --routeId ) 
            # \t [ -rid | --routeId ] <ROUTE_ID>: Mandatory for delete and update\n
            ROUTE_ID=$2            
            shift ; shift ;;
        * ) 
            if [[ $1 == -* ]]; then
                echo -e $(help "ERROR: Unknown parameter [$1]");
                [ "$CALLMODE" == "executed" ] && exit -1 || return -1; 
            elif test "${#ACTION}" -eq 0; then
              ACTION=$1              
            fi
            shift;;
    esac
done

if test "${#ACTION}" -eq 0; then
    ACTION="list"
fi

##################### Main Code ##############
shopt -s expand_aliases
[ -f ~/.bash_aliases ] && source ~/.bash_aliases;
ADMINTOKEN=$(kSecret-show -f admin-token -n apisix plane-api -v)
IP_APISIXCONTROL=$(kGet -a svc control- -o yaml -v -n apisix | yq eval '.spec.clusterIP' -)

ROUTES=$(cat <<EOF
{
    "ROUTE_DEMO_JSON": {
        "name": "hello",
        "uri": "/",
        "host": "fiwaredsc-consumer.local",
        "methods": [
            "GET"
        ],
        "upstream": {
            "type": "roundrobin",
            "nodes": {
                "echo-svc:8080": 1
            }
        },
        "plugins": {
            "proxy-rewrite": {
                "uri": "/"
            }
        }
    },
    "ROUTE_API6DASHBOARD_JSON": {
        "name": "api6Dashboard",
        "uri": "/*",
        "host": "fiwaredsc-api6dashboard.local",
        "methods": [
            "GET",
            "POST",
            "PUT",
            "HEAD",
            "CONNECT",
            "OPTIONS",
            "PATCH",
            "DELETE"
        ],
        "upstream": {
            "type": "roundrobin",
            "nodes": {
                "apisix-dashboard:80": 1
            }
        }
    },
    "ROUTE_TIR_JSON": {
        "name": "TIR",
        "uri": "/*",
        "host": "fiwaredsc-trustanchor.local",
        "methods": [
            "GET",
            "POST",
            "PUT"
        ],
        "upstream": {
            "type": "roundrobin",
            "nodes": {
                "tir.trust-anchor.svc.cluster.local:8080": 1
            }
        }
    },
    "ROUTE_TIRITA_JSON": {
        "name": "TIRITA",
        "uri": "/*",
        "host": "fiwaredsc-tir.ita.es",
        "methods": [
            "GET",
            "POST",
            "PUT"
        ],
        "upstream": {
            "type": "roundrobin",
            "nodes": {
                "tir.trust-anchor.svc.cluster.local:8080": 1
            }
        }
    },
    "ROUTE_DID_WEB_fiwaredsc_consumer_ita_es": {
        "uri": "/.well-known/did.json",
        "name": "Did.web",
        "host": "fiwaredsc-consumer.ita.es",
        "methods": [
            "GET"
        ],
        "upstream": {
            "type": "roundrobin",
            "nodes": {
                "did.consumer.svc.cluster.local:3000": 1
            }
        },
        "plugins": {
            "proxy-rewrite": {
                "uri": "/did-material/did.json"
            }
        }
    },
    "ROUTE_CONSUMER_KEYCLOAK_fiwaredsc_consumer_ita_es": {
        "uri": "/*",
        "name": "consumer",
        "host": "fiwaredsc-consumer.ita.es",
        "methods": [
            "GET",
            "POST",
            "PUT",
            "HEAD",
            "CONNECT",
            "OPTIONS",
            "PATCH",
            "DELETE"
        ],
        "upstream": {
            "type": "roundrobin",
            "scheme": "https",
            "nodes": {
                "consumer-keycloak.consumer.svc.cluster.local:443": 1
            }
        }
    },
    "ROUTE_WALLET_fiwaredsc_wallet_ita_es": {
        "uri": "/*",
        "name": "Wallet",
        "methods": [
            "GET",
            "POST",
            "PUT",
            "HEAD",
            "CONNECT",
            "OPTIONS",
            "PATCH",
            "DELETE"
        ],
        "host": "fiwaredsc-wallet.ita.es",
        "upstream": {
            "nodes": [
                {
                    "host": "wallet.consumer.svc.cluster.local",
                    "port": 3000,
                    "weight": 1
                }
            ],
            "timeout": {
                "connect": 6,
                "send": 6,
                "read": 6
            },
            "type": "roundrobin",
            "scheme": "http",
            "pass_host": "pass",
            "keepalive_pool": {
                "idle_timeout": 60,
                "requests": 1000,
                "size": 320
            }
        },
        "status": 1
    },
    "ROUTE_OIDC_fiwaredsc_vcverifier_ita_es": {
        "uri": "/.well-known/*",
        "name": "OIDC",
        "host": "fiwaredsc-provider.ita.es",
        "methods": [
            "GET"
        ],
        "upstream": {
            "type": "roundrobin",
            "nodes": {
                "verifier.provider.svc.cluster.local:3000": 1
            }
        },
        "plugins": {
            "proxy-rewrite": {
                "regex_uri": [
                    "^/.well-known/(.*)",
                    "/services/hackathon-service/.well-known/\$1"
                ]
            }
        }
    },
    "ROUTE_OIDC_TOKEN_fiwaredsc_vcverifier_ita_es": {
        "uri": "/services/hackathon-service/token",
        "name": "OIDC-Token",
        "host": "fiwaredsc-provider.ita.es",
        "methods": [
            "GET",
            "POST"
        ],
        "upstream": {
            "type": "roundrobin",
            "nodes": {
                "verifier.provider.svc.cluster.local:3000": 1
            }
        },
        "plugins": {
            "proxy-rewrite": {
                "uri": "/services/hackathon-service/token"
            }
        }
    },
    "ROUTE_PROVIDER_SERVICE_fiwaredsc_providerWithoutAutho_ita_es": {
        "uri": "/ngsi-ld/*",
        "name": "service",
        "host": "fiwaredsc-provider.ita.es",
        "methods": [
            "GET",
            "POST",
            "PUT",
            "HEAD",
            "CONNECT",
            "OPTIONS",
            "PATCH",
            "DELETE"
        ],
        "upstream": {
            "type": "roundrobin",
            "scheme": "http",
            "nodes": {
                "ds-scorpio.service.svc.cluster.local:9090": 1
            }
        },
        "plugins": {
            "proxy-rewrite": {
                "regex_uri": [
                    "^/ngsi-ld/(.*)",
                    "/ngsi-ld/\$1"
                ]
            }
        }
    },
    "ROUTE_PROVIDER_SERVICE_fiwaredsc_provider_ita_es": {
        "uri": "/ngsi-ld/*",
        "name": "service",
        "host": "fiwaredsc-provider.ita.es",
        "methods": [
            "GET",
            "POST",
            "PUT",
            "HEAD",
            "CONNECT",
            "OPTIONS",
            "PATCH",
            "DELETE"
        ],
        "upstream": {
            "type": "roundrobin",
            "scheme": "http",
            "nodes": {
                "ds-scorpio.service.svc.cluster.local:9090": 1
            }
        },
        "plugins": {
            "proxy-rewrite": {
                "regex_uri": [
                    "^/ngsi-ld/(.*)",
                    "/ngsi-ld/\$1"
                ]
            },
            "openid-connect": {
                "bearer_only": true,
                "use_jwks": true,
                "client_id": "hackathon-service",
                "client_secret": "unused",
                "ssl_verify": false,
                "discovery": "http://verifier.provider.svc.cluster.local:3000/services/hackathon-service/.well-known/openid-configuration"
            }
        }
    }
}
EOF
)
# Info routes
INFO_ROUTES=$(cat <<EOF
{
    "ROUTE_DID_WEB_fiwaredsc_consumer_ita_es": {
        "info": "# https://fiwaredsc-consumer.ita.es/.well-known/did.json"
	},
    "ROUTE_CONSUMER_KEYCLOAK_fiwaredsc_consumer_ita_es": {
        "info": "# https://fiwaredsc-consumer.ita.es/"
	},
    "ROUTE_WALLET_fiwaredsc_wallet_ita_es": {
        "info": "# https://fiwaredsc-wallet.ita.es/"
	},
    "ROUTE_OIDC_fiwaredsc_vcverifier_ita_es": {
        "info": [
            "# https://fiwaredsc-provider.ita.es/.well-known/openid-configuration",
            "# https://fiwaredsc-provider.ita.es/.well-known/jwks"
        ]
	},
    "ROUTE_OIDC_TOKEN_fiwaredsc_vcverifier_ita_es": {
        "info": [
            "# https://fiwaredsc-provider.ita.es/services/hackathon-service/token"
        ]
	},
    "ROUTE_PROVIDER_SERVICE_fiwaredsc_providerWithoutAutho_ita_es": {
        "info": [
            "# https://fiwaredsc-provider.ita.es/ngsi-ld/"
        ]
	},
    "ROUTE_PROVIDER_SERVICE_fiwaredsc_provider_ita_es": {
        "info": [
            "# https://fiwaredsc-provider.ita.es/ngsi-ld/"
        ],
        "plugins": {
            "openid-connect": {
                "info": "# https://apisix.apache.org/docs/apisix/plugins/openid-connect/"
			}
		}
	}
}
EOF
)


# echo "$ROUTES" | jq .
if [[ "$ACTION" =~ ^(list|info|insert|update|delete)$ ]]; then  
  ROUTE_NAMES=$(echo "$ROUTES" | jq -r 'keys[]')
  if [ ${#ROUTE} -eq 0 ]; then
    if [[ "$ACTION" =~ ^(insert|update)$ ]]; then
      echo -e $(help "ERROR: Route is mandatory for action $ACTION. Must be one of [$ROUTE_NAMES]")
      [ "$CALLMODE" == "executed" ] && exit -1 || return -1; 
    fi
  else 
    ROUTE_JSON=$(echo "$ROUTES" | jq -r --arg key "$ROUTE" '.[$key]')
    if [ ${#ROUTE_JSON} -eq 0 ]; then
      echo -e $(help "ERROR: No route with name $ROUTE has been found. Must be one of [$ROUTE_NAMES]")
      [ "$CALLMODE" == "executed" ] && exit -1 || return -1; 
    fi
  fi  
  if [[ $ACTION =~ ^(delete|update)$ ]]; then
    if [ ${#ROUTE_ID} -eq 0 ]; then
      echo -e $(help "ERROR: RouteID is mandatory for action $ACTION. Must match the ID of the route (see the list to find it)")
      [ "$CALLMODE" == "executed" ] && exit -1 || return -1; 
    fi
  fi
  if [[ $ACTION == "info" ]]; then
    if [ ${#ROUTE_JSON} -eq 0 ]; then
      echo "# Info of routes available at this script:"
      echo "ROUTES=[$ROUTE_NAMES]"
    else
      echo "# Info of route $ROUTE:"
      echo "ROUTE[\"$ROUTE\"]=$ROUTE_JSON"
    fi
  elif [[ "$ACTION" == "list" ]]; then
    if [ ${#ROUTE_ID} -eq 0 ]; then
      echo "# Get list of api6 routes"
      curl -s -k https://$IP_APISIXCONTROL:9180/apisix/admin/routes -H "X-API-KEY:$ADMINTOKEN"
    else
      echo "# Get details of api6 route $ROUTE_ID"
      curl -s -k https://$IP_APISIXCONTROL:9180/apisix/admin/routes/$ROUTE_ID -H "X-API-KEY:$ADMINTOKEN"
    fi
  elif [[ $ACTION == "insert" ]]; then
    echo "# Insert api6 route $ROUTE"
    curl -s -i -X POST -k https://$IP_APISIXCONTROL:9180/apisix/admin/routes -H "X-API-KEY:$ADMINTOKEN" \
      -d "$ROUTE_JSON"
  elif [[ $ACTION == "update" ]]; then
    echo "# Update api6 route $ROUTE with ID=$ROUTE_ID"
    curl -s -i -X PUT -k https://$IP_APISIXCONTROL:9180/apisix/admin/routes/$ROUTE_ID \
        -H "X-API-KEY:$ADMINTOKEN" \
        -d "$ROUTE_JSON"
  elif [[ $ACTION == "delete" ]]; then
    echo "# DELETE api6 route with ID=$ROUTE_ID"
    curl -s -i -X DELETE -k -H "X-API-KEY:$ADMINTOKEN" \
      https://$IP_APISIXCONTROL:9180/apisix/admin/routes/$ROUTE_ID
  fi
else
  echo -e $(help "ERROR: Action $ACTION is not recognized. Must be one of [ info | list | insert | update | delete ]")
fi