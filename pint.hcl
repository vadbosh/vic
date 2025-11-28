prometheus "vmdb" {
  uri     = "https://victoria.wellnessliving.com/select/0/prometheus"
  timeout = "2m"
   headers  = {
    "Authorization" = "Bearer 4IKVJ3oZzhCdEmndwoJSag=="
  }
}

checks {
  disabled = [
    "alerts/external_labels",
    "promql/rate"
  ]
}

check "promql/series" {
  ignoreMetrics = [
    "some_rare_metric_example", 
    ".*_backup_error",
    "this_metric_does_not.*"
  ]
}

