# Construction Project Management Analytics

A raw-to-insight data pipeline built in BigQuery + dbt, analyzing 12,424 field tasks from 8 real Irish construction projects (2019–2020) to surface operational risk that isn't visible at a surface-level glance.

**Data source:** [Construction/Project Management Report Examples](https://www.kaggle.com/datasets/claytonmiller/construction-and-project-management-example-data) (Kaggle), donated by a BIM manager from a real field-app export.



## Summary

COVID caused a real disruption and recovery surge in field activity. The apparent "safety problem" is partly an illusion of raw numbers. And roughly 1 in 5 open issues are stuck long-term, with accountability gaps, unassigned tasks, and inconsistent trade naming hiding real risk that can completely miss.


## Finding 1 — Field activity nearly stopped during Ireland's COVID lockdown, then surged once it reopened

<img width="1500" height="750" alt="Monthly Volume Chart" src="https://github.com/user-attachments/assets/f47a455a-fe50-4bf5-abeb-0373be6c9e98" />


In March 2020, workers were logging almost 1,000 inspection/safety/quality tasks a month. Then Ireland shut down construction sites nationwide starting March 28th. In April, that number crashed to 355, a 63% drop, basically the site went quiet. Once things reopened in May, activity didn't just recover, it exploded and by June, teams were logging over 1,700 tasks a month, nearly double what was normal before COVID. The shutdown created a backlog of catch-up work.

*Model: [`mart_monthly_volume.sql`](models/marts/mart_monthly_volume.sql)*


## Finding 2 — Most "safety issues" on this project aren't actually issues

<img width="900" height="900" alt="Safety Composition Chart" src="https://github.com/user-attachments/assets/eaf756ca-c543-42fd-94a4-2f6bd2cb6136" />


71% of everything logged in this system falls under "Safety." Sounds alarming at first. But dig one level deeper and of those 8,884 safety entries, 3,343 of them (37.6%) are labeled "Good Observation" meaning someone saw a worker doing something right (wearing the right gear, following procedure correctly) and logged it as a positive note, not a problem. So a little over a third of "safety issues" are actually compliments, not complaints. If you only looked at the raw count, you'd wrongly conclude the site is dangerous when it's actually well monitored.

*Model: [`mart_safety_composition.sql`](models/marts/mart_safety_composition.sql)*


## Finding 3 — Most open issues get closed fast, but a real chunk is stuck for months

<img width="1200" height="750" alt="Backlog Aging Chart" src="https://github.com/user-attachments/assets/07199aa5-ee47-4308-95e1-9bda5ee12c0f" />


Of everything still open, half (742 tasks) are less than 30 days old, a normal and healthy turnaround. But 294 tasks (about 1 in 5 open items) have been sitting unresolved for over 90 days. Some go back over a year. That's the difference between "business as usual" and "things are falling through the cracks." A healthy project has some backlog.

*Model: [`mart_backlog_aging.sql`](models/marts/mart_backlog_aging.sql)*


## Finding 4 — One contractor owns most of the old, stuck problems — but there's a bigger issue hiding underneath

<img width="1350" height="825" alt="Backlog by Package Chart" src="https://github.com/user-attachments/assets/594cd6da-4d19-47ba-8270-96277650a8b0" />


Of those 294 old, unresolved tasks, 100 of them (about a third) belong to a single group: the Main Contractor. That's the headline. But two things caught while checking the data are honestly more interesting:

- **29 of those old, stuck tasks have no trade assigned to them at all** and nobody's name is on them. That's arguably worse than any single slow contractor, there's no accountability path at all for almost 30 chronically unresolved problems.
- **The exact same trade (partitions and ceiling work) was logged under three different names** by different people filling out the field app  "Internal Partitions & Ceilings," "Ceilings & Partitions," and "Partitions & Ceilings." Until you catch that and combine them, it looks like three small, unremarkable trades. Combined, it's actually a top 6 problem area. If you hadn't asked about it, that would've stayed invisible.

*Model: [`mart_backlog_by_package.sql`](models/marts/mart_backlog_by_package.sql)*


## Data quality notes

Issues found and handled in the staging layer ([`stg_tasks.sql`](models/staging/stg_tasks.sql)):

- **`Target` was an Excel serial date, not a real date.** Stored as raw day-counts since 1899-12-30 (Excel's internal date format), not a proper date type. 
- **`Priority` mixed three unrelated concepts in one column** , actual priority level (High/Medium/Low), safety incident classification (Behavioural/System Failure), and planning lookahead tags. Split into separate typed columns.
- **Trade package had three naming variants for the same trade** — "Internal Partitions & Ceilings," "Ceilings & Partitions," and "Partitions & Ceilings" all refer to the same work, logged inconsistently. Normalized this in staging; without this, the trade would rank far lower than it actually is.
- **1,042 tasks had no trade package assigned.** Labeled explicitly as `Unassigned` rather than left blank, since a blank category disappears from analysis instead of surfacing as its own finding.
- **`task_ref` is not globally unique**, the same reference number can appear in multiple different projects. The true unique key is `task_ref` + `project_id` together.
- **No clean join key exists between the Forms and Tasks tables.** ~75% of tasks originate from a checklist answer (`Association = FormAnswer`), but no Form reference is stored on the Task row — any join would have to be inferred by project, location, and date proximity, not a real foreign key.

---

## Tech stack

BigQuery (warehouse) · dbt (transformation, testing) · Python/pandas (validation, chart generation)
