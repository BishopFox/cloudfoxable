#! /bin/bash
# cleanup.sh profile region
# Cleanup environment variables

unset PROFILE

if [ -n "$1" ]; then
  PROFILE="--profile $1"
else
  PROFILE="--profile default"
fi

if [ -n "$2" ]; then
  REGION="--region $2"
elif [ -n $(terraform output -raw CTF_Region) ]; then
  REGION=`terraform output -raw CTF_Region`
else
  REGION="--region us-west-2"
fi

echo -e "\nProfile set to: $PROFILE"
echo -e "Region set to: $REGION"
echo 
read -r -p "Is the Profile and Region correct? Do you want to continue? [y/N] " response
if [[ "$response" =~ ^([yY][eE][sS]|[yY])$ ]]; then

  unset AWS_ACCESS_KEY_ID
  unset AWS_SECRET_ACCESS_KEY
  unset AWS_SESSION_TOKEN

  id=$(aws sts get-caller-identity --output text --query Account $PROFILE)

  #Cleanup Logs
  aws $PROFILE $REGION logs describe-log-streams --log-group-name "/aws/codebuild/test-codebuild-project" --query 'logStreams[*].logStreamName' --output table | awk '{print $2}' | grep -v ^$ | while read x; do aws $PROFILE $REGION logs delete-log-stream --log-group-name "/aws/codebuild/test-codebuild-project" --log-stream-name $x; done
  aws $PROFILE $REGION logs delete-log-group --log-group-name "/aws/codebuild/test-codebuild-project"

  #Cleanup ECR
  repos=("webapp" "database" "test")
  for repo in "${repos[@]}"; do
    echo $repo
    aws $PROFILE ecr batch-delete-image $REGION \
        --repository-name $repo \
        --image-ids "$(aws $PROFILE default ecr list-images $REGION --repository-name $repo --query 'imageIds[*]' --output json)" || true
  done

  #Cleanup docker
  docker images | grep "$id.amazonaws.com" | awk '{print $3}' | while read image_id; do
    docker rmi -f "$image_id"
  done

  #Cleanup AWS
  terraform destroy --auto-approve 
  # NOTE: Sometime terraform will try to delete roles before removing attached policies, just rerun destroy command to fully cleanup
  terraform destroy --auto-approve 

else
  echo
  echo "Rerun the script: $(pwd)/cleanup.sh profile region"  
  echo "ex: $(pwd)/cleanup.sh default us-west-2" 
  exit

fi
