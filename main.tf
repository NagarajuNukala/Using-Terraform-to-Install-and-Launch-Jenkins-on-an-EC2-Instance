# Define the AWS provider
provider "aws" {
  region = "us-east-1" # Replace with your desired AWS region
}

# Create a key pair for SSH access
resource "aws_key_pair" "my_key_pair" {
  key_name   = "my-key-pair"                                                     # Replace with your desired key pair name
  public_key = file("/Users/rajunukala/Desktop/devops/terra-jenkins/my-key.pub") # Replace with your public key file path
}

# Create a security group for Jenkins
resource "aws_security_group" "jenkins_sg" {
  name        = "jenkins-sg" # Replace with your desired security group name
  description = "Jenkins Security Group"

  # Ingress rule for SSH (port 22) and Jenkins (port 8080)
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Ingress rule for Jenkins (port 8080)
  ingress {
    from_port   = 8080
    to_port     = 8080
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Add outbound rule to allow all traffic
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1" # All protocols
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# Launch an EC2 instance with Jenkins installation
resource "aws_instance" "jenkins_instance" {
  ami             = "ami-0261755bbcb8c4a84" # Replace with your desired AMI ID (Ubuntu 20.04 LTS, for example)
  instance_type   = "t2.medium"             # Replace with your desired instance type
  key_name        = aws_key_pair.my_key_pair.key_name
  security_groups = [aws_security_group.jenkins_sg.name]

  user_data = <<-EOF
    #!/bin/bash
    sudo apt update -y
    sudo apt install -y openjdk-11-jdk
    sudo wget -q -O - https://pkg.jenkins.io/debian/jenkins.io.key | sudo apt-key add -
    sudo sh -c 'echo deb http://pkg.jenkins.io/debian-stable binary/ > /etc/apt/sources.list.d/jenkins.list'
    sudo apt update -y
    sudo apt install -y jenkins
    sudo systemctl start jenkins
    sudo systemctl enable jenkins
  EOF

  tags = {
    Name = "Jenkins Instance"
  }
}

# Output the public IP address of the EC2 instance
output "public_ip" {
  value = aws_instance.jenkins_instance.public_ip
}

