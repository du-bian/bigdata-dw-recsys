CREATE TABLE ods_event_log_inc (
    id STRING,
    base STRING,
    event_list STRING,
    dt STRING
) PARTITIONED BY (dt)
WITH (
    'connector' = 'hive',
    'hive-conf-dir' = '/home/hadoop/app/hive/conf'
);
INSERT INTO ods_event_log_inc
SELECT
    id,
    base,
    event_list,
    dt
FROM kafka_source_table;
