resource "aws_db_subnet_group" "petclinic" {
  name        = "petclinic-rds-subnet-group"
  description = "Subnet group for PetClinic RDS MySQL"

  subnet_ids = [
    "subnet-042e940e5f9f6f043",
    "subnet-02bb13ffe901c2c5d"
  ]

  tags = {
    Name        = "petclinic-rds-subnet-group"
    Environment = "dev"
    Project     = "PetClinic"
  }
}
