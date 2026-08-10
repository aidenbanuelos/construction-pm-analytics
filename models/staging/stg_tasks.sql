-- models/staging/stg_tasks.sql
--
-- Staging model for construction.tasks (raw BigQuery table).
-- Job: type-cast and standardize only. No business logic, no filtering,
-- no aggregation — that belongs in mart models downstream.

with source as (

    select * from {{ source('construction', 'tasks') }}

),

renamed as (

    select
        Ref                as task_ref,
        Status              as status,
        Location            as location,
        Description         as description,
        Type                as type,

        -- Trade package had 3 naming variants for the same trade
        -- (Internal Partitions & Ceilings / Ceilings & Partitions /
        -- Partitions & Ceilings) plus 1,042 nulls. Both are cleaned
        -- here so no downstream query silently undercounts a trade
        -- or drops unassigned tasks from analysis.
        case
            when `To Package` in (
                'Internal Partitions & Ceilings',
                'Ceilings & Partitions',
                'Partitions & Ceilings'
            ) then 'Partitions & Ceilings'
            when `To Package` is null then 'Unassigned'
            else `To Package`
        end as trade_package,

        Association         as association,
        OverDue             as is_overdue,
        Images              as has_images,
        Comments            as has_comments,
        Documents           as has_documents,
        Cause               as cause,
        project             as project_id,
        `Report Status`     as report_status,
        `Task Group`        as task_group,

        Created             as created_date,
        `Status Changed`    as status_changed_date,

        date_add(date '1899-12-30', interval Target day) as target_date,

        Priority as priority_raw

    from source

),

priority_split as (

    select
        *,

        case
            when priority_raw in ('High', 'High (resolve within 48 hours)') then 'High'
            when priority_raw in ('Medium', 'Medium (resolve within 5 days)') then 'Medium'
            when priority_raw in ('Low', 'Low (resolve within 2 weeks)') then 'Low'
            else null
        end as priority_level,

        case
            when priority_raw in (
                'Behavioural Failure',
                'System Failure',
                'System Failure - Deviation from RAMS / Manufacturer Instructions'
            ) then priority_raw
            when priority_raw = 'Best Practice' then 'Best Practice'
            else null
        end as safety_incident_classification,

        case
            when priority_raw in ('2 Week Look Ahead', '1 Week Look Ahead', '1 Month Look Ahead')
                then priority_raw
            else null
        end as lookahead_tag,

        case
            when priority_raw = '.' then true
            else false
        end as priority_is_data_error

    from renamed

)

select * from priority_split
