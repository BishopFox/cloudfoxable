#! /bin/bash
#Cleanup environment variables

unset PROFILE

if [ -n "$1" ]; then
  echo -e "\n${Green}PROFILE set to:${Color_Off} $1"
  PROFILE="--profile $1"
fi


unset AWS_ACCESS_KEY_ID
unset AWS_SECRET_ACCESS_KEY
unset AWS_SESSION_TOKEN

#Cleanup Logs
aws $PROFILE --region `terraform output -raw CTF_Region` logs describe-log-streams --log-group-name "/aws/codebuild/test-codebuild-project" --query 'logStreams[*].logStreamName' --output table | awk '{print $2}' | grep -v ^$ | while read x; do aws $PROFILE --region `terraform output -raw CTF_Region` logs delete-log-stream --log-group-name "/aws/codebuild/test-codebuild-project" --log-stream-name $x; done
aws $PROFILE --region `terraform output -raw CTF_Region` logs delete-log-group --log-group-name "/aws/codebuild/test-codebuild-project"

#Cleanup ECR
repos=("webapp" "database" "test")
for repo in "${repos[@]}"; do
echo $repo
aws $PROFILE ecr batch-delete-image --region `terraform output -raw CTF_Region` \
    --repository-name $repo \
    --image-ids "$(aws $PROFILE default ecr list-images --region `terraform output -raw CTF_Region` --repository-name $repo --query 'imageIds[*]' --output json)" || true
done

#Cleanup docker
docker images | grep "`terraform output -raw CTF_Account`.dkr.ecr.`terraform output -raw CTF_Region`.amazonaws.com" | awk '{print $3}' | while read image_id; do
docker rmi -f "$image_id"
done

#Cleanup AWS
terraform destroy --auto-approve 
# NOTE: Sometime terraform will try to delete roles before removing attached policies, just rerun destroy command to fully cleanup
terraform destroy --auto-approve 