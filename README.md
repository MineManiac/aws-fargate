# **envAIronment-fargate**
AWS project for my Cloud Computing class in college (INSPER), focusing on using FARGATE.

## **What are we going to use??**
For the following project we are going to use a couple tools to make the environment work

* TERRAFORM 14.6
  
**AWS - Services:**
* EC2
* LAMBDA
* FARGATE

# **Getting Started**
Create or Use a AWS account

## **Installations**
 You'll need to install the AWS CLI on your machine https://aws.amazon.com/cli/

 Afterwards Install Terraform, you can follow the instructions here: https://learn.hashicorp.com/tutorials/terraform/install-cli

 I am using WINDOWS and had a bit of a problem installing Terraform on my windows machine so if you want, you can see the following tutorial:
https://www.youtube.com/watch?v=bSrV1Dr8py8&ab_channel=WillPereira


## **AWS access Key and Secret Key**
You'll need to go to the directory of your Terraform folder and run

```sh
   aws configure
```

Where you'll be asked to type your access key and secret key so that we can run terraform with the AWS provider

### **HEADS-UP**
Later on for each resource we'll need to choose a Amazon Machine Image (ami), the default image we're going to use is the ubuntu 22.04 jammy

In each resource created you'll need to setup the following:
``` sh
    data "aws_ami" "ubuntu" {
        most_recent = true

        filter {
            name= "name"
            values = ["ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"]
        }

        owners = [ "099720109477" ]
    }
```
We use this so that the image chosen is dynamic independently of the server used. The owner is Cannonical.

And in case you need the origin:
```sh
amazon/ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-20230516	
```

# **Tutorial**
I created a couple of files inside the Terraform folder so that I can manage and setup all of the resources used in AWS.

We'll start deploying the EC2 resource, and later on lambda and Fargate.

# **1. Setting Up EC2**

## **Create backend.tf**
Create a backend.tf file

Here we are going to define the AWS provider setting up the version and the region

```sh
   # Configure the AWS Provider
    provider "aws" {
        region  = var.region
    }
```

## **Create variables.tf**
We'll need to create a variables file to make it easier to change things, variables.tf

At first lets setup the region and the instance type
```sh
    variable "region" {
        description = "Define what region the AWS provider will use"
        default = "us-east-2"
    }

    variable "instance_type" {
        description = "Define what instance type the resource will use"
        default = "t2.micro"
    }
```

## **Create ec2.tf**
We create this file to manage the ec2 server resource

Here we are going to code the deployment of the instance EC2 named "server". Where the image is the one previously stated, the type used is micro because I am using this to test the environment and don't want to waste a bunch of money.

```sh
    resource "aws_instance" "server" {
        ami = "ami-053b0d53c279acc90"
        instance_type = var.instance_type
    }
```
The tags are used to categorize our resource, where we can name, state the type of environment we are going to use, in our case as a developer, the provisioner (Terraform), and the repository we are working on. It is totally up to you how to tag, and it is optional.

```sh
    tags = {
        Name = "server-ec2"
        Environment = "Dev"
        Provisioner = "Terraform"
        Repo = "https://github.com/MineManiac/envAIronment-fargate"
    }
```


## **Creating the Output.tf file**
Here we are going to create the basic output file, where you can see all the outputs you set up. 


```sh
    output "public_ip" {
        value = aws_instance.server.public_ip
    }
```

## **Final EC2 setup**

In the end your files should look like this:

* backend.tf:
    
```sh
    # Configure the AWS Provider
    provider "aws" {
        region = var.region
    }
```

* variables.tf:
```sh
    variable "region" {
        description = "Define what region the AWS provider will use"
        default = "us-east-2"
    }

    variable "instance_type" {
        description = "Define what instance type the resource will use"
        default = "t2.micro"
    }
```
* ec2.tf:
```sh
    data "aws_ami" "ubuntu" {
        most_recent = true

        filter {
            name= "name"
            values = ["ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"]
        }

        owners = [ "099720109477" ]
    }


    resource "aws_instance" "server" {
        ami           = data.aws_ami.ubuntu.id
        instance_type = var.instance_type

        tags = {
            Name        = "server-ec2"
            Environment = "Dev"
            Provisioner = "Terraform"
            Repo        = "https://github.com/MineManiac/envAIronment-fargate"
        }
    }
```
* output.tf:
```sh
    output "public_ip" {
        value = aws_instance.server.public_ip
    }
```

If you want to see more outputs references you can check the following link: https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/instance

## **Testing**
The first thing you should do is format all the files, you can do that by using the command:
```sh
terraform fmt [FILENAME]
```

Open your console and go to the path where your files are

run the following commands
```sh
terraform init
terraform plan
terraform apply
```

To check if everything was done correctly you need to open your amazon dashboard and check if the instance was created.
If everything looks good destroy the instance so that we can proceed to the next steps.

```sh
terraform destroy
```

# **2. Lambda & Fargate**


## **Documentações das ferramentas de desenvolvimento utilizadas:**

* [Terraform](https://www.terraform.io/docs/index.html)
* [AWS](https://docs.aws.amazon.com/index.html)
* [Docker](https://docs.docker.com/)
* [VScode](https://code.visualstudio.com/docs)
* [Tutorial Demay](https://github.com/TiagoDemay/tutorial-terraform/blob/main/tutorial/terraform.md)

