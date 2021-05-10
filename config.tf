variable "aws_access_key" {}
variable "aws_secret_key" {}
variable "provate_key_path" {}
variable "key_name" {}
variable "aws_region" {
    default = "us-east-1"
}

// Defines the provider
provider "aws" {
    access_key = var.access_key
    secret_key = var.secret_key
    region = var.aws_region

}

// "data" means "datasource", where whe search for informations about our provider
// Allow Terraform to interact with the default VPC, without create an additional one
// This data search all Amazon Linux AMI's on the region
data "aws_ami" "aws-linux" {
    most_recent = true
    owners = ["amazon"]
    
    filter {
        name = "name"
        values = [ "amzn-ami-hvm*" ]
    }

    filter {
        name = "root-device-type"
        values = [ "ebs" ]
    }

    filter {
        name = "virtualization-type"
        values = [ "hvm" ]
    }
}

// Uses the default VPC within your region
// VPC = Virtual Private Cloud
resource "aws_default_vpc" "default" {
  
}

//Allows to connect with our instance via SSH, wich is using NGinx
resource "aws_security_group" "allow_ssh" {
    name = "nginx_demo"
    description = "Allows ports for nginx demo"
    vpc_id = aws_default_vpc.default.id

    ingress = [ {
      cidr_blocks = [ "0.0.0.0/0" ]
      from_port = 22
      to_port = 22
      protocol = "tcp"
    }

    ,{
      cidr_blocks = [ "0.0.0.0/0" ]
      from_port = 80
      to_port = 80
      protocol = "tcp"
    } ]

    egress = [ {
      cidr_blocks = [ "0.0.0.0/0" ]
      from_port = 0
      to_port = 0
      protocol = "-1"
    } ]
}



resource "aws_instance" "nginx" {
    ami = data.aws_ami.aws-linux.id
    instance_type = "t2.micro"
    key_name = var.key_name
    vpc_security_group_ids = [aws_security_group.allow_ssh.id]

    connection {
        type = "ssh"
        host = self.public_ip
        user = "ec2-user"
        private_Key = file(var.private_key_path)
    }

    provisioner "remote-exec" {
        inline = ["sudo yum install nginx -y", "sudo service nginx start"]
    
    }


}

output "aws_instance_public_dns" {
    value = "aws_instance.nginx.public_dns"
}

