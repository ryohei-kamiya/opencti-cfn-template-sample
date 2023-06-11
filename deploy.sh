#!/bin/bash

SCRIPT_PATH="${BASH_SOURCE:-$0}"
ABS_SCRIPT_PATH="$(realpath "${SCRIPT_PATH}")"
SCRIPTDIR=$(dirname "${ABS_SCRIPT_PATH}")
cd "$SCRIPTDIR" || exit 1;

if [ ! -f .env ]; then
  echo "[ERROR] .env is not found.";
  exit 1;
fi

# shellcheck source=/dev/null
source .env


usage () {
  echo "$1" >&2
  cat <<_EOT_ >&2

Usage:
  ./deploy.sh [-e] [-h]

Description:
  A script for deploying the stack.
  If you don't specify the -e option, it just creates a changeset and doesn't deploy it.

Options:
  -e: Execute changeset. If not specified, just create a changeset without deploying it.
  -h: Display a help message.
_EOT_
}

get_args () {
  CHANGESET_OPTION="--no-execute-changeset"
  EXIT="0"
  while getopts "eh" OPT; do
    case $OPT in
      "e")
        CHANGESET_OPTION="";
        ;;
      "h")
        usage "Help";
        ;;
      "?")
        usage "[ERROR] Undefined options.";
        EXIT=1;
        ;;
    esac
  done
  echo "$EXIT $CHANGESET_OPTION"
}

IFS=" " read -r -a args <<< "$(get_args "$@")"

EXIT="${args[0]}"
if [ "$EXIT" != "0" ]; then
  exit $EXIT;
fi

CHANGESET_OPTION="${args[1]}"

if [ -z "${AWS_PROFILE}" ]; then
  usage "[ERROR] AWS_PROFILE is requied.";
  exit 1;
fi
if [ -z "${AWS_REGION}" ]; then
  usage "[ERROR] AWS_REGION is requied.";
  exit 1;
fi
if [ -z "${STACK_PREFIX}" ]; then
  usage "[ERROR] STACK_PREFIX is required.";
  exit 1;
fi

cat <<EOF
aws cloudformation deploy \
  --stack-name "${STACK_PREFIX}-${STAGE}" ${CHANGESET_OPTION} \
  --template-file cloudformation.yml \
  --parameter-overrides \
    StackPrefix="$STACK_PREFIX" \
    Stage="$STAGE" \
    DomainName="$DOMAIN_NAME" \
    PublicHostedZoneId="$PUBLIC_HOSTED_ZONE_ID" \
    OpenCtiAdminEmail="$OPENCTI_ADMIN_EMAIL" \
    OpenCtiAdminPassword="$OPENCTI_ADMIN_PASSWORD" \
    EC2InstanceAMI="$EC2_INSTANCE_AMI" \
    EC2InstanceInstanceType="$EC2_INSTANCE_INSTANCE_TYPE" \
    EC2InstanceVolumeType="$EC2_INSTANCE_VOLUME_TYPE" \
    EC2InstanceVolumeSize=$EC2_INSTANCE_VOLUME_SIZE \
  --capabilities CAPABILITY_NAMED_IAM \
  --region "${AWS_REGION}" \
  --profile "${AWS_PROFILE}"
EOF
aws cloudformation deploy \
  --stack-name "${STACK_PREFIX}-${STAGE}" ${CHANGESET_OPTION} \
  --template-file cloudformation.yml \
  --parameter-overrides \
    StackPrefix="$STACK_PREFIX" \
    Stage="$STAGE" \
    DomainName="$DOMAIN_NAME" \
    PublicHostedZoneId="$PUBLIC_HOSTED_ZONE_ID" \
    OpenCtiAdminEmail="$OPENCTI_ADMIN_EMAIL" \
    OpenCtiAdminPassword="$OPENCTI_ADMIN_PASSWORD" \
    EC2InstanceAMI="$EC2_INSTANCE_AMI" \
    EC2InstanceInstanceType="$EC2_INSTANCE_INSTANCE_TYPE" \
    EC2InstanceVolumeType="$EC2_INSTANCE_VOLUME_TYPE" \
    EC2InstanceVolumeSize=$EC2_INSTANCE_VOLUME_SIZE \
  --capabilities CAPABILITY_NAMED_IAM \
  --region "${AWS_REGION}" \
  --profile "${AWS_PROFILE}"

cd - || exit 1;
