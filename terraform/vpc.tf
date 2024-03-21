#################################################### Creating VPC ###############################################################################

resource "aws_vpc" "BEES" {
  cidr_block       = "10.0.0.0/16"
  instance_tenancy = "default"

  tags = {
    Name = "BEES"
  }
}

#################################################### Creating Subnets ###########################################################################

resource "aws_subnet" "public1" {
  tags = {
    Name = "BEES-subnet-public1-us-east-2a"
  }
  vpc_id            = aws_vpc.BEES.id
  availability_zone = "us-east-2a"
  cidr_block        = "10.0.0.0/20"
}

resource "aws_subnet" "public2" {
  tags = {
    Name = "BEES-subnet-public2-us-east-2b"
  }
  vpc_id            = aws_vpc.BEES.id
  availability_zone = "us-east-2b"
  cidr_block        = "10.0.128.0/20"
}

resource "aws_subnet" "private1" {
  tags = {
    Name = "BEES-subnet-private1-us-east-2a"
  }
  vpc_id            = aws_vpc.BEES.id
  availability_zone = "us-east-2a"
  cidr_block        = "10.0.16.0/20"
}

resource "aws_subnet" "private2" {
  tags = {
    Name = "BEES-subnet-private2-us-east-2b"
  }
  vpc_id            = aws_vpc.BEES.id
  availability_zone = "us-east-2b"
  cidr_block        = "10.0.144.0/20"
}

#################################################### Creating Internetgateway for public subnet ##################################################

resource "aws_internet_gateway" "BEES-igw" {
  tags = {
    Name = "BEES-igw"
  }
  vpc_id = aws_vpc.BEES.id
}

#################################################### Creating route table for public subnet ######################################################

resource "aws_route_table" "BEES-rtb-public" {
  tags = {
    Name = "BEES-rtb-public"
  }
  vpc_id = aws_vpc.BEES.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.BEES-igw.id
  }
}

#################################################### Creating route table for private subnets ####################################################

resource "aws_route_table" "BEES-rtb-private1-us-east-2a" {
  tags = {
    Name = "BEES-rtb-private1-us-east-2a"
  }
  vpc_id = aws_vpc.BEES.id
}

resource "aws_route_table" "BEES-rtb-private2-us-east-2b" {
  tags = {
    Name = "BEES-rtb-private2-us-east-2b"
  }
  vpc_id = aws_vpc.BEES.id
}

#################################################### Creating S3 VPc ENDPOINT ####################################################################

resource "aws_vpc_endpoint" "s3" {
  tags = {
    Name = "s3"
  }
  vpc_id            = aws_vpc.BEES.id
  service_name      = "com.amazonaws.us-east-2.s3"
  vpc_endpoint_type = "Gateway"
  route_table_ids   = [aws_route_table.BEES-rtb-private1-us-east-2a.id, aws_route_table.BEES-rtb-private2-us-east-2b.id]
}

#################################################### Associating route tables to subnets #########################################################

resource "aws_route_table_association" "Public1RTAssociation" {
  subnet_id      = aws_subnet.public1.id
  route_table_id = aws_route_table.BEES-rtb-public.id
}

resource "aws_route_table_association" "Public2RTAssociation" {
  subnet_id      = aws_subnet.public2.id
  route_table_id = aws_route_table.BEES-rtb-public.id
}

resource "aws_route_table_association" "Private11RTAssociation" {
  subnet_id      = aws_subnet.private1.id
  route_table_id = aws_route_table.BEES-rtb-private1-us-east-2a.id
}

resource "aws_route_table_association" "Private2RTAssociation" {
  subnet_id      = aws_subnet.private2.id
  route_table_id = aws_route_table.BEES-rtb-private2-us-east-2b.id
}

resource "aws_efs_file_system" "Postgres-Database" {
  tags = {
    Name = "Postgres-Database"
  }
}

############################################################## Creating Role #####################################################################

resource "aws_iam_role" "EC2CodeDeploy" {
  name               = "EC2CodeDeploy"
  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "ec2.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
EOF
}

resource "aws_iam_role" "CodeDeployRole" {
  name               = "CodeDeployRole"
  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "codedeploy.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
EOF
}

############################################################## Assigning policy to it ############################################################

resource "aws_iam_policy_attachment" "EC2CodeDeploy_code_deploy_policy_attachment" {
  name       = "CodeDeployPolicyAttachment"
  roles      = [aws_iam_role.EC2CodeDeploy.name]
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonEC2RoleforAWSCodeDeploy"
}

resource "aws_iam_policy_attachment" "CodeDeployRole_code_deploy_policy_attachment" {
  name       = "CodeDeployPolicyAttachment"
  roles      = [aws_iam_role.CodeDeployRole.name]
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSCodeDeployRole"
}

resource "aws_security_group" "EC2-webhosting" {
  name        = "EC2-webhosting"
  description = "EC2-webhosting"
  vpc_id      = aws_vpc.BEES.id
  tags = {
    Name = "EC2-webhosting"
  }

  # Define ingress rule to allow incoming
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    description = "http"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    description = "ssh"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Define egress rule to allow all outgoing traffic
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

################################################################## Key_pair #####################################################################

resource "aws_key_pair" "website-key" {
  key_name   = "website"
  public_key = file("./website.pub")
}

##################################################################### EC2 ########################################################################

resource "aws_instance" "example_instance" {
  ami                         = "ami-0e0bf53f6def86294" # Update with your desired AMI ID
  instance_type               = "t2.micro"              # Update with your desired instance type
  subnet_id                   = aws_subnet.public1.id
  key_name                    = aws_key_pair.website-key.key_name
  associate_public_ip_address = true
  vpc_security_group_ids      = [aws_security_group.EC2-webhosting.id]

  provisioner "file" {
    source      = "./web.sh"
    destination = "/tmp/web.sh"
  }

  provisioner "remote-exec" {

    inline = [
      "chmod +x /tmp/web.sh",
      "sudo /tmp/web.sh"
    ]
  }

  connection {
    user        = "ec2-user"
    private_key = file("./website")
    host        = self.public_ip
  }

}