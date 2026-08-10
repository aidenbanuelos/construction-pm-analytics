-- Finding 3a: how old are currently-open tasks, bucketed.
-- Becuase data is from 2019-2020, I reported how old it is compared to the last data entry date

with tasks as (
    select * from {{ ref('stg_tasks') }}
),

snapshot as (
    select max(created_date) as snapshot_date from tasks
),

open_tasks as (
    select
        t.*,
        date_diff(s.snapshot_date, t.created_date, day) as age_days
    from tasks t
    cross join snapshot s
    where t.report_status = 'Open'
)

select
    case
        when age_days <= 30 then '0-30 days'
        when age_days <= 60 then '31-60 days'
        when age_days <= 90 then '61-90 days'
        else '90+ days'
    end as aging_bucket,
    count(*) as task_count
from open_tasks
group by aging_bucket
order by aging_bucket
