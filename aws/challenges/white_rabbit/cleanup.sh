#! /bin/bash
# cleanup.sh [profile] [region]
# Cleanup environment variables

unset PROFILE

if [ -n "$1" ]; then
  PROFILE="$1"
else
  PROFILE="default"
fi

if [ -n "$2" ]; then
  REGION="$2"
elif [ -n $(terraform output -raw CTF_Region) ]; then
  REGION=`terraform output -raw CTF_Region`
else
  REGION="us-west-2"
fi

echo -e "\nProfile set to: $PROFILE"
echo -e "Region set to: $REGION"
echo 
read -r -p "Is the profile and region correct? Do you want to continue? [y/N] " response
if [[ "$response" =~ ^([yY][eE][sS]|[yY])$ ]]; then

  unset AWS_ACCESS_KEY_ID
  unset AWS_SECRET_ACCESS_KEY
  unset AWS_SESSION_TOKEN

  id=$(aws --profile $PROFILE sts get-caller-identity --output text --query Account)

  #Cleanup Logs
  aws --profile $PROFILE --region $REGION logs describe-log-streams --log-group-name "/aws/codebuild/test-codebuild-project" --query 'logStreams[*].logStreamName' --output table | awk '{print $2}' | grep -v ^$ | while read x; do aws --profile $PROFILE --region $REGION logs delete-log-stream --log-group-name "/aws/codebuild/test-codebuild-project" --log-stream-name $x; done
  aws --profile $PROFILE --region $REGION logs delete-log-group --log-group-name "/aws/codebuild/test-codebuild-project"

  #Cleanup ECR
  repos=("webapp" "database" "test")
  for repo in "${repos[@]}"; do
    aws --profile $PROFILE --region $REGION ecr batch-delete-image \
      --repository-name $repo \
      --image-ids "$(aws --profile $PROFILE --region $REGION ecr list-images --repository-name $repo --query 'imageIds[*]' --output json)" || true
  done

  #Cleanup docker
  docker images | grep "$id.amazonaws.com" | awk '{print $3}' | while read image_id; do
    docker rmi -f "$image_id"
  done

  # Cleanup roles incase user forgot
  roles=$(aws --profile $PROFILE --region $REGION iam list-roles --query "Roles[?starts_with(RoleName, 'march_hare_encrypted')].RoleName" --output text)

  for role in $roles; do
    # Detach managed policies
    managed_policies=$(aws --profile $PROFILE --region $REGION iam list-attached-role-policies --role-name "$role" --query "AttachedPolicies[].PolicyArn" --output text)
    for policy_arn in $managed_policies; do
        aws --profile $PROFILE --region $REGION iam detach-role-policy --role-name "$role" --policy-arn "$policy_arn"
    done
    # Delete inline policies
    inline_policies=$(aws --profile $PROFILE --region $REGION iam list-role-policies --role-name "$role" --query "PolicyNames[]" --output text)
    for policy_name in $inline_policies; do
        aws --profile $PROFILE --region $REGION iam delete-role-policy --role-name "$role" --policy-name "$policy_name"
    done

    # Delete the role
    aws --profile $PROFILE --region $REGION iam delete-role --role-name "$role"
  done

  #Cleanup AWS
  terraform destroy --auto-approve 
  # NOTE: Sometime terraform will try to delete roles before removing attached policies, just rerun destroy command to fully cleanup
  terraform destroy --auto-approve 

  rm -rf challenges/white_rabbit/data/docker/webapp/*
  rm -rf challenges/white_rabbit/data/docker/database/*
  rm -rf challenges/white_rabbit/data/docker/test/*

else
  echo
  echo "Rerun the script: $(pwd)/cleanup.sh profile region"  
  echo "ex: $(pwd)/cleanup.sh default us-west-2" 
  exit

fi
