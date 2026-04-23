{ ... }:
{
  services.plausible = {
    enable = true;

    server = {
      baseUrl = "https://a.viddrobnic.com";
      port = 8001;
      secretKeybaseFile = "/var/lib/secrets/plausible-secret-key-base";
    };
  };

  services.clickhouse.extraServerConfig = ''
    <clickhouse>
      <profiles>
        <default>
          <!-- https://clickhouse.com/docs/en/operations/settings/settings#max_threads -->
          <max_threads>1</max_threads>
          <!-- https://clickhouse.com/docs/en/operations/settings/settings#max_block_size -->
          <max_block_size>8192</max_block_size>
          <!-- https://clickhouse.com/docs/en/operations/settings/settings#max_download_threads -->
          <max_download_threads>1</max_download_threads>
          <!-- https://clickhouse.com/docs/en/operations/settings/settings#input_format_parallel_parsing -->
          <input_format_parallel_parsing>0</input_format_parallel_parsing>
          <!-- https://clickhouse.com/docs/en/operations/settings/settings#output_format_parallel_formatting -->
          <output_format_parallel_formatting>0</output_format_parallel_formatting>
        </default>
      </profiles>

      <logger>
        <level>warning</level>
        <console>true</console>
      </logger>

      <query_log replace="1">
        <database>system</database>
        <table>query_log</table>
        <flush_interval_milliseconds>7500</flush_interval_milliseconds>
        <engine>
          ENGINE = MergeTree
          PARTITION BY event_date
          ORDER BY (event_time)
          TTL event_date + interval 30 day
          SETTINGS ttl_only_drop_parts=1
        </engine>
      </query_log>

      <!-- Stops unnecessary logging -->
      <metric_log remove="remove" />
      <asynchronous_metric_log remove="remove" />
      <query_thread_log remove="remove" />
      <text_log remove="remove" />
      <trace_log remove="remove" />
      <session_log remove="remove" />
      <part_log remove="remove" />

      <!-- https://clickhouse.com/docs/en/operations/server-configuration-parameters/settings#mark_cache_size -->
      <mark_cache_size>524288000</mark_cache_size>
    </clickhouse>
  '';

  services.caddy.virtualHosts."a.viddrobnic.com" = {
    extraConfig = ''
      encode zstd gzip
      reverse_proxy * :8001
    '';
  };
}
