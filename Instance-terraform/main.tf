resource "aws_security_group" "Jenkins-sg" {
  name        = "Jenkins-Security Group"
  description = "Open 22,443,80,8080,9000,9100,9090,3000"

  # Define a single ingress rule to allow traffic on all specified ports
  ingress = [
    for port in [22, 80, 443, 8080, 9000, 9100, 9090, 3000] : {
      description      = "TLS from VPC"
      from_port        = port
      to_port          = port
      protocol         = "tcp"
      cidr_blocks      = ["0.0.0.0/0"]
      ipv6_cidr_blocks = []
      prefix_list_ids  = []
      security_groups  = []
      self             = false
    }
  ]

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "Jenkins-sg"
  }
}

# DATA For AMI
data "aws_ami" "ubuntu" {
  most_recent = true

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  owners = ["099720109477"] # Canonical
}

# Create the IAM Role and Attach the Administrator Policy
resource "aws_iam_role" "chatgpt_role" {
  name = "chatgpt-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "chatgpt_role_attach" {
  role       = aws_iam_role.chatgpt_role.name
  policy_arn = "arn:aws:iam::aws:policy/AdministratorAccess"
}

# Create an Instance Profile and Attach the Role
resource "aws_iam_instance_profile" "chatgpt_instance_profile" {
  name = "chatgpt-instance-profile"
  role = aws_iam_role.chatgpt_role.name
}

# JENKINS SONARQUBE EC2 INSTANCE
resource "aws_instance" "web" {
  ami                    = data.aws_ami.ubuntu.id #change your ami value according to your aws instance
  instance_type          = "t2.large"
  key_name               = "jenkins"
  vpc_security_group_ids = [aws_security_group.Jenkins-sg.id]
  user_data              = templatefile("./script.sh", {})

  iam_instance_profile = aws_iam_instance_profile.chatgpt_instance_profile.name

  tags = {
    Name = "gpt clone"
  }
  root_block_device {
    volume_size = 30
  }
}

# PROMETHEUS GRAFANA WEB INSTANCE
resource "aws_instance" "web2" {
  ami                    = data.aws_ami.ubuntu.id
  instance_type          = "t2.medium"
  key_name               = "jenkins"
  vpc_security_group_ids = [aws_security_group.Jenkins-sg.id]
  user_data              = file("./install_monitoring_stack.sh")
  tags = {
    Name = "Monitoring via grafana"
  }
  root_block_device {
    volume_size = 30
  }
}

