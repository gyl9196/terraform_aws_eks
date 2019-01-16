#!/bin/bash
set -eux

init() {
  export ENVIRON=$(echo "$2" | awk '{print tolower($0)}')
  export bucket_name="niel-terraform-$ENVIRON"

  echo "bucket name is ${bucket_name}"

  eval "AWS_ACCESS_KEY=\$$2_AWS_ACCESS_KEY"
  eval "AWS_SECRET_KEY=\$$2_AWS_SECRET_KEY"
  export ACCESS_KEY=$AWS_ACCESS_KEY
  export SECRET_KEY=$AWS_SECRET_KEY

  export TF_VAR_access_key=$ACCESS_KEY
  export TF_VAR_secret_key=$SECRET_KEY

  export AWS_ACCESS_KEY_ID=${ACCESS_KEY}
  export AWS_SECRET_ACCESS_KEY=${SECRET_KEY}
}


usage() {
  local prog
  prog=$(basename "$0")
  cat <<EOF
Usage: ${prog} [action] [environment]

OPTIONS:
    action : plan or apply, which will be applied to terraform scripts
    environment: GONG for niel personal usage
EOF
}

destroy() {
  terraform destroy --var-file="env/${ENVIRON}.tfvars" --target=module.$1
}

runTerraform() {
  rm -rf .terraform
  local module=""
  if ["$#" -gt 1]; then 
    module="--target=module.$3"
    echo "module: $module"
  fi

  terraform init -backend-config="bucket = \"$bucket_name\"" -backend-config="key=\"eks/terraform.tfstate\""

  if [ "$1" == "apply" ]; then
    terraform $1 --auto-approve --var-file="env/${ENVIRON}.tfvars" $module
  else 
    terraform $1 -var-file="env/${ENVIRON}.tfvars" $module
  fi

}

main(){
  if [[ "$@" == "--help" ]]; then
      usage
      exit 0
  fi
  init "$@" 
  if [ "$1" == "destroy"  ]; then     
    destroy $3
  else 
    runTerraform "$@"
  fi 
}

main "$@"
