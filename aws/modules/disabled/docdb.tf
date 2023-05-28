# Create a security group
resource "aws_security_group" "example_security_group" {
  vpc_id = aws_vpc.cloudfox.id

  # Allow incoming connections on the MongoDB port (27017)
  ingress {
    from_port   = 27017
    to_port     = 27017
    protocol    = "tcp"
    //cidr_blocks = ["${var.user_ip}/32"]
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# Create a subnet group
resource "aws_docdb_subnet_group" "example_subnet_group" {
  name       = "example-subnet-group"
  subnet_ids = [aws_subnet.cloudfox-operational-1.id, aws_subnet.cloudfox-operational-2.id, aws_subnet.cloudfox-operational-3.id]
}



# Create a DocumentDB cluster
resource "aws_docdb_cluster" "example_cluster" {
  cluster_identifier        = "example-cluster"
  availability_zones        = [var.AWS_REGION_SUB_1, var.AWS_REGION_SUB_2, var.AWS_REGION_SUB_3]
  master_username           = "cloudfoxable"
  master_password           = "password123"  # Replace with your own password
  vpc_security_group_ids    = [aws_security_group.example_security_group.id]
  db_subnet_group_name      = aws_docdb_subnet_group.example_subnet_group.name
  backup_retention_period   = 7
  preferred_backup_window   = "07:00-09:00"
  preferred_maintenance_window = "sun:03:00-sun:04:00"
  storage_encrypted         = true
  engine_version            = "3.6.0"
  deletion_protection       = false
}

# Output the cluster endpoint
output "cluster_endpoint" {
  value = aws_docdb_cluster.example_cluster.endpoint
}

resource "aws_docdb_cluster_instance" "cluster_instances" {
  count              = 1
  identifier         = "docdb-cluster-demo-${count.index}"
  cluster_identifier = aws_docdb_cluster.example_cluster.id
  instance_class     = "db.t3.medium"
}