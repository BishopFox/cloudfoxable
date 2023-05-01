// an openzfs fsx filesystem
resource "aws_fsx_openzfs_file_system" "cloudfox-fsx-zfs" {
  subnet_ids = [aws_subnet.cloudfox-operational-1.id]
  storage_capacity = 64
  throughput_capacity = 64
  storage_type = "SSD"
  deployment_type = "SINGLE_AZ_1"
  tags = {
    Name = "cloudfox-fsx"
  }
}


