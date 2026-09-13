# Proof: the alarms fire on absence, not just on failure

This is the transcript of the deliberate kill-switch test — the schedule was
disabled on purpose, and both alarms are shown transitioning from `OK` to
`ALARM` because data stopped arriving, not because of a bad value.

## Timeline

| Time (UTC) | Event |
|---|---|
| 04:15 – 04:45 | Normal operation. Lambda invoked every 15 min, both metrics published. |
| ~04:50 | `aws_scheduler_schedule.ingest` set to `state = "DISABLED"` via Terraform. |
| 04:45 | **Last real invocation.** No invocation happens after this point. |
| ~05:00, ~05:15 | Empty 15-minute windows begin accumulating with no data published. |
| **05:31:22** | `alarm-on-absence-no-writing-data`: **OK → ALARM** |
| **05:31:42** | `alarm-on-absence-not-invoked`: **OK → ALARM** |

Both alarms fired roughly 46 minutes after the last real invocation — one
full missing period plus CloudWatch's own evaluation lag on top of it, which
matches the mechanism documented for `treat_missing_data`.

## The alarm reason, verbatim

```
Threshold Crossed: no datapoints were received for 1 period and 1 missing
datapoint was treated as [Breaching].
```

Not "a value crossed a threshold." **No data arrived, and the absence itself
was treated as the failure.** This is the entire thesis of the project,
confirmed by AWS's own evaluation engine, not by anything I asserted.

## Full CloudWatch alarm history

```
alarm-on-absence-not-invoked
  Alarm updated from ALARM to OK              2026-09-12T17:42:42.572000-04:00
  Alarm updated from OK to ALARM              2026-09-12T01:31:42.573000-04:00
  Alarm updated from INSUFFICIENT_DATA to OK  2026-09-12T00:29:42.571000-04:00

alarm-on-absence-no-writing-data
  Alarm updated from ALARM to OK              2026-09-12T17:42:22.557000-04:00
  Alarm updated from OK to ALARM              2026-09-12T01:31:22.555000-04:00
  Alarm updated from INSUFFICIENT_DATA to OK  2026-09-12T00:29:22.557000-04:00
```

The `state = "DISABLED"` was reverted to `"ENABLED"` after the test. Both
alarms cleared themselves — `ALARM → OK` — the moment real invocations
resumed, with no manual intervention on the alarms at all. The full
lifecycle a system like this is supposed to go through, observed end to
end: healthy, broken on purpose, detected, recovered.

## What this does *not* prove

The SNS notification itself never arrived — that failure mode is documented
separately in `TROUBLESHOOTING.md`, ruled out on every cause checkable from
this end, and reported to AWS re:Post. The alarm mechanism is proven
independent of that: state transitions are read directly from CloudWatch,
not inferred from an email that may or may not show up.

## How to reproduce

```bash
# 1. Disable the trigger
#    (in scheduler.tf: state = "DISABLED", then terraform apply)

# 2. Wait past one full period + evaluation lag (~30-50 min for a 15 min period)

# 3. Read the transition history directly
aws cloudwatch describe-alarm-history \
  --alarm-name alarm-on-absence-not-invoked \
  --history-item-type StateUpdate \
  --query 'AlarmHistoryItems[].{Time:Timestamp,Summary:HistorySummary}' \
  --output table
```
