{ lib }:
{
  telegraf_down = {
    condition = ''min(up{job=~"telegraf",type='server'}) by (source, job, instance, org) == 0'';
    time = "3m";
    description = "{{$labels.instance}}: {{$labels.job}} telegraf exporter from {{$labels.source}} is down";
  };

  prometheus_not_connected_to_alertmanager = {
    condition = "prometheus_notifications_alertmanagers_discovered < 1";
    description = ''
      Prometheus cannot connect the alertmanager
        VALUE = {{ $value }}
        LABELS = {{ $labels }}'';
  };

  connection_failed = {
    condition = "net_response_result_code != 0";
    description = "{{$labels.server}}: connection to {{$labels.port}}({{$labels.protocol}}) failed from {{$labels.instance}}";
  };
}
