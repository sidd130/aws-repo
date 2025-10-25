data "aws_iam_policy_document" "jenkins_kms_policy" {
  version = "2012-10-17"
  policy_id = "key-consolepolicy-3"

  # Enable IAM User Permissions
  statement {
    sid    = "Enable IAM User Permissions"
    effect = "Allow"
    principals {
      type = "AWS"
      identifiers = ["arn:aws:iam::${var.account_id}:root"]
    }
    actions   = ["kms:*"]
    resources = ["*"]
  }

  # Allow access for Key Administrators
  statement {
    sid    = "Allow access for Key Administrators"
    effect = "Allow"
    principals {
      type = "AWS"
      identifiers = ["arn:aws:iam::${var.account_id}:user/siddas"]
    }
    actions = [
      "kms:Create*",
      "kms:Describe*",
      "kms:Enable*",
      "kms:List*",
      "kms:Put*",
      "kms:Update*",
      "kms:Revoke*",
      "kms:Disable*",
      "kms:Get*",
      "kms:Delete*",
      "kms:TagResource",
      "kms:UntagResource",
      "kms:ScheduleKeyDeletion",
      "kms:CancelKeyDeletion",
      "kms:RotateKeyOnDemand"
    ]
    resources = ["*"]
  }

  # Allow use of the key
  statement {
    sid    = "Allow use of the key"
    effect = "Allow"
    principals {
      type = "AWS"
      identifiers = ["arn:aws:iam::${var.account_id}:user/siddas"]
    }
    actions = [
      "kms:Encrypt",
      "kms:Decrypt",
      "kms:ReEncrypt*",
      "kms:GenerateDataKey*",
      "kms:DescribeKey"
    ]
    resources = ["*"]
  }

  # Allow attachment of persistent resources
  statement {
    sid    = "Allow attachment of persistent resources"
    effect = "Allow"
    principals {
      type = "AWS"
      identifiers = ["arn:aws:iam::${var.account_id}:user/siddas"]
    }
    actions = [
      "kms:CreateGrant",
      "kms:ListGrants",
      "kms:RevokeGrant"
    ]
    resources = ["*"]
    condition {
      test     = "Bool"
      variable = "kms:GrantIsForAWSResource"
      values   = ["true"]
    }
  }

  # Privilege for Jenkins EC2 instance profile
  statement {
    sid    = "Privilege for Jenkins EC2 instance profile"
    effect = "Allow"
    principals {
      type = "AWS"
      identifiers = ["arn:aws:iam::${var.account_id}:role/jenkins-ec2-role"]
    }
    actions = [
      "kms:Encrypt",
      "kms:Decrypt",
      "kms:ReEncrypt*",
      "kms:GenerateDataKey*",
      "kms:DescribeKey"
    ]
    resources = ["*"]
  }
}