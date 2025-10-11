# Replace these values with your existing resource IDs
vpc_id = "vpc-5cd4ca34"
# Subnets in different AZs
public_subnet_ids = [
  "subnet-00d4dde3d0bb30f36",  # ap-south-1a
  "subnet-013d8d5598d30fee1"   # ap-south-1b - Replace with your second subnet ID
]
private_subnet_id = "subnet-040cc2dadbb05321a"  # Subnet for EC2 instances
existing_route_table_id = "rtb-0441c5c05a40e889f"
security_group_id = "sg-0ff0c47cf3588c4ce"
key_name = "jenkins-host-keypair"  # Replace with your existing key pair name

# ALB Configuration
alb_security_group_id = "sg-0ff0c47cf3588c4ce"  # You might want to use a different security group for ALB
public_subnets = ["subnet-00d4dde3d0bb30f36"]  # List all public subnets where ALB should be placed