You are an expert in IaC and AWS. You have the following tasks to be performed:

* Using Terraform 1.13 HCL, come up with terraform configuration for AWS provider that creates the following resources:
    * ASG with a launch configuration using AMI **RHEL-9.5.0_HVM-20250313-x86_64-0-Hourly2-GP3**, instance type t3.medium.
    * Use the region **ap-south-1** for creating the resources.
    * An elastic IP **jenkins-host-t3** needs to be attached to the EC2.

---

VPC, subnet, internet gateway, route table and route table association are already existing. Repeat the previous steps, but this time, prompt for the names/IDs of existing resources wherever required for the creation of the ASG. Also move the new directory and files to repo **aws-repo**.

---

Now update the userdata of the EC2 referring the website <a href="https://www.jenkins.io/doc/book/installing/linux/">Jenkins setup</a> so that the following tasks are accomplished:
* Refer to the section **Red Hat Enterprise Linux and derivatives** and use the steps in **Long Term Support release**
* Figure out and include the JVM configuration for implementing **G1 garbage collection**, such that Jenkins doesn't crash on the EC2.

---

Security group is also existing, so move it to .tfvars file and update main.tf to use the existing security group.

---

Add a key pair in the launch template, and source its value from the variables file.

---

Refactor the terraform config for version 1.11.4

---

Terraform is returning the following errors:

```
+ terraform validate
╷
│ Error: Invalid combination of arguments
│ 
│   with aws_autoscaling_attachment.eip,
│   on main.tf line 97, in resource "aws_autoscaling_attachment" "eip":
│   97: resource "aws_autoscaling_attachment" "eip" {
│ 
│ "lb_target_group_arn": one of
│ `alb_target_group_arn,elb,lb_target_group_arn` must be specified
╵
╷
│ Error: Invalid combination of arguments
│ 
│   with aws_autoscaling_attachment.eip,
│   on main.tf line 97, in resource "aws_autoscaling_attachment" "eip":
│   97: resource "aws_autoscaling_attachment" "eip" {
│ 
│ "alb_target_group_arn": one of
│ `alb_target_group_arn,elb,lb_target_group_arn` must be specified
╵
╷
│ Error: Invalid combination of arguments
│ 
│   with aws_autoscaling_attachment.eip,
│   on main.tf line 97, in resource "aws_autoscaling_attachment" "eip":
│   97: resource "aws_autoscaling_attachment" "eip" {
│ 
│ "elb": one of `alb_target_group_arn,elb,lb_target_group_arn` must be
│ specified
```

Evaluate the errors and perform the necessary changes. Prompt me whenever certain inputs are required.

---

If that is the case, then is it possible to retain the ASG, then create an ALB and attach the elastic IP to the ALB instead?

---

Analyze the following error and suggest a fix for it:

```
╷
│ Error: creating ELBv2 application Load Balancer (jenkins-alb): ValidationError: At least two subnets in two different Availability Zones must be specified
│ 	status code: 400, request id: d1ebf33b-521d-4ed1-a79f-9d74216a0805
│ 
│   with aws_lb.jenkins,
│   on main.tf line 67, in resource "aws_lb" "jenkins":
│   67: resource "aws_lb" "jenkins" {
│ 
╵
```

---

Convert the configuration to host the EC2 in the public subnet, associate the EIP with the EC2, and remove the ALB and ASG definitions. Also remove any private subnet definitions and references if not required.

---

Convert the user data such that it is saved in a shell script, then executed while directing the output to /var/log/user-data-log.txt. Also, use set -x in the beginning and set +x in the end of the user data script.

---

EIP is existing, so make changes in the configuration such that the EIP is referenced from vars and associated with the EC2, during creation of resources. And while destroying resources, EIP isn't dropped but rather just dissociated.

---

Update the user data to export an env var JENKINS_HOME with value `/var/lib/jenkins`, such that it persists even after user data init completion.

---

While the lastest changes look good, there are 2 follow-up changes required:
- The env var setup should be moved between `HTTPS config for jenkins` and `jenkins startup`.
- `wget` installation got removed, so it needs to be added back in the dependency installation. Else subsequent steps will fail.

---

Create an EC2 instance profile which has the following permissions:
- GetObject, PutObject on all S3 buckets in the account.
- Read parameters from SSM parameter store.

Then attach the instance profile to the EC2

---

Replace the region and account number hardcoded valued in the ssm poilicy with variables

---

Perform the following steps in the user data script:
- Using **aws CLI**, retrieve the value of the SSM parameters `arn:aws:ssm:ap-south-1:438801865484:parameter/jenkins/https-keystore-pwd` and `arn:aws:ssm:ap-south-1:438801865484:parameter/jenkins/s3-bucket-name`. Both parameters are encrypted, so use the KMS key alias `arn:aws:kms:ap-south-1:438801865484:alias/jenkins-sym-key` for decrypting the parameters. The retrieved values should be exported as env vars.
- The env var for parameter `/jenkins/https-keystore-pwd` should be referenced wherever applicable in the the user data script.
- Env vars should be unset towards the end of the script.

---

Ensure that the EC2 execution role is not dropped during the terraform destroy operation, and is updated during its creation

---

Encapsulate commands in the user data with `set +x` and `set -x`, where the commands are using the env var `JENKINS_KEYSTORE_PWD`, except while unsetting the env var.

---

Analyze the directory `terraform/jenkins-asg` in the repo `aws-repo` and perform the following tasks:
- Instead of creating just the EC2 instance, create an ASG having min,max,desired as 1,1,1. The launch template should have the same configuration as the present EC2 instance, and the EC2 should continue to be spun up in the private subnet.

---

The ASG lifecycle hook cannot directly trigger a Lambda. Refer to <a href=https://docs.aws.amazon.com/autoscaling/ec2/userguide/tutorial-lifecycle-hook-lambda.html>lifecycle hook tutorial</a>. and make additional changes.