# Create IAM role for Jenkins EC2
resource "aws_iam_role" "jenkins_role" {
  name = "jenkins-ec2-role"

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

# Create IAM policy for S3 access
resource "aws_iam_role_policy" "jenkins_s3_policy" {
  name = "jenkins-s3-policy"
  role = aws_iam_role.jenkins_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "s3:GetObject",
          "s3:PutObject"
        ]
        Resource = [
          "arn:aws:s3:::siddas-jenkins-backup-store/*"
        ]
      }
    ]
  })
}

# Create IAM policy for SSM parameter store access and KMS decryption
resource "aws_iam_role_policy" "jenkins_ssm_policy" {
  name = "jenkins-ssm-policy"
  role = aws_iam_role.jenkins_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "ssm:GetParameter",
          "ssm:GetParameters",
          "ssm:GetParametersByPath"
        ]
        Resource = "arn:aws:ssm:${var.aws_region}:${var.account_id}:parameter/jenkins/*"
      },
      {
        Effect = "Allow"
        Action = [
          "kms:Decrypt"
        ]
        Resource = "arn:aws:kms:${var.aws_region}:${var.account_id}:alias/jenkins-sym-key"
      }
    ]
  })
}

# Create instance profile
resource "aws_iam_instance_profile" "jenkins_profile" {
  name = "jenkins-instance-profile"
  role = aws_iam_role.jenkins_role.name
}

# Create EC2 instance
resource "aws_instance" "jenkins" {
  ami           = var.ami_id
  instance_type = var.instance_type
  subnet_id     = var.subnet_id
  key_name      = var.key_name
  iam_instance_profile = aws_iam_instance_profile.jenkins_profile.name

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
              yum install -y fontconfig wget unzip

              # Install AWS CLI
              echo "Installing AWS CLI..."
              curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
              unzip awscliv2.zip
              ./aws/install
              rm -f awscliv2.zip
              rm -rf aws/

              # Fetch SSM parameters
              echo "Fetching SSM parameters..."
              export JENKINS_KEYSTORE_PWD=$(aws ssm get-parameter \
                --name "/jenkins/https-keystore-pwd" \
                --with-decryption \
                --region ${var.aws_region} \
                --query "Parameter.Value" \
                --output text)

              export JENKINS_BACKUP_BUCKET=$(aws ssm get-parameter \
                --name "/jenkins/s3-bucket-name" \
                --with-decryption \
                --region ${var.aws_region} \
                --query "Parameter.Value" \
                --output text)

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
              Environment="JENKINS_HOME=/var/lib/jenkins"
              Environment="JENKINS_HTTPS_PORT=8443"
              Environment="JENKINS_HTTPS_KEYSTORE=/etc/ssl/jenkins/jenkins.p12"
              Environment="JENKINS_HTTPS_KEYSTORE_PASSWORD=$JENKINS_KEYSTORE_PWD"
              JENKINS_CONFIG

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

              # Configure HTTPS for Jenkins
              echo "Configuring HTTPS for Jenkins..."
              openssl req -newkey rsa:2048 -nodes -keyout key.pem -x509 -days 365 -out jenkins.pem -subj "/C=IN/ST=Karnataka/L=Bengaluru/O=NA/OU=NA/CN=NA" -batch
              openssl pkcs12 -inkey key.pem -in jenkins.pem -export -out jenkins.p12 -name jenkins -passout pass:$JENKINS_KEYSTORE_PWD
              mkdir -p /etc/ssl/jenkins/
              mv jenkins.p12 /etc/ssl/jenkins/
              chmod uga+rx /etc/ssl/jenkins/jenkins.p12
              
              # Set up Jenkins environment variable
              echo "Setting up JENKINS_HOME environment variable..."
              echo 'export JENKINS_HOME=/var/lib/jenkins' > /etc/profile.d/jenkins_home.sh
              chmod +x /etc/profile.d/jenkins_home.sh
              source /etc/profile.d/jenkins_home.sh
              
              # Reload systemd and start Jenkins
              echo "Starting Jenkins service..."
              systemctl daemon-reload
              systemctl enable jenkins
              systemctl start jenkins

              # Install Terraform
              echo "Installing Terraform..."
              yum install -y yum-utils
              yum-config-manager --add-repo https://rpm.releases.hashicorp.com/RHEL/hashicorp.repo
              yum -y install terraform

              # Clean up sensitive environment variables
              echo "Cleaning up sensitive environment variables..."
              unset JENKINS_KEYSTORE_PWD
              unset JENKINS_BACKUP_BUCKET

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