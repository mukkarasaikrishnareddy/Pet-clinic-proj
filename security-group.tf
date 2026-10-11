resource "aws_security_group" "rds" {
  name        = "petclinic-rds-sg"
  description = "Security group for PetClinic RDS MySQL"
  vpc_id      = "vpc-017c95bc0edc7e1ba"

  ingress {
    description     = "MySQL access from PetClinic EC2"
    from_port       = 3306
    to_port         = 3306
    protocol        = "tcp"
    security_groups = ["sg-04359017cf06cba79"]
  }

  ingress {
    description     = "MySQL access from PetClinic EKS"
    from_port       = 3306
    to_port         = 3306
    protocol        = "tcp"
    security_groups = ["sg-0f85931ffac294e58"]
  }

  egress {
    description = "Allow outbound traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name        = "petclinic-rds-sg"
    Environment = "dev"
    Project     = "PetClinic"
  }
}
