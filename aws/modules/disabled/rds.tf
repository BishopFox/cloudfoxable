resource "aws_security_group" "allow_mysql_from_world" {
  name        = "allow_mysql_from_world"
  description = "Allow mysql inbound traffic from world"
  vpc_id      = aws_vpc.cloudfox.id

  ingress {
    description      = "SSH from world"
    from_port        = 3306
    to_port          = 3306
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
  }

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  tags = {
    Name = "allow_mysql_from_world"
  }
}



resource "aws_db_subnet_group" "default" {
  name        = "rds-subnet-group"
  description = "Terraform example RDS subnet group"
  subnet_ids  = [aws_subnet.cloudfox-operational-1.id, aws_subnet.cloudfox-operational-2.id, aws_subnet.cloudfox-operational-3.id]
}


resource "aws_db_instance" "default" {
  allocated_storage    = 5
  engine               = "mysql"
  engine_version       = "5.7"
  instance_class       = "db.t3.micro"
  db_name              = "cloudfox${random_string.resource-suffix.result}"  
  identifier           = "cloudfox-rds-${random_string.resource-suffix.result}"   
  username             = "admin"
  password             = random_password.database-secret.result
  parameter_group_name = "default.mysql5.7"
  skip_final_snapshot  = true
  publicly_accessible    = true
  vpc_security_group_ids  = [ aws_security_group.allow_mysql_from_world.id ]
  db_subnet_group_name = aws_db_subnet_group.default.id

}

