# **envAIronment-fargate**
AWS project for my Cloud Computing class in college (INSPER), focusing on using FARGATE.

## **About the project**
Fargate is a AWS serverless service that allows us to run containers without having to manage servers or clusters. It is a very useful tool for developers that want to focus on the code and not on the infrastructure.

Running ECS with fargate eliminates the need to manage servers or clusters of Amazon EC2 instances. With Fargate, you no longer have to provision, configure, and scale clusters of virtual machines to run containers. This removes the need to choose server types, decide when to scale your clusters, or optimize cluster packing. Fargate lets you focus on designing and building your applications instead of managing the infrastructure that runs them.

The final goal of this project is to create a environment where we can run a container with a python script that will be triggered by a lambda function, and the container will run a script that will create a file in a S3 bucket.

For the meantime we are going to use a simple hello-world.json in the place of the images.

## **What are we going to use??**
For the following project we are going to use a couple tools to make the environment work

* TERRAFORM 14.6
    > Infrastructure as code tool
* ECS with FARGATE 
    > Elastic Container Service to run our serverless containers
* VPC 
    > Virtual private network to isolate our environment
* LAMBDA
    > To trigger the container and functions
* S3 
    > To store the images
* IAM
    > To manage the permissions

# **Getting Started**
Create or Use an existing AWS account

In the amazon dashboard give the proper permissions to it, so that you can create the resources needed for the project.

## **Installations**
 You'll need to install the AWS CLI on your machine https://aws.amazon.com/cli/

 Afterwards Install Terraform, you can follow the instructions here: https://learn.hashicorp.com/tutorials/terraform/install-cli


## **AWS access Key and Secret Key**
To input your access key and secret key from AWS you'll need to run the following command on your terminal:

```sh
   aws configure
```
this is done so that we can use terraform to create the resources on AWS.

# **Tutorial**
First of all you'll need to create a folder to store all of the files, I named mine terraform, but you can name it whatever you want.

We'll start deploying the ECS Fargate resource, and later on lambda, S3 and IAM.

## 1. Setting Up ECS using Fargate

### **Create main.tf**
Here we are going to define the AWS provider setting up the region to **us-east-2**
> main.tf
```sh
   # Configure the AWS Provider
    provider "aws" {
        region = "us-east-2"
        alias  = "us-east-2"
    }
```
Create a resource called **aws_ecs_cluster** that will be our cluster, and we'll name it **"ecs-cluster"**
```sh
    resource "aws_ecs_cluster" "ecs-cluster" {
        name = "ecs-cluster"
    }
```

Make a resource called **aws_ecs_task_definition** to define the task that will be run by the container, and name it **"ecs-task"**
```sh
    resource "aws_ecs_task_definition" "task_definition" {
        family                   = "image-processor"
        execution_role_arn       = aws_iam_role.esc_role.arn
        task_role_arn            = aws_iam_role.task_role.arn
        network_mode             = "awsvpc"
        requires_compatibilities = ["FARGATE"]
        memory =  512
        cpu = 256

        container_definitions = data.local_file.containerdefinitions.content
    }
```
The **aws_iam_role** resource will be made later on, now lets focus on the container_definitions file.

It is necessary to create a json file with the container definitions, so that we can run the container with the proper configurations easily.

In the same folder create a file called **containerdefinitions.json** and paste the following code, watch out for the indentation:
>containerdefinitions.json
```json
[
  {
    "name": "image-processor",
    "image": "ubuntu:latest",
    
    "portMappings": [
      {
        "containerPort": 80,
        "protocol": "tcp"
      }
    ],
    "environment": [
      {
        "name": "images-bucket",
        "value": "${aws_s3_bucket.bucket_images.bucket}"
      },
      {
        "name": "processing-image-function",
        "value": "${aws_lambda_function.image_processing.function_name}"
      }
    ]
  }
]
```
The Bucket and Lambda Function will be created later on, so for now just copy the code and paste it in the json file.

Back in the **main.tf** file we'll need to set our json file as a local_file resource, so that we can use it in the **aws_ecs_task_definition** resource.
>main.tf
```sh
    data "local_file" "containerdefinitions" {
        filename = "containerdefinitions.json"
    }
```

Now we'll add the **aws_ecs_service** resource, that will manage the containers, and name it **image_processing_service"**
```sh
    resource "aws_ecs_service" "image_processing_service" {
        name            = "image_processing_service"
        cluster         = aws_ecs_cluster.ecs_cluster.id
        task_definition = aws_ecs_task_definition.task_definition.arn
        desired_count   = 1

        network_configuration {
            subnets = [aws_subnet.my_subnet.id]
        }
    }
```
For the network configuration we'll need to start our own **Virtual Private Cloud (VPC)** and Subnet, so that we can isolate our environment.

```sh
    resource "aws_vpc" "vpc" {
        cidr_block = "10.0.0.0/16"
    }

    resource "aws_subnet" "subnet" {
        vpc_id                  = aws_vpc.vpc.id
        cidr_block              = "10.0.1.0/24"
        availability_zone       = "us-east-2a"
        map_public_ip_on_launch = true
    }

```

## 2. Setting up S3
### **Create s3.tf**
We create this file and code the resource **aws_s3_bucket** to save the images that we'll be uploading to the container.
> s3.tf
```sh
    resource "aws_s3_bucket" "bucket_images" {
        bucket = "bucket-save-images"
    }
```

## 3. Setting Lambda
### **Create lambda.tf**
This file is meant to code the lambda function that will process the images and save them in the bucket.

However I did not make the image processing function, in place I used a simple **"Hello World"** function, so that we can test the lambda function and see if it is working properly.

```sh
    resource "aws_lambda_function" "image_processing" {
        function_name    = "image-processing"
        role             = aws_iam_role.lambda_role.arn
        handler          = "hello-world.handler"
        runtime          = "nodejs14.x"
        filename         = "hello-world.zip"
        source_code_hash = filebase64sha256("hello-world.zip")

        environment {
            variables = {
            S3_BUCKET = aws_s3_bucket.bucket_images.bucket
            }
        }
    }
```

For the Hello World function to work, create a file called **hello-world.js** and **zip**, saving it in the same directory. Paste the following code inside of it:
> hello-world.js
```js
exports.handler = async (event) => {
    console.log("Hello, World!");
  
    const response = {
      statusCode: 200,
      body: "Hello, World!",
    };
  
    return response;
  };
```
## 4. Setting up IAM
### **Create the proper permission files**
We'll have to use **IAM** to create the proper permissions for our resources to work, so we'll need to create 2 files, one for the **ecs_role.tf** and another one **lambda_role.tf**.

### **Create ecs_role.tf**
It is necessary so that our ECS service can access the S3 bucket and the Lambda function.
> ecs_role.tf
```sh
resource "aws_iam_role" "ecs_role" {
  name = "ecs-role"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "ecs-tasks.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
EOF
}
```

### **Create lambda_role.tf**
You'll also want to grant permissions for the **ecs_role** to access the **s3_bucket** and **lambda_function**.

```sh	
resource "aws_iam_role" "task_role" {
  name = "task-role"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "ecs-tasks.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
EOF
}
```

Same thing for lambda role, we'll need to grant permissions for the **lambda_role** to access the **s3_bucket**.
>lambda_role.tf
```sh
resource "aws_iam_role" "lambda_role" {
  name = "lambda-role"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "lambda.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
EOF
}
```


## 5.Setting up the output
Here we are going to create the basic output file, where you can see all the outputs you set up.

You can change the outputs according to your needs

### **Create outputs.tf**
```sh
output "cluster_name" {
  description = "value of the cluster name"
  value = aws_ecs_cluster.ecs_cluster.name
}

output "task_definition_arn" {
  description = "value of the task definition arn"
  value = aws_ecs_task_definition.task_definition.arn
}

output "service_name" {
  description = "value of the service name"
  value = aws_ecs_service.image_processing_service.name
}

output "lambda_function_name" {
  description = "value of the lambda function name"
  value = aws_lambda_function.image_processing.function_name
}

output "s3_bucket_name" {
  description = "value of the s3 bucket name"
  value = aws_s3_bucket.bucket_images.bucket
}
```

## **Final Step - Testing with Terraform**

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

## 6. **Testing**
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

To check if everything was done correctly you need to open your amazon dashboard and check if everything looks alright.
Afterwards you need to run:
```sh
terraform destroy
```
To clean up everything.

### Your terminal should look like this when you run the **terraform apply** command, showing the outputs I stated in the output.tf file:
<img src="https://github.com/MineManiac/envAIronment-fargate/assets/15271557/3bb42dea-d39a-446c-9dc4-51f91539a54b"  width="70%">

### A couple of screenshots from my amazon dashboard:


<img src="https://github.com/MineManiac/envAIronment-fargate/assets/15271557/7c922523-683e-425f-b77c-811682be7e66"  width="70%">
<img src="https://github.com/MineManiac/envAIronment-fargate/assets/15271557/6feed310-f3e9-4dba-ae25-2d161398cfd0"  width="70%">
<img src="https://github.com/MineManiac/envAIronment-fargate/assets/15271557/de2bc31d-75da-448a-8fa0-d82632abd4ef"  width="70%">
<img src="https://github.com/MineManiac/envAIronment-fargate/assets/15271557/3ac8b790-287d-4ca9-887d-8d2325b5c4c7"  width="70%">
<img src="https://github.com/MineManiac/envAIronment-fargate/assets/15271557/ed055fc9-8eeb-441c-9e14-4bf89548fded"  width="70%">
<img src="https://github.com/MineManiac/envAIronment-fargate/assets/15271557/419bdc76-1ce8-4280-a8a6-175ef3559ed8"  width="70%">
<img src="https://github.com/MineManiac/envAIronment-fargate/assets/15271557/32d8f9f9-bf19-4999-89d8-fb9e064d6487"  width="70%">


## **Documentation for the tools used:**

* [Terraform](https://www.terraform.io/docs/index.html)
* [AWS](https://docs.aws.amazon.com/index.html)
* [VScode](https://code.visualstudio.com/docs)
* [Tutorial Demay](https://github.com/TiagoDemay/tutorial-terraform/blob/main/tutorial/terraform.md)
* [Tutorial Hashicorp](https://learn.hashicorp.com/tutorials/terraform/aws-build?in=terraform/aws-get-started)

## **Quick References:**
https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/lambda_function

https://spacelift.io/blog/terraform-docker

https://dev.to/aws-builders/create-an-ecs-cluster-with-docker-image-using-terraform-8fc

https://www.claranet.fr/blog/aws-fargate-terraform

https://engineering.finleap.com/posts/2020-02-20-ecs-fargate-terraform/

https://erik-ekberg.medium.com/terraform-ecs-fargate-example-1397d3ab7f02]

https://www.architect.io/blog/2021-03-30/create-and-manage-an-aws-ecs-cluster-with-terraform/
