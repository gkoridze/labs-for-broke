resource "aws_s3_bucket" "ignitions" {
  bucket_prefix = "ignitions-kubelius"

  tags = {
    Name        = "ignition bucket"
    Environment = "kubelius"
  }
  depends_on = [aws_instance.gw_instance]
}

resource "aws_s3_object" "control-ignition" {
  for_each       = var.control-instances
  key            = "${each.key}.ign"
  bucket         = aws_s3_bucket.ignitions.id
  content_base64 = data.external.ignition_control[each.key].result.base64
}


resource "aws_iam_role" "ignition_role" {
  name        = "ingition_ec2"
  description = "iam role to retrive ignitions from ec2 instances"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
        Effect = "Allow"
      }
    ]
  })
}

resource "aws_iam_policy" "ignition_ec2" {
  name        = "ignition_ec2"
  description = "iam policy to retrive ignitions from ec2 instances"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "s3:ListBucket",
          "s3:ListObject",
          "s3:GetObject",
        ]
        Resource = [
          aws_s3_bucket.ignitions.arn,
          "${aws_s3_bucket.ignitions.arn}/*"
        ]
        Effect = "Allow"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "igntion_policy" {
  role       = aws_iam_role.ignition_role.name
  policy_arn = aws_iam_policy.ignition_ec2.arn
}
