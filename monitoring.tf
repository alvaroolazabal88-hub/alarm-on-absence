resource "aws_cloudwatch_metric_alarm" "not_invoked" {
  alarm_name          = "alarm-on-absence-not-invoked"
  alarm_description   = "The schedule stopped firing: no invocations in the last 15 minutes."
  namespace           = "AlarmOnAbsence"
  metric_name         = "FetchesCompleted"
  statistic           = "Sum"
  period              = 900
  evaluation_periods  = 1
  threshold           = 1
  comparison_operator = "LessThanThreshold"
  treat_missing_data  = "breaching"
  alarm_actions       = [aws_sns_topic.alerts.arn]
}

resource "aws_cloudwatch_metric_alarm" "not_writing" {
  alarm_name          = "alarm-on-absence-no-writing-data"
  alarm_description   = "The Lambda did not put data in S3 bucket for the last 15 minutes."
  namespace           = "AlarmOnAbsence"
  metric_name         = "RecordsWritten"
  statistic           = "Sum"
  period              = 900
  evaluation_periods  = 1
  threshold           = 1
  comparison_operator = "LessThanThreshold"
  treat_missing_data  = "breaching"
  alarm_actions       = [aws_sns_topic.alerts.arn]
}