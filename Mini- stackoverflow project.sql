-- Which tags have the most views ? 
SELECT Distinct tag, SUM(total_views) AS total_views
FROM `jrjames83-1171.sampledata.top_questions`
GROUP BY tag
ORDER BY total_views DESC
LIMIT 10;

-- Which tags have the most views in the last quarter ? 
SELECT DISTINCT tag, SUM(quarter_views) AS quarter_views
FROM `jrjames83-1171.sampledata.top_questions`
WHERE quarter = (SELECT MAX(quarter) FROM `jrjames83-1171.sampledata.top_questions`)
GROUP BY tag
ORDER BY quarter_views DESC
LIMIT 10;

-- Which questions have the most views ?
SELECT DISTINCT title, total_views
FROM `jrjames83-1171.sampledata.top_questions`
ORDER BY total_views DESC
LIMIT 10;


-- Which tags are used together the most ? 
SELECT
    CASE
        WHEN t1.tag < t2.tag THEN t1.tag
        ELSE t2.tag
    END AS tag1,
    CASE
        WHEN t1.tag < t2.tag THEN t2.tag
        ELSE t1.tag
    END AS tag2,
    COUNT(*) AS count
FROM
    `jrjames83-1171.sampledata.top_questions` AS t1
JOIN
    `jrjames83-1171.sampledata.top_questions` AS t2 ON t1.id = t2.id AND t1.tag != t2.tag
GROUP BY tag1, tag2
ORDER BY count DESC
LIMIT 10;



-- Most common words used in stackoverflow titles (top 3 words for every tag)
with base_table as (
SELECT title,tag,id, split(title, " ") as words
FROM `jrjames83-1171.sampledata.top_questions`
),words_table as(
SELECT distinct tag, title , lower(trim(word)) as word
FROM base_table, UNNEST(words) as word
),ranked_words as(
Select 
  tag, 
  wt.word, 
  count(*) as count,
  row_number() OVER( partition by tag order by count(*) DESC ) as tag_word_rank
FROM words_table wt
WHERE wt.word NOT IN ("a","an","and","are","as","at","be","but","by","for","if","in","into","is","it",
"no","not","of","on","or","such","that","the","their","then","there","these","they",
"this","to","was","will","with","you","your")
Group by tag,wt.word
HAVING count > 1 
Order by tag,tag_word_rank
)
SELECT *
FROM ranked_words
WHERE  tag_word_rank <= 3
ORDER BY tag, tag_word_rank






