resource "aws_security_group" "ec2" {
  name        = "launch-wizard-10"
  description = "launch-wizard-10 created 2026-10-05T13:53:30.332Z"
  vpc_id      = aws_vpc.petclinic.id

  ingress {
    description = "SSH access"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    description = "Allow outbound traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name        = "launch-wizard-10"
    Environment = "dev"
    Project     = "PetClinic"
  }
}
