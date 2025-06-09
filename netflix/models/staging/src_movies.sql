with raw_movies as (
    select * from {{source('netflix','r_movies')}}
)
select 
    movieId as movie_id,
    title,
    genres
from raw_movies
