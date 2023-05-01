❯ cloudfox aws -p cflab secrets -v2


❯ cat cloudfox-output/aws/cloudfoxable/loot/pull-secrets-commands.txt

❯ export profile=cloudfoxable
❯ aws --profile $profile --region us-west-2 ssm get-parameter --with-decryption --name /cloudfoxable/flag/its-a-secret