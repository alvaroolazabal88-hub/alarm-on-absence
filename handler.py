import json
import os
import time
import urllib.request
import boto3

USGS_URL = "https://earthquake.usgs.gov/earthquakes/feed/v1.0/summary/all_hour.geojson"
NAMESPACE = "AlarmOnAbsence"

BUCKET = os.environ["DATA_BUCKET"]

cloudwatch = boto3.client("cloudwatch")
s3 = boto3.client("s3")


def publish_metric(name, value):
    cloudwatch.put_metric_data(
        Namespace=NAMESPACE,
        MetricData=[
            {"MetricName": name, "Value": value, "Unit": "Count"}
        ],
    )


def handler(event, context):
    publish_metric("FetchesCompleted", 1)

    try:
        with urllib.request.urlopen(USGS_URL, timeout=10) as response:
            raw = response.read()
        payload = json.loads(raw)
        records = payload.get("features", [])
    except OSError as error:
        print(f"Failed to fetch USGS feed: {error}")
        return {"fetched": True, "records_written": 0, "error": str(error)}

    timestamp = time.strftime("%Y/%m/%d/%H%M%S", time.gmtime())
    key = f"records/{timestamp}.json"

    s3.put_object(Bucket=BUCKET, Key=key, Body=raw, ContentType="application/json")

    publish_metric("RecordsWritten", len(records))
    return {"fetched": True, "records_written": len(records), "s3_key": key}