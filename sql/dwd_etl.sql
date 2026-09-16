DWD
第一步提取炸开数据json
insert overwrite table dwd_base_event_log_inc partition(dt='2025-05-01')
select
get_json_object(base,'$.mid') mid,
get_json_object(base,'$.uid') uid,
get_json_object(base,'$.vc') vc,
get_json_object(base,'$.vn') vn,
get_json_object(base,'$.lan') lan,
get_json_object(base,'$.source') source,
get_json_object(base,'$.os') os,
get_json_object(base,'$.area') area,
get_json_object(base,'$.model') model,
get_json_object(base,'$.brand') brand,
get_json_object(base,'$.resolution') resolution,
get_json_object(base,'$.t') app_time,
get_json_object(base,'$.network') network,
get_json_object(base,'$.lon') lon,
get_json_object(base,'$.lat') lat,
get_json_object(event,'$.event_name') event_name,
get_json_object(event,'$.event_body') event_json,
get_json_object(event,'$.event_time') event_time
from
(
    select
    tmpinner.id,
tmpinner.base,

    events.event
    from
    (
        select
        id,
        base,
        replace(regexp_extract(event_list,'^\\[(.+)\\]$',1),'},{"event_body"', '}||{"event_body"') as event_list
        from ods_event_log_inc where dt='2025-05-01'
    ) tmpinner lateral VIEW outer explode(split(event_list,'\\|\\|')) events AS event
) tmpouter;

第二步 写入dwd，按照json分装事实表，去重空值
insert overwrite table news.dwd_flow_click_inc partition(dt='$dt')
select
mid,uid,vc,vn,lan,source,os,area,model,brand,resolution,app_time,network,lon,lat,
get_json_object(event_json,'$.action') action,
get_json_object(event_json,'$.news_id') news_id,
get_json_object(event_json,'$.order') page_order,
get_json_object(event_json,'$.news_type') news_type,
get_json_object(event_json,'$.exposure_type') exposure_type,
event_time
from
(
    select 
        *,
        row_number() over(partition by mid,event_time order by event_time) rn
    from news.dwd_base_event_log_inc
    where dt='$dt' and event_name='click'
    --这里做基础脏数据过滤
    and mid is not null and length(mid)>0
) t
where t.rn = 1 --只取第一条，重复数据剔除
and get_json_object(event_json,'$.news_id') != '-1';

insert overwrite table news.dwd_flow_news_detail_inc partition(dt='$dt')
select
mid,uid,vc,vn,lan,source,os,area,model,brand,resolution,app_time,network,lon,lat,
get_json_object(event_json,'$.entrance') entrance,
get_json_object(event_json,'$.action') action,
get_json_object(event_json,'$.news_id') news_id,
get_json_object(event_json,'$.stay_time') stay_time,
get_json_object(event_json,'$.load_time') load_time,
get_json_object(event_json,'$.ecc') ecc,
get_json_object(event_json,'$.news_type') news_type,
event_time
from
(
    select 
        *,
        row_number() over(partition by mid,event_time order by event_time) rn
    from news.dwd_base_event_log_inc
    where dt='$dt' 
      and event_name='news_detail_view'  -- 重点！事件名称：新闻详情浏览
      and mid is not null and length(mid)>0
) t
where t.rn = 1;
