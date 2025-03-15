![cloudfoxable-single-flag](https://github.com/BishopFox/cloudfoxable/assets/46326948/d0c20a83-0851-4b93-8e57-d6c43edbd506)

Start Hacking: [CloudFoxable](https://cloudfoxable.bishopfox.com)

Read the blog for more details: [Introducing CloudFoxable: A Gamified Cloud Hacking Sandbox](https://bishopfox.com/blog/cloudfoxable-gamified-cloud-hacking-sandbox)

# Background

CloudFox helps penetration testers and security professionals find exploitable attack paths in cloud infrastructure. However, what if you want to find and exploit services not yet present in your current environment? What if you lack access to an enterprise AWS environment? 

Enter CloudFoxable, an intentionally vulnerable AWS environment created specifically to showcase CloudFox’s capabilities and help you find latent attack paths more effectively. Drawing inspiration from [CloudGoat](https://github.com/RhinoSecurityLabs/cloudgoat), [flaws.cloud](https://flaws.cloud/), [flaws2.cloud](https://flaws2.cloud/) and [Metasploitable 1-3](https://github.com/rapid7/metasploitable3), CloudFoxable provides a wide array of flags and attack paths in a CTF format. 

Similar to [CloudGoat](https://github.com/RhinoSecurityLabs/cloudgoat) and [IAM-Vulnerable](https://github.com/BishopFox/iam-vulnerable), CloudFoxable deploys intentionally vulnerable AWS resources in a user-managed playground account, for users to learn about identifying and exploiting cloud vulnerabilities. However, more like [flaws.cloud](https://flaws.cloud/), your experience is more web based and guided. 


* Total number of challenges:    18

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

# Enable as needed (These challenges incur cost)
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


# Build with Docker

If you're using **Windows**, you might encounter issues when deploying some of the challenges due to platform-specific limitations. To avoid this, a Dockerfile is provided to help you build and run the application in a consistent environment across different systems.

<details>
    <summary>Click to expand</summary>

## Clone the Repository

Start by cloning the repository to your local machine:

```bash
git clone https://github.com/BishopFox/cloudfoxable.git
cd cloudfoxable
```

## Build the Docker Image
Once you have cloned the repository, build the Docker image with the following command. This will ensure that you are using a fresh build without any cached layers:
```bash
docker build --no-cache -t cloudfoxable .
```

### Run Docker on Windows with PowerShell
If you're on Windows, use the following PowerShell command to run the Docker container. This will:
- Mount your AWS credentials file to the container for persistence.
- Mount your Terraform (state) file(s) to the container for persistence.
- Start an interactive session where you can run Terraform commands.
```pwsh
cd aws
docker run -it -v $env:USERPROFILE/.aws/credentials:/root/.aws/credentials -v ${PWD}:/cloudfoxable/aws cloudfoxable
```
</details>

# Hungry for more? 

https://github.com/iknowjason/Awesome-CloudSec-Labs


# Contributing

If you'd like to add a new challenge, here's the steps within CloudFoxable once you fork the repo: 

* `cp aws/challenges/1_challenge_template aws/challenges/challenge_name`
* Rename the challenge template folder and `challenge_name.tf` file to the name of your challenge.
* Add your terraform code
* Make a new variable in aws/variables.tf
  ```
  variable "challenge_name_enabled" {
  description = "Enable or disable challenge_name challenge (true = enabled, false = disabled)"
  type        = bool
  default     = false
  }
  ```
* Add it to the "Enabled/Disabled Challenge section in `terraform.tfvars.example`. Specify if it should be enabled by default (low/no cost), or disabled by default (costs $$)
  ```
  challenge_name_enabled = false
  ```
* Add the module to aws/main.tf
  ```
  module "challenge_challenge_name" {
    source = "./challenges/challenge-name"
    count = var.challenge_name_enabled ? 1 : 0
    aws_assume_role_arn = (var.aws_assume_role_arn != "" ? var.aws_assume_role_arn : data.aws_caller_identity.current.arn) 
    account_id = data.aws_caller_identity.current.account_id
    aws_local_profile = var.aws_local_profile
    user_ip = local.user_ip
    }
   ```
* Add the challenge name to the `enabled_challenges` local variable:
  ```
    var.challenge_name_enabled ?                   "name                      | $12/month    |" : ""
  ```







