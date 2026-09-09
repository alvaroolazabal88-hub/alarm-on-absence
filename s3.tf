resource "aws_s3_bucket" "s3_alarm_on_absence" {
  bucket = "s3-data-alarm-on-absence-0263443218"
}

resource "aws_s3_bucket_versioning" "s3_alarm_on_absence" {
  bucket = aws_s3_bucket.s3_alarm_on_absence.id

  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "s3_alarm_on_absence" {
  bucket = aws_s3_bucket.s3_alarm_on_absence.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}
resource "aws_s3_bucket_public_access_block" "s3_alarm_on_absence" {
  bucket = aws_s3_bucket.s3_alarm_on_absence.id

  block_public_acls       = true
  ignore_public_acls      = true
  block_public_policy     = true
  restrict_public_buckets = true
}