# IAM Role for DLM
resource "aws_iam_role" "dlm_role" {
  name = "${var.project_name}-dlm-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "dlm.amazonaws.com"
        }
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "dlm" {
  role       = aws_iam_role.dlm_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSDataLifecycleManagerServiceRole"
}

# DLM Lifecycle Policy for EBS Snapshots
resource "aws_dlm_lifecycle_policy" "ebs_snapshots" {
  description        = "${var.project_name} - Daily EBS snapshots with 30-day retention"
  execution_role_arn = aws_iam_role.dlm_role.arn
  state              = "ENABLED"

  policy_details {
    resource_types = ["VOLUME"]

    schedule {
      name = "Daily snapshots"

      create_rule {
        interval      = 24
        interval_unit = "HOURS"
        times         = ["03:00"] # 3 AM UTC
      }

      retain_rule {
        count = 30 # Keep 30 snapshots (30 days)
      }

      tags_to_add = {
        SnapshotCreator = "DLM"
        Project         = var.project_name
      }

      copy_tags = true
    }

    target_tags = {
      Name = "${var.project_name}-data"
    }
  }

  tags = {
    Name = "${var.project_name}-dlm-policy"
  }
}
