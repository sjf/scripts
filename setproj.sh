NAME="sfortune-${1}"
export CLOUDSDK_CORE_PROJECT=$NAME

# function gc_properties() {
#   CONFIG=$(gcloud config list)

#   ENDPOINT=$(gc config get-value api_endpoint_overrides/cloudfunctions)
#   PROJ=$(gc_project)
#   RES="$PROJ"
#   if [ -n "$ENDPOINT" ]; then
#     RES="$RES(T)"
#   fi
#   echo "$RES"
# }
# gc_properties

# \[\033[1;37\]