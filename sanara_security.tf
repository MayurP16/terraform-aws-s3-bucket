resource "aws_sns_topic" "this_events" {
  name = "this-events"
}

resource "aws_sns_topic_policy" "this_events_policy" {
  arn = aws_sns_topic.this_events.arn
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid       = "AllowS3Publish"
        Effect    = "Allow"
        Principal = { Service = "s3.amazonaws.com" }
        Action    = "SNS:Publish"
        Resource  = aws_sns_topic.this_events.arn
        Condition = {
          ArnLike = {
            "aws:SourceArn" = var.is_directory_bucket ? aws_s3_directory_bucket.this[0].arn : aws_s3_bucket.this[0].arn
          }
        }
      }
    ]
  })
}

resource "aws_s3_bucket_notification" "this_notifications" {
  bucket = var.is_directory_bucket ? aws_s3_directory_bucket.this[0].bucket : aws_s3_bucket.this[0].id
  topic {
    topic_arn = aws_sns_topic.this_events.arn
    events    = ["s3:ObjectCreated:*"]
  }
  depends_on = [aws_sns_topic_policy.this_events_policy]
}

resource "aws_s3_bucket_versioning" "this_versioning" {
  bucket = var.is_directory_bucket ? aws_s3_directory_bucket.this[0].bucket : aws_s3_bucket.this[0].id
  versioning_configuration {
    status = "Enabled"
  }
}
