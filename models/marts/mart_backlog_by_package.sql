-- Finding 3b: which trade packages own the unresolved
-- (90+ day) open tasks. Separate model from aging buckets above
-- because this answers a different question of who and not how old

with tasks as (
    select * from {{ ref('stg_tasks') }}
),

snapshot as (
    select max(created_date) as snapshot_date from tasks
),

open_90plus as (
    select
        t.*,
        date_diff(s.snapshot_date, t.created_date, day) as age_days
    from tasks t
    cross join snapshot s
    where t.report_status = 'Open'
)

select
    trade_package,
    count(*) as overdue_90plus_count
from open_90plus
where age_days > 90
group by trade_package
order by overdue_90plus_count desc
limit 10
