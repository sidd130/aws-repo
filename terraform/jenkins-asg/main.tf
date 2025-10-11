resource "aws_launch_template" "jenkins" {
  name_prefix   = "jenkins-template"
  image_id      = var.ami_id
  instance_type = var.instance_type
  key_name      = var.key_name

  network_interfaces {
    associate_public_ip_address = true
    security_groups            = [var.security_group_id]
  }

  tag_specifications {
    resource_type = "instance"
    tags = {
      Name = "jenkins-server"
    }
  }

  user_data = base64encode(<<-EOF
              #!/bin/bash
              # Update system
              yum update -y

              # Install required dependencies
              yum install -y fontconfig

              # Install Java 21
              yum install -y java-21-openjdk

              # Install Jenkins LTS release
              wget -O /etc/yum.repos.d/jenkins.repo https://pkg.jenkins.io/redhat-stable/jenkins.repo
              rpm --import https://pkg.jenkins.io/redhat-stable/jenkins.io-2023.key
              yum install -y jenkins

              # Configure JVM options for Jenkins with G1 garbage collector
              mkdir -p /etc/systemd/system/jenkins.service.d/
              cat << JENKINS_CONFIG > /etc/systemd/system/jenkins.service.d/override.conf
              [Service]
              Environment="JAVA_OPTS=-Xmx2048m -XX:+UseG1GC -XX:+ExplicitGCInvokesConcurrent -XX:+ParallelRefProcEnabled -XX:+UseStringDeduplication -XX:+UnlockExperimentalVMOptions -XX:G1NewSizePercent=20 -XX:+UnlockDiagnosticVMOptions -XX:G1HeapRegionSize=8m -XX:MetaspaceSize=512m -XX:InitiatingHeapOccupancyPercent=45"
              JENKINS_CONFIG

              # Reload systemd and start Jenkins
              systemctl daemon-reload
              systemctl enable jenkins
              systemctl start jenkins

              # Configure firewall if it's running
              if systemctl is-active firewalld; then
                firewall-cmd --permanent --new-service=jenkins
                firewall-cmd --permanent --service=jenkins --set-short="Jenkins ports"
                firewall-cmd --permanent --service=jenkins --set-description="Jenkins port exceptions"
                firewall-cmd --permanent --service=jenkins --add-port=8080/tcp
                firewall-cmd --permanent --add-service=jenkins
                firewall-cmd --permanent --zone=public --add-service=http
                firewall-cmd --reload
              fi

              # Install Terraform
              yum install -y yum-utils
              yum-config-manager --add-repo https://rpm.releases.hashicorp.com/RHEL/hashicorp.repo
              yum -y install terraform
              EOF
  )
}

# Create Application Load Balancer
resource "aws_lb" "jenkins" {
  name               = "jenkins-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [var.alb_security_group_id]
  subnets            = var.public_subnet_ids

  enable_deletion_protection = false

  tags = {
    Name = "jenkins-alb"
  }
}

# Create ALB target group
resource "aws_lb_target_group" "jenkins" {
  name     = "jenkins-target-group"
  port     = 8080
  protocol = "HTTP"
  vpc_id   = var.vpc_id

  health_check {
    enabled             = true
    healthy_threshold   = 2
    interval            = 15
    matcher            = "200,403"  # Jenkins returns 403 when not authenticated
    path               = "/login"
    port               = "traffic-port"
    timeout            = 5
    unhealthy_threshold = 2
  }

  tags = {
    Name = "jenkins-target-group"
  }
}

# Create ALB listener
resource "aws_lb_listener" "jenkins" {
  load_balancer_arn = aws_lb.jenkins.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.jenkins.arn
  }
}

# Create Auto Scaling Group
resource "aws_autoscaling_group" "jenkins" {
  name                = "jenkins-asg"
  desired_capacity    = var.desired_capacity
  max_size           = var.max_size
  min_size           = var.min_size
  target_group_arns  = [aws_lb_target_group.jenkins.arn]
  vpc_zone_identifier = [var.private_subnet_id]

  launch_template {
    id      = aws_launch_template.jenkins.id
    version = "$Latest"
  }

  tag {
    key                 = "Name"
    value               = "jenkins-server"
    propagate_at_launch = true
  }

  lifecycle {
    create_before_destroy = true
  }
}

# Create Elastic IP for ALB
resource "aws_eip" "jenkins" {
  tags = {
    Name = "jenkins-host-t3"
  }
}

# Associate EIP with ALB using a NAT Gateway
resource "aws_nat_gateway" "jenkins" {
  allocation_id = aws_eip.jenkins.id
  subnet_id     = var.public_subnet_ids[0]

  tags = {
    Name = "jenkins-nat-gateway"
  }
}