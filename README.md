# CloudFoxable

Use Terraform to create your own vulnerable by design AWS penetration testing playground

<image>

CloudFox helps penetration testers and security professionals find exploitable attack paths in cloud infrastructure. However, what if you want to find and exploit services not yet present in your current environment? What if you lack access to an enterprise AWS environment? 

Enter CloudFoxable, an intentionally vulnerable AWS environment created specifically to showcase CloudFox’s capabilities and help you find latent attack paths more effectively. Drawing inspiration from CloudGoat, flaws.cloud, and Metasploitable, CloudFoxable provides a wide array of flags and attack paths in a CTF format. 

Similar to CloudGoat and IAM-Vulnerable, CloudFoxable deploys intentionally vulnerable AWS resources in a user-managed playground account, for users to learn about identifying and exploiting cloud vulnerabilities.


Total number of challenges:    X
Total number of flags:         X


# Table of Contents

TBD

# Quick Start

1. **Select or create an AWS account** - Do NOT use an account that has any production resources or sensitive data.
2. **Complete the first challenge** - Head over to [cloudfoxable.bishopfox.com](https://cloudfoxable.bishopfox.com) to get started. The first challenge ["Setup, deploy, get first flag!"](https://cloudfoxable.bishopfox.com/challenges#Setup,%20deploy,%20get%20first%20flag!-4) walks you through deploying CloudFoxable to your playground account. 
4. **(Optional) Register an account** - Track your progress and compete with others by creating an account at [cloudfoxable.bishopfox.com](https://cloudfoxable.bishopfox.com). Note: You can do all of the challenges without an account. 


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