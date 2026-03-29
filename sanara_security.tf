resource "aws_s3_bucket" "_access_logs" {
  bucket_prefix = "-access-logs-"
}

resource "aws_s3_bucket_logging" "_logging" {
  bucket        = aws_s3_bucket..id
  target_bucket = aws_s3_bucket._access_logs.id
  target_prefix = "logs/"
}

resource "aws_s3_bucket_ownership_controls" "_ownership_controls" {
  bucket = aws_s3_bucket..id
  rule {
    object_ownership = "BucketOwnerEnforced"
  }
}

resource "aws_sns_topic" "_events" {
  name = "-events"
}

resource "aws_sns_topic_policy" "_events_policy" {
  arn = aws_sns_topic._events.arn
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid       = "AllowS3Publish"
        Effect    = "Allow"
        Principal = { Service = "s3.amazonaws.com" }
        Action    = "SNS:Publish"
        Resource  = aws_sns_topic._events.arn
        Condition = {
          ArnLike = {
            "aws:SourceArn" = aws_s3_bucket..arn
          }
        }
      }
    ]
  })
}

resource "aws_s3_bucket_notification" "_notifications" {
  bucket = aws_s3_bucket..id
  topic {
    topic_arn = aws_sns_topic._events.arn
    events    = ["s3:ObjectCreated:*"]
  }
  depends_on = [aws_sns_topic_policy._events_policy]
}

resource "aws_s3_bucket_public_access_block" "_pab" {
  bucket = aws_s3_bucket..id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_server_side_encryption_configuration" "_sse" {
  bucket = aws_s3_bucket..id
  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm     = "aws:kms"
      kms_master_key_id = "alias/aws/s3"
    }
  }
}

resource "aws_s3_bucket_versioning" "_versioning" {
  bucket = aws_s3_bucket..id
  versioning_configuration {
    status = "Enabled"
  }
}
