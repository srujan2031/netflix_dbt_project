WITH fact_movie_w_tags AS (
    SELECT * FROM {{ ref('dim_movies_with_tags') }}
)

SELECT * FROM fact_movie_w_tags
