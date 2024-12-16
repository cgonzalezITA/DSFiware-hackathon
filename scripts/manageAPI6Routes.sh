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
            \t [ -rid | --routeId ] <ROUTE_ID>: Mandatory when more than one route is registered with the same name,uri and host\n
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
    "ROUTE_WELLKNOWN_DID_WEB_fiwaredsc_consumer_ita_es": {
        "uri": "/.well-known/did.json",
        "name": "vcissuer-consumer-Did.web",
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
        "name": "vcissuer-consumer-ita_es",
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
    "ROUTE_CONSUMER_KEYCLOAK_fiwaredsc_consumer_local": {
        "name": "vcissuer-consumer-local",
        "uri": "/*",
        "host": "fiwaredsc-consumer.local",
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
                "consumer-keycloak.consumer.svc.cluster.local:80": 1
            }
        }
    },



    "ROUTE_WELLKNOWN_JWKS_fiwaredsc_vcverifier_local": {
        "uri": "/.well-known/jwks*",
        "name": "provider-verifier-JWKS",
        "host": "fiwaredsc-provider.local",
        "methods": ["GET", "POST"],
        "upstream": {
            "type": "roundrobin",
            "nodes": {
                "verifier.provider.svc.cluster.local:3000": 1
            }
        }
    },
    "ROUTE_WELLKNOWN_OIDC_fiwaredsc_vcverifier_local": {
        "uri": "/.well-known/*",
        "name": "provider-verifier-OIDC",
        "host": "fiwaredsc-provider.local",
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
    "ROUTE_WELLKNOWN_OIDC_Service_fiwaredsc_vcverifier_local": {
        "name": "provider-service-OIDC",
        "uri": "/services/hackathon-service/*",
        "host": "fiwaredsc-provider.local",
        "methods": ["GET", "POST"],
        "upstream": {
            "type": "roundrobin",
            "nodes": {
                "verifier.provider.svc.cluster.local:3000": 1
            }
        },
        "plugins": {
            "proxy-rewrite": {
                "regex_uri": ["^/services/hackathon-service/(.*)", "/services/hackathon-service/\$1"]
            }
        }
    },
    "ROUTE_OIDC_TOKEN_fiwaredsc_vcverifier_local": {
        "uri": "/services/hackathon-service/token",
        "name": "provider-verifier-OIDC-Token",
        "host": "fiwaredsc-provider.local",
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
    "ROUTE_PROVIDER_SERVICE_fiwaredsc_provider_local_0auth": {
        "uri": "/services/hackathon-service/ngsi-ld/*",
        "name": "SERVICE_fiwaredsc_provider_local",
        "host": "fiwaredsc-provider.local",
        "methods": [ "GET" ],
        "upstream": {
            "type": "roundrobin",
            "scheme": "http",
            "nodes": {
                "ds-scorpio.service.svc.cluster.local:9090": 1
            }
        },
        "plugins": {
            "proxy-rewrite": {
                "regex_uri": ["^/services/hackathon-service/ngsi-ld/(.*)", "/ngsi-ld/\$1"]
            }
        }
    },
    "ROUTE_PROVIDER_SERVICE_fiwaredsc_provider_local_authentication": {
        "uri": "/services/hackathon-service/ngsi-ld/*",
        "name": "SERVICE_fiwaredsc_provider_local",
        "host": "fiwaredsc-provider.local",
        "methods": ["GET", "POST", "PUT", "HEAD", "CONNECT", "OPTIONS", "PATCH", "DELETE"],
        "upstream": {
            "type": "roundrobin",
            "scheme": "http",
            "nodes": {
                "ds-scorpio.service.svc.cluster.local:9090": 1
            }
        },
        "plugins": {
            "proxy-rewrite": {
                "regex_uri": ["^/services/hackathon-service/ngsi-ld/(.*)", "/ngsi-ld/\$1"]
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
    },
    

    "ROUTE_PROVIDER_fiwaredsc_provider_ita_es_dataSpaceConfiguration": {
        "uri": "/.well-known/data-space-configuration",
        "name": "fiwaredsc_provider_dataSpaceConfiguration",
        "host": "fiwaredsc-provider.ita.es",
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
    "ROUTE_WELLKNOWN_OIDC_fiwaredsc_vcverifier_ita_es": {
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
                "bearer_only": "true",
                "use_jwks": "true",
                "client_id": "hackathon-service",
                "client_secret": "unused",
                "ssl_verify": "false",
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

    "ROUTE_PROVIDER_SERVICE_fiwaredsc_provider_local_authentication"='{
      "info": [
            "# https://fiwaredsc-provider.local/services/hackathon-service/ngsi-ld/v1/entities?type=Order",
            "# https://apisix.apache.org/docs/apisix/plugins/openid-connect/"
        ]
    },
    "ROUTE_PROVIDER_fiwaredsc_provider_local_dataSpaceConfiguration": {
        "info": [
            "# https://fiwaredsc-provider.local/.well-known/data-space-configuration"
        ]
	},
    "ROUTE_PROVIDER_fiwaredsc_provider_ita_es_dataSpaceConfiguration": {
        "info": [
            "# https://fiwaredsc-provider.ita.es/.well-known/data-space-configuration"
        ]
	},
    "ROUTE_WELLKNOWN_DID_WEB_fiwaredsc_consumer_ita_es": {
        "info": "# https://fiwaredsc-consumer.ita.es/.well-known/did.json"
	},
    "ROUTE_CONSUMER_KEYCLOAK_fiwaredsc_consumer_ita_es": {
        "info": "# https://fiwaredsc-consumer.ita.es/"
	},
    "ROUTE_WALLET_fiwaredsc_wallet_ita_es": {
        "info": "# https://fiwaredsc-wallet.ita.es/"
	},
    "ROUTE_WELLKNOWN_OIDC_fiwaredsc_vcverifier_ita_es": {
        "info": [
            "# https://fiwaredsc-provider.ita.es/.well-known/openid-configuration"
        ]
	},
    "ROUTE_WELLKNOWN_OIDC_Service_fiwaredsc_vcverifier_local": {
        "info": [
            "# https://fiwaredsc-provider.local/services/hackathon-service/.well-known/openid-configuration"
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
    if [[ "$ACTION" =~ ^(insert)$ ]]; then
      echo -e $(help "ERROR: Route is mandatory for action $ACTION. Must be one of [$ROUTE_NAMES]")
      [ "$CALLMODE" == "executed" ] && exit -1 || return -1; 
    elif [[ "$ACTION" =~ ^(update|delete)$ ]] && [ ${#ROUTE_ID} -eq 0 ]; then
      echo -e $(help "ERROR: One of ROUTE or ROUTE_ID must be provided for action $ACTION. The ROUTE must be one of [$ROUTE_NAMES]")
      [ "$CALLMODE" == "executed" ] && exit -1 || return -1; 
    fi
  elif  [ ${#ROUTE_ID} -eq 0 ]; then
    ROUTE_JSON=$(echo "$ROUTES" | jq -r --arg key "$ROUTE" '.[$key]')
    if [ ${#ROUTE_JSON} -eq 0 ]; then
      echo -e $(help "ERROR: No route with name $ROUTE has been found. Must be one of [$ROUTE_NAMES]")
      [ "$CALLMODE" == "executed" ] && exit -1 || return -1; 
    fi
    ROUTE_NAME=$(echo $ROUTE_JSON | jq -e -r '.name // ""' 2>/dev/null || echo "")
    ROUTE_URI=$(echo $ROUTE_JSON | jq -e -r '.uri // ""' 2>/dev/null || echo "")
    ROUTE_HOST=$(echo $ROUTE_JSON | jq -e -r '.host // ""' 2>/dev/null || echo "")
    if [[ $ACTION =~ ^(insert|update|delete)$ ]]; then
        # .value.name; .value.host
        APISIXROUTES=$(curl -s -k https://$IP_APISIXCONTROL:9180/apisix/admin/routes -H "X-API-KEY:$ADMINTOKEN") 
        # Search the ID
        # ROUTE_ID=$(echo $APISIXROUTES | jq -r --arg NAME "$ROUTE_NAME" --arg HOST "$ROUTE_HOST" --arg URI "$ROUTE_URI" \
        #     '.list[] | select(.name == $NAME and .host == $HOST and .uri == $URI) | .id // ""')
        if [[ ${#ROUTE_NAME} -gt 0 ]]; then
            ROUTE_ID=$(echo $APISIXROUTES | jq -c --arg NAME "$ROUTE_NAME" \
                '.list[] | select(.value.name == $NAME) | .value.id // ""')
        fi
        if [ ${#ROUTE_ID} -eq 0 ]; then
            if [[ ${#ROUTE_NAME} -gt 0 ]] && [[ ${#ROUTE_URI} -gt 0 ]] && [[ ${#ROUTE_HOST} -gt 0 ]]; then
                ROUTE_ID=$(echo $APISIXROUTES | jq -c --arg NAME "$ROUTE_NAME" --arg URI "$ROUTE_URI" --arg HOST "$ROUTE_HOST" \
                    '.list[] | select(.value.name == $NAME and .value.uri == $URI and .value.host == $HOST) | .value.id // ""')
            elif [[ ${#ROUTE_NAME} -gt 0 ]] && ${#ROUTE_URI} -gt 0 ]]; then
                ROUTE_ID=$(echo $APISIXROUTES | jq -c --arg NAME "$ROUTE_NAME" --arg URI "$ROUTE_URI" \
                    '.list[] | select(.value.name == $NAME and .value.uri == $URI) | .value.id // ""')
            else
                echo -e $(help "ERROR: Route $ROUTE must contain at least a name and a uri; optional a host")
                [ "$CALLMODE" == "executed" ] && exit -1 || return -1; 
            fi
        fi
        if [ ${#ROUTE_ID} -eq 0 ]; then
            if [[ $ACTION =~ ^(update|delete)$ ]]; then
                echo -e $(help "ERROR: Route $ROUTE not found at the list of registered apisix routes for action $ACTION.")
                [ "$CALLMODE" == "executed" ] && exit -1 || return -1; 
            fi
        else
            [[ "$ACTION" == "insert" ]] && ACTION="update";
            ROUTE_ID=$(echo $ROUTE_ID | sed "s|\"||g"); # Removes "
            if [[ "$ROUTE_ID" == *" "* ]]; then
                echo -e $(help "ERROR: More than one route has been detected. Please use -rid ROUTE_ID. The possible values are [$ROUTE_ID]")
                [ "$CALLMODE" == "executed" ] && exit -1 || return -1; 
            fi
        fi
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
      curl -s -k https://$IP_APISIXCONTROL:9180/apisix/admin/routes -H "X-API-KEY:$ADMINTOKEN" | jq .
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