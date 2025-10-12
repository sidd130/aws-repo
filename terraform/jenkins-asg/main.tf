# Create EC2 instance
resource "aws_instance" "jenkins" {
  ami           = var.ami_id
  instance_type = var.instance_type
  subnet_id     = var.subnet_id
  key_name      = var.key_name

  vpc_security_group_ids = [var.security_group_id]

  user_data = base64encode(<<-EOF
              #!/bin/bash
              exec 1> >(tee /var/log/user-data-log.txt) 2>&1
              set -x

              echo "Starting Jenkins installation and configuration at $(date)"

              # Update system
              echo "Updating system packages..."
              yum update -y

              # Install required dependencies
              echo "Installing dependencies..."
              yum install -y fontconfig wget

              # Install Java 21
              echo "Installing Java 21..."
              yum install -y java-21-openjdk

              # Install Jenkins LTS release
              echo "Installing Jenkins LTS..."
              wget -O /etc/yum.repos.d/jenkins.repo https://pkg.jenkins.io/redhat-stable/jenkins.repo
              rpm --import https://pkg.jenkins.io/redhat-stable/jenkins.io-2023.key
              yum install -y jenkins

              # Configure JVM options for Jenkins with G1 garbage collector
              echo "Configuring JVM options for Jenkins..."
              mkdir -p /etc/systemd/system/jenkins.service.d/
              cat << 'JENKINS_CONFIG' > /etc/systemd/system/jenkins.service.d/override.conf
              [Service]
              Environment="JAVA_OPTS=-Xmx2048m -XX:+UseG1GC -XX:+ExplicitGCInvokesConcurrent -XX:+ParallelRefProcEnabled -XX:+UseStringDeduplication -XX:+UnlockExperimentalVMOptions -XX:G1NewSizePercent=20 -XX:+UnlockDiagnosticVMOptions -XX:G1HeapRegionSize=8m -XX:MetaspaceSize=512m -XX:InitiatingHeapOccupancyPercent=45"
              JENKINS_CONFIG

              # Reload systemd and start Jenkins
              echo "Starting Jenkins service..."
              systemctl daemon-reload
              systemctl enable jenkins
              systemctl start jenkins

              # Configure firewall if it's running
              echo "Configuring firewall rules..."
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
              echo "Installing Terraform..."
              yum install -y yum-utils
              yum-config-manager --add-repo https://rpm.releases.hashicorp.com/RHEL/hashicorp.repo
              yum -y install terraform

              echo "Installation completed at $(date)"
              set +x
              EOF
  )

  tags = {
    Name = "jenkins-server"
  }
}

# Data source for existing EIP
data "aws_eip" "jenkins" {
  id = var.eip_id
}

# Associate existing EIP with EC2 instance
resource "aws_eip_association" "jenkins" {
  instance_id   = aws_instance.jenkins.id
  allocation_id = data.aws_eip.jenkins.id

  lifecycle {
    create_before_destroy = true
  }
}