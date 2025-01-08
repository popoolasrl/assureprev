resource "aws_s3_bucket" "primary_bucket" {
  provider = aws.primary
  bucket   = "prevailtest11-${var.firm_id_key}"

  tags = {
    Name = "prevailtest11-${var.firm_id_key}"
    Environment = var.environment
  }
}

resource "aws_s3_bucket_versioning" "primary_versioning" {
  provider = aws.primary
  bucket   = aws_s3_bucket.primary_bucket.id
  versioning_configuration {
    status = "Enabled"
  }
}

# Secondary bucket
resource "aws_s3_bucket" "secondary_bucket" {
  provider = aws.secondary
  bucket   = "prevailtest221-${var.firm_id_key}-replica"

  tags = {
    Name = "prevailtest221-${var.firm_id_key}-replica"
    Environment = var.environment
  }
}

resource "aws_s3_bucket_versioning" "secondary_versioning" {
  provider = aws.secondary
  bucket   = aws_s3_bucket.secondary_bucket.id
  versioning_configuration {
    status = "Enabled"
  }
}

# Secondary bucket policy to allow replication

# resource "aws_s3_bucket_policy" "secondary_bucket_policy" {
#   provider = aws.secondary
#   bucket   = aws_s3_bucket.secondary_bucket.id

#   policy = jsonencode({
#     Version = "2012-10-17"
#     Statement = [
#       {
#         Sid    = "AllowReplication"
#         Effect = "Allow"
#         Principal = {
#           AWS = "arn:aws:iam::762233758283:role/S3ReplicationRole"
#         }
#         Action = [
#           "s3:ReplicateObject",
#           "s3:ReplicateDelete",
#           "s3:ReplicateTags",
#           "s3:ObjectOwnerOverrideToBucketOwner"
#         ]
#         Resource = [
#           "${aws_s3_bucket.secondary_bucket.arn}",
#           "${aws_s3_bucket.secondary_bucket.arn}/*"
#         ]
#       }
#     ]
#   })
# }





resource "aws_s3_bucket_policy" "secondary_bucket_policy" {
  provider = aws.secondary
  bucket   = aws_s3_bucket.secondary_bucket.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "AllowReplication"
        Effect = "Allow"
        Principal = {
          # AWS = "arn:aws:iam::762233758283:role/S3ReplicationRole"
          AWS = "arn:aws:iam::762233758283:role/S3ReplicationRole-${var.firm_id_key}"
          # AWS = var.replication_role_arn      // i will change this if it doesnt work//
        }
        Action = [
          "s3:ReplicateObject",
          "s3:ReplicateDelete",
          "s3:ReplicateTags",
          "s3:PutObject",
          "s3:PutObjectAcl",
          "s3:PutObjectVersionAcl",
          "s3:ObjectOwnerOverrideToBucketOwner"
        ]
        Resource = "${aws_s3_bucket.secondary_bucket.arn}/*"
      }
    ]
  })
}

# Replication configuration
resource "aws_s3_bucket_replication_configuration" "replication" {
  provider = aws.primary
  depends_on = [
    aws_s3_bucket_versioning.primary_versioning,
    aws_s3_bucket_versioning.secondary_versioning
  ]
  
  role   = var.replication_role_arn
  # role   = aws_iam_role.s3_replication.arn
  bucket = aws_s3_bucket.primary_bucket.id

  rule {
    id     = "CrossAccountReplicationRule"
    status = "Enabled"

    destination {
      bucket        = aws_s3_bucket.secondary_bucket.arn
      account       = var.destination_account_id
      storage_class = "GLACIER_IR"
    }
  }
}
