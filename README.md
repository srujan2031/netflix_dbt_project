# Netflix Analytics Pipeline — dbt + Snowflake + S3

[![dbt](https://img.shields.io/badge/dbt-Cloud%20%7C%20Core-orange)](https://www.getdbt.com/)
[![Snowflake](https://img.shields.io/badge/Snowflake-Data%20Cloud-blue)](https://www.snowflake.com/)
[![AWS S3](https://img.shields.io/badge/AWS-S3-green)](https://aws.amazon.com/s3/)

An end-to-end ELT pipeline that ingests Netflix/MovieLens datasets from Amazon S3 into Snowflake and transforms raw data into analytics-ready models with dbt.

## What this project demonstrates

- Cloud ingestion: S3 → Snowflake via external stages and `COPY INTO`
- Layered dbt modeling: raw → staging → dimensions/facts → marts
- Slowly Changing Dimensions (SCD Type 2) with dbt snapshots
- Incremental models for large, frequently-updated tables
- 14+ dbt data-quality tests (uniqueness, not-null, referential integrity, accepted values)
- Role-based access control and warehouse provisioning in Snowflake

## Architecture

```
Netflix CSVs
    ↓
Amazon S3 (raw landing zone)
    ↓
Snowflake external stage
    ↓
Raw tables (COPY INTO)
    ↓
dbt staging models (cleaned, typed, renamed)
    ↓
Dimension & fact models
    ↓
dbt snapshots (SCD Type 2 history)
    ↓
Mart models (analysis-ready)
    ↓
BI layer (Looker Studio / Power BI / Tableau)
```

## Tech stack

| Layer        | Tool                          |
|--------------|-------------------------------|
| Storage      | Amazon S3                     |
| Warehouse    | Snowflake                     |
| Transform    | dbt Core + dbt-snowflake      |
| Language     | SQL, Python (venv)            |
| Versioning   | Git                           |
| BI           | Looker Studio                 |

## Dataset

Open-source MovieLens data (Netflix-style), stored as CSV in S3:

| File | Contents |
|------|----------|
| `movies.csv` | Movie ID, title, genres |
| `ratings.csv` | User ratings with timestamps |
| `tags.csv` | User-submitted tags |
| `genome_scores.csv` / `genome_tags.csv` | Tag relevance scores |
| `links.csv` | Movie IDs mapped to IMDb / TMDb |

## Getting started

### Prerequisites

- AWS account with an S3 bucket containing the CSV files
- Snowflake account with `ACCOUNTADMIN` (or equivalent) access
- Python 3.9+ and dbt Core

### 1. Clone the repo

```bash
git clone https://github.com/srujan2031/netflix_dbt_project.git
cd netflix_dbt_project
```

### 2. Upload data to S3

Upload all CSV files to your S3 bucket (e.g. `s3://netflixdataset-srujan/`).

### 3. Set up Snowflake

Run the statements in `snowflake_sql_commands.sql`. It provisions:

- `TRANSFORM` role with least-privilege grants
- `COMPUTE_WH` warehouse
- `MOVIELENS` database with `RAW` schema
- External stage pointing at your S3 bucket
- Raw tables loaded via `COPY INTO`

> Credentials are passed via environment variables — never hardcoded. See `.env.example`.

### 4. Configure dbt

```bash
python -m venv venv
source venv/bin/activate
pip install dbt-core dbt-snowflake
```

Create `~/.dbt/profiles.yml`:

```yaml
netflix_dbt_project:
  target: dev
  outputs:
    dev:
      type: snowflake
      account: "{{ env_var('SNOWFLAKE_ACCOUNT') }}"
      user: "{{ env_var('SNOWFLAKE_USER') }}"
      password: "{{ env_var('SNOWFLAKE_PASSWORD') }}"
      role: TRANSFORM
      database: MOVIELENS
      warehouse: COMPUTE_WH
      schema: DEV
```

### 5. Run the pipeline

```bash
dbt deps        # install package dependencies
dbt seed        # load seed files (if any)
dbt run         # build all models (incremental where configured)
dbt snapshot    # capture SCD Type 2 history
dbt test        # run 14+ data-quality tests
```

### 6. Visualize

Connect Looker Studio (or Power BI / Tableau) to the `MOVIELENS` database and build on the mart models: `movie_analysis`, `genre_rating_distribution`, `user_engagement_summary`, `tag_relevance_analysis`, `movie_release_trends`.

## Project structure

```
netflix_dbt_project/
├── models/
│   ├── raw/          # source-aligned models
│   ├── staging/      # cleaned, tested staging layer
│   ├── dim/          # dimension tables
│   ├── fact/         # fact tables
│   └── mart/         # analysis-ready marts
├── snapshots/        # SCD Type 2 snapshot definitions
├── macros/           # reusable Jinja macros
├── seeds/            # static seed data
├── tests/            # custom data tests
├── dbt_project.yml
└── snowflake_sql_commands.sql
```

## Design decisions

- **Incremental models** on large tables (`src_ratings`) to avoid full refreshes on every run.
- **dbt snapshots** on `src_tags` for SCD Type 2 change tracking without manual history tables.
- **Layered modeling** (raw → staging → dim/fact → mart) so each layer has a single responsibility and failures are easy to isolate.
- **Tests as contracts**: uniqueness, not-null, and relationship tests run on every `dbt test`, catching bad data before it reaches marts.

## Future improvements

- [ ] CI with GitHub Actions (`dbt build` on every PR)
- [ ] dbt docs site published via GitHub Pages
- [ ] Airflow orchestration for scheduled runs

## Author

**Srujan Chinta** — Data Engineer
[LinkedIn](https://www.linkedin.com/in/srujanchinta7) · srujanchinta7@gmail.com
