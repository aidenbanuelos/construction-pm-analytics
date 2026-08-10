-- Finding 2: what share of "Safety" tasks are positive observations
-- vs actual issues, so raw Safety counts aren't mistaken for defects.

with tasks as (
    select * from {{ ref('stg_tasks') }}
),

safety as (
    select * from tasks where task_group = 'Safety'
)

select
    count(*) as total_safety_tasks,
    countif(status = 'EHS Good Observation') as good_observations,
    countif(status != 'EHS Good Observation') as actual_issues,
    round(countif(status = 'EHS Good Observation') / count(*) * 100, 1) as good_observation_pct
from safety
