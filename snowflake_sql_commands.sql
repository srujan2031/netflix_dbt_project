USE ROLE ACCOUNTADMIN;

-- Step 2: Create the 'transform' role and assign it to ACCOUNTADMIN
CREATE ROLE IF NOT EXISTS TRANSFORM;
GRANT ROLE TRANSFORM TO ROLE ACCOUNTADMIN;

-- Step 3: Create a default warehouse
CREATE WAREHOUSE IF NOT EXISTS COMPUTE_WH;
GRANT OPERATE ON WAREHOUSE COMPUTE_WH TO ROLE TRANSFORM;

-- Step 4: Create the 'dbt' user and assign it to the transform role
CREATE USER IF NOT EXISTS dbt
  PASSWORD = 'dbtPassword123'
  LOGIN_NAME = 'dbt'
  MUST_CHANGE_PASSWORD = FALSE
  DEFAULT_WAREHOUSE = COMPUTE_WH
  DEFAULT_ROLE = TRANSFORM
  DEFAULT_NAMESPACE = MOVIELENS.RAW
  COMMENT = 'dbt user used for data transformation';

ALTER USER dbt SET TYPE = LEGACY_SERVICE;
GRANT ROLE TRANSFORM TO USER dbt;
-- Step 5: Create a database and schema for the MovieLens project
CREATE DATABASE IF NOT EXISTS MOVIELENS;
CREATE SCHEMA IF NOT EXISTS MOVIELENS.RAW;

-- Step 6: Grant permissions to the 'transform' role
GRANT ALL ON WAREHOUSE COMPUTE_WH TO ROLE TRANSFORM;
GRANT ALL ON DATABASE MOVIELENS TO ROLE TRANSFORM;
GRANT ALL ON ALL SCHEMAS IN DATABASE MOVIELENS TO ROLE TRANSFORM;
GRANT ALL ON FUTURE SCHEMAS IN DATABASE MOVIELENS TO ROLE TRANSFORM;
GRANT ALL ON ALL TABLES IN SCHEMA MOVIELENS.RAW TO ROLE TRANSFORM;
GRANT ALL ON FUTURE TABLES IN SCHEMA MOVIELENS.RAW TO ROLE TRANSFORM;

select * from MOVIELENS.DEV.FACT_RATINGS
ORDER BY RATING_TIMESTAMP DESC
LIMIT 5
SELECT * 
FROM MOVIELENS.DEV.SRC_RATINGS
ORDER BY rating_timestamp DESC
LIMIT 5;
-- Insert a new test row into source ratings
INSERT INTO MOVIELENS.DEV.SRC_RATINGS (user_id, movie_id, rating, rating_timestamp)
VALUES (87587, 7151, '4.0', '2015-03-31 23:40:02.000 -0700');

select * from snapshots.snap_tags
where user_id=18
order by user_id, dbt_valid_from desc

UPDATE src_tags
SET tag = 'Mark Waters Returns', tag_timestamp = CAST(CURRENT_TIMESTAMP() AS TIMESTAMP_NTZ)
WHERE user_id = 18;

SELECT * FROM dev.src_tags
ORDER BY user_id DESC;

CREATE or replace TABLE movie_analysis AS (
  WITH ratings_summary AS (
    SELECT
      movie_id,
      AVG(rating) AS average_rating,
      COUNT(*) AS total_ratings
    FROM MOVIELENS.DEV.fact_ratings
    GROUP BY movie_id
    HAVING COUNT(*) > 100  -- Only movies with at least 100 ratings
  )
  SELECT
    m.movie_title,
    rs.average_rating,
    rs.total_ratings
  FROM ratings_summary rs
  JOIN MOVIELENS.DEV.dim_movies m
    ON m.movie_id = rs.movie_id
  ORDER BY rs.average_rating DESC
  LIMIT 20
);
CREATE OR REPLACE TABLE genre_rating_distribution AS
SELECT
    genre.value::STRING AS genre,
    AVG(r.rating) AS average_rating,
    COUNT(DISTINCT m.movie_id) AS total_movies
FROM dim_movies m
JOIN fact_ratings r
  ON m.movie_id = r.movie_id,
LATERAL FLATTEN(input => SPLIT(m.genres, '|')) AS genre
GROUP BY genre
ORDER BY average_rating DESC;
CREATE OR REPLACE TABLE user_engagement_summary AS
SELECT
    user_id,
    COUNT(*) AS number_of_ratings,
    AVG(rating) AS average_rating_given
FROM fact_ratings
GROUP BY user_id
ORDER BY number_of_ratings DESC
LIMIT 20;

CREATE OR REPLACE TABLE movie_release_trends AS
SELECT
    EXTRACT(year FROM release_date) AS release_year,
    COUNT(DISTINCT movie_id) AS movies_released
FROM seed_movie_release_dates
GROUP BY release_year
ORDER BY release_year ASC;

CREATE OR REPLACE TABLE tag_relevance_analysis AS
SELECT
    t.tag_name,
    AVG(gs.relevance_score) AS avg_relevance,
    COUNT(DISTINCT gs.movie_id) AS movies_tagged
FROM fact_genome_scores gs
JOIN dim_genome_tags t
  ON gs.tag_id = t.tag_id
GROUP BY t.tag_name
ORDER BY avg_relevance DESC
LIMIT 20;
