-- Finding 1: monthly task volume, flagging Ireland's mandated
-- construction shutdown period (28 Mar - 18 May 2020).

with tasks as (
    select * from {{ ref('stg_tasks') }}
),

monthly as (
    select
        format_date('%Y-%m', created_date) as month,
        count(*) as task_count
    from tasks
    group by month
)

select
    month,
    task_count,
    case
        when month in ('2020-03', '2020-04', '2020-05') then true
        else false
    end as during_shutdown_period
from monthly
order by month
