# Fixed

Contributed by: Joseph Barcia (Bishop Fox)
category: 'Assumed Breach: Developer'
description: 
  **Overview**

  - **Author:** Joseph Barcia (Bishop Fox)
  - **Default state:** Disabled
  - **Estimated Cost:** $0.00/month
  - **Starting Point:** `arn:aws:iam::ACCOUNT_ID:role/retest`

Requirements:
  - AWS cli w/ default profile configured for Cloudfoxable
  - Docker

  **Challenge Details**

  In Lewis Carroll's Alice's Adventures in Wonderland, the "rabbit hole" is the literal entrance to Wonderland, which Alice falls down after chasing the White Rabbit. This fall leads her to a bizarre and surreal world where the laws of physics and logic don't apply.

  In total, there are five flags, can you find them all? Becareful of the false positives and the rabbit holes. Have fun exploiting and hopefully you learn something new.

  FLAG{FIXED:FLAG1_FLAG2_FLAG3_FLAG4_FLAG5}

  **Cleanup Tasks**

  Manually delete any additional resources you have created then execute the following: 

  ```
  unset AWS_ACCESS_KEY_ID
  unset AWS_SECRET_ACCESS_KEY
  unset AWS_SESSION_TOKEN

  repos=("webapp" "database" "test")
  for repo in "${repos[@]}"; do
    echo $repo
    aws ecr batch-delete-image --region `terraform output -raw CTF_Region` \
      --repository-name $repo \
      --image-ids "$(aws ecr list-images --region `terraform output -raw CTF_Region` --repository-name $repo --query 'imageIds[*]' --output json)" || true
  done

  docker images | grep "`terraform output -raw CTF_Account`.dkr.ecr.`terraform output -raw CTF_Region`.amazonaws.com" | awk '{print $3}' | while read image_id; do
    docker rmi -f "$image_id"
  done
  
  terraform destroy --auto-approve 

  # NOTE: Sometime terraform will try to delete roles before removing attached policies, just rerun destroy command to fully cleanup
  terraform destroy --auto-approve 
  ```

Value: 400

hints:
- "The hurrier I go, the behinder I get"
