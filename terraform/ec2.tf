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