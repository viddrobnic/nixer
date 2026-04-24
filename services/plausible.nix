{ ... }:
{
  virtualisation.oci-containers.containers = {
    plausible-db = {
      image = "postgres:16-alpine";
      autoStart = true;

      volumes = [
        "plausible-db-data:/var/lib/postgresql/data"
      ];

      environment = {
        POSTGRES_PASSWORD = "postgres";
      };
    };

    plausible-events-db = {
      image = "clickhouse/clickhouse-server:24.12-alpine";
      autoStart = true;

      volumes = [
        "plausible-event-data:/var/lib/clickhouse"
        "plausible-event-logs:/var/log/clickhouse-server"
        "/etc/plausible-clickhouse/config.xml:/etc/clickhouse-server/config.d/config.xml:ro"
      ];

      environment = {
        CLICKHOUSE_SKIP_USER_SETUP = "1";
      };
    };

    plausible = {
      image = "ghcr.io/plausible/community-edition:v3.2.0";
      autoStart = true;
      cmd = [
        "sh"
        "-c"
        "/entrypoint.sh db createdb && /entrypoint.sh db migrate && /entrypoint.sh run"
      ];

      dependsOn = [
        "plausible-db"
        "plausible-events-db"
      ];

      volumes = [
        "plausible-data:/var/lib/plausible"
      ];

      environment = {
        TMPDIR = "/var/lib/plausible/tmp";
        BASE_URL = "https://a.viddrobnic.com";
        HTTP_PORT = "8001";

        DATABASE_URL = "postgres://postgres:postgres@plausible-db:5432/plausible_db";
        CLICKHOUSE_DATABASE_URL = "http://plausible-events-db:8123/plausible_events_db";
      };
      environmentFiles = [
        "/var/lib/secrets/plausible"
      ];

      ports = [ "8001:8001" ];
    };
  };

  environment.etc.plausible-clickhouse = {
    group = "plausible";
    user = "plausible";
    target = "plausible-clickhouse/config.xml";

    text = ''
      <clickhouse>
        <listen_host>0.0.0.0</listen_host>

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
  };

  services.caddy.virtualHosts."a.viddrobnic.com" = {
    extraConfig = ''
      encode zstd gzip
      reverse_proxy * :8001
    '';
  };
}
