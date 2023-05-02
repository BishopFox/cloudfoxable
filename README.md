# CloudFoxable

Use Terraform to create your own vulnerable by design AWS penetration testing playground

![image](https://user-images.githubusercontent.com/46326948/235528856-64ffddb0-b1a0-4eda-bb88-6c0bc95d936b.png)

CloudFox helps penetration testers and security professionals find exploitable attack paths in cloud infrastructure. However, what if you want to find and exploit services not yet present in your current environment? What if you lack access to an enterprise AWS environment? 

Enter CloudFoxable, an intentionally vulnerable AWS environment created specifically to showcase CloudFox’s capabilities and help you find latent attack paths more effectively. Drawing inspiration from CloudGoat, flaws.cloud, and Metasploitable, CloudFoxable provides a wide array of flags and attack paths in a CTF format. 

Similar to CloudGoat and IAM-Vulnerable, CloudFoxable deploys intentionally vulnerable AWS resources in a user-managed playground account, for users to learn about identifying and exploiting cloud vulnerabilities.


* Total number of challenges:    X
* Total number of flags:         X


# Table of Contents

TBD

# Quick Start

1. **Select or create an AWS account** - Do NOT use an account that has any production resources or sensitive data.
2. **Complete the first challenge** - Head over to [cloudfoxable.bishopfox.com](https://cloudfoxable.bishopfox.com) to get started. The first challenge ["Setup, deploy, get first flag!"](https://cloudfoxable.bishopfox.com/challenges#Setup,%20deploy,%20get%20first%20flag!-4) walks you through deploying CloudFoxable to your playground account. 
3. **(Optional) Register an account** - Track your progress and compete with others by creating an account at [cloudfoxable.bishopfox.com](https://cloudfoxable.bishopfox.com). Note: You can do all of the challenges without an account. 
4. Install [CloudFox](https://github.com/BishopFox/cloudfox), [Pmapper](https://github.com/nccgroup/PMapper), [Pacu](https://github.com/RhinoSecurityLabs/pacu) and any other AWS Cloud Penetration Testing tools you like to use. 

 


# Deployment Instructions
This instructions can also be found in the first challenge ["Setup, deploy, get first flag!"](https://cloudfoxable.bishopfox.com/challenges#Setup,%20deploy,%20get%20first%20flag!-4)

1. Select or create an AWS account. (Do NOT use an account that has any production resources or sensitive data!)
1. [Create a non-root user with administrative access](https://https://docs.aws.amazon.com/IAM/latest/UserGuide/getting-started_create-admin-group.html) that you will use when running Terraform.
2. [Create an access key for that user](https://https://docs.aws.amazon.com/IAM/latest/UserGuide/id_credentials_access-keys.html).
3. [Install the AWS CLI](https://https://docs.aws.amazon.com/cli/latest/userguide/install-cliv2.html).
4. [Configure your AWS CLI](https://https://docs.aws.amazon.com/cli/latest/userguide/cli-configure-quickstart.html) with your newly created admin user as the default profile.
5. Confirm your CLI is working as expected by executing `aws sts get-caller-identity`.
6. [Install the Terraform binary ](https://https://www.terraform.io/downloads.html)and add the binary location to your path.
7. `git clone https://github.com/BishopFox/cloudfoxable`
8. `cd cloudfoxable/aws`
9. `cp terraform.tfvars.example terraform.tfvars`  
10. `terraform init`
11. Edit `terraform.tfvars` and set set the AWS profile you'd like to use: `aws_local_profile = "YOUR_PROFILE"`
12. (Optional) `terraform plan`
13. `terraform apply`


# A Modular Approach

Similar to IAM-Vulnerable, some challenges are enabled by default (the ones that have little or no cost implications), and others are disabled by default (the ones that incur cost if deployed). This way, you can enable specific modules as needed. The mechanism for enabling/disabling challenges is a little different than IAM-Vulnerable though. 

Within cloudfoxable.bishopfox.com, each challenge will tell you if you need to make any terraform changes (aka deploy something) to complete the challenge. The way you do this is to edit terraform.tfvars and update the enabled flag from false to true as needed. 

Here's an example: 

```
############################
# Enabled/Disabled Challenges
############################

# Always on (Low or No cost)
challenge_foo_enabled = true
challenge_bar_enabled = true
challenge_alice_enabled = true

# Enable as needed (These challenges incur noticeable cost)
challenge_bob_enabled = false
challenge_mallory_enabled = false
```

To enable the mallory challenge, you would simply update the following line:
```
challenge_mallory_enabled = true
```

After you enable a challenge, you will need to re-run terraform apply:
```
terraform apply
```

You have now deployed the mallory challenge.


**Cleanup**

Whenever you want to remove all of the CloudFoxable-created resources, you can run these commands:
1. `cd cloudfoxable/aws`
1. `terraform destroy`
