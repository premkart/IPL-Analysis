/* Objective questions */
/*Q1  1.	List the different dtypes of columns in table “ball_by_ball” (using information schema)*/
SELECT COLUMN_NAME, DATA_TYPE
FROM INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_NAME = 'ball_by_ball'

/*Q2 2.	What is the total number of run scored in 1st season by RCB (bonus : also include the extra runs using the extra runs table)*/
select sum(bs.Runs_Scored+e.Extra_Runs) as Total_runs_by_RCB 
from ball_by_ball b
 left join batsman_scored bs 
 on b.Match_Id=bs.Match_Id 
 and b.Over_Id=bs.Over_Id 
 and b.Ball_Id=bs.Ball_Id 
 and b.Innings_No=bs.Innings_No
left join extra_runs e on b.Match_Id=e.Match_Id and b.Over_Id=e.Over_Id and b.Ball_Id=e.Ball_Id and b.Innings_No=e.Innings_No
join team t on b.Team_Batting=t.Team_Id
join matches m on  b.Match_Id = m.Match_Id
where m.Season_Id=1;


/*Q3 How many players were more than age of 25 during season 2 ?*/
with cte as (select distinct p.Player_Id, extract(year from p.DOB) as birth_year, s.Season_Year , ABS(s.Season_Year - extract(year from p.DOB)) as age from matches m 
join player_match pm on m.Match_Id=pm.Match_Id
join player p on p.Player_Id=pm.Player_Id
join season s on s.Season_Id=m.Season_Id
where s.Season_Id=2
)
select count(distinct Player_id) as players_were_more_than_age_of_25 from cte c where  age > 25

    
/*Q4 4.	How many matches did RCB win in season 1?*/
select count(*) as RCB_win from matches m join team t on t.Team_Id=m.Team_1
join team t1 on t1.Team_Id=m.Team_2
join win_by w on w.Win_Id=m.win_type
where m.Season_Id=1 and t.Team_Name='Royal Challengers Bangalore';
 

/*Q5 List top 10 players according to their strike rate in last 4 seasons*/

SELECT 
    p.Player_id, 
    p.Player_Name, 
    (SUM(bs.Runs_Scored) * 100.0 / COUNT(b.Ball_Id)) AS Strike_rate
FROM 
    ball_by_ball b
JOIN 
    batsman_scored bs ON b.Match_Id = bs.Match_Id 
    AND b.Over_Id = bs.Over_Id 
    AND b.Ball_Id = bs.Ball_Id
JOIN 
    player_match pm ON pm.Match_Id = b.Match_Id 
    AND pm.Player_Id = b.Striker
join matches m on m.Match_Id=b.Match_Id
JOIN 
    player p ON p.Player_Id = pm.Player_Id
where m.Season_Id in ('6','7','8','9')
GROUP BY 
    p.Player_id, p.Player_Name
order by Strike_rate desc
 limit 10;


/*Q6 6.	What is the average runs scored by each batsman considering all the seasons */
WITH per_player_per_season AS (
  SELECT 
    p.Player_Name AS batsman, 
    m.Season_Id, 
    SUM(bs.Runs_Scored) AS total_runs
  FROM 
    batsman_scored bs 
    JOIN ball_by_ball b ON bs.Match_Id = b.Match_Id 
      AND bs.Over_Id = b.Over_Id 
      AND bs.Ball_Id = b.Ball_Id 
      AND bs.Innings_No = b.Innings_No
    JOIN matches m ON m.Match_Id = bs.Match_Id 
    JOIN player p ON p.Player_Id = b.Striker
  GROUP BY 
    p.Player_Name, 
    m.Season_Id
),
avg_runs1 AS (
  SELECT 
    batsman, 
    AVG(total_runs) AS avg_runs
  FROM 
    per_player_per_season
  WHERE 
    Season_Id <= 9
  GROUP BY 
    batsman
)
SELECT 
  batsman, 
  avg_runs
FROM 
  avg_runs1
ORDER BY 
  avg_runs DESC;

    
/*Q7 .What are the average wickets taken by each bowler considering all the seasons?*/
WITH per_player_per_season AS (
  SELECT 
    p.Player_Name AS bowler_name,
    m.Season_Id,
    COUNT(w.Player_Out) AS total_wickets_taken
  FROM 
    wicket_taken w
  JOIN 
    ball_by_ball b ON b.Match_Id = w.Match_Id 
      AND b.Over_Id = w.Over_Id 
      AND b.Ball_Id = w.Ball_Id 
      AND b.Innings_No = w.Innings_No
  JOIN 
    matches m ON m.Match_Id = w.Match_Id
  JOIN 
    player p ON p.Player_Id = b.Bowler
  GROUP BY 
    p.Player_Name, m.Season_Id
),
avg_wickets1 AS (
  SELECT 
    bowler_name,
    Season_Id,
    AVG(total_wickets_taken) AS avg_wickets
  FROM 
    per_player_per_season
  GROUP BY 
    bowler_name, Season_Id
)
SELECT 
  bowler_name,
  Season_Id,
  avg_wickets
FROM 
  avg_wickets1
ORDER BY 
  avg_wickets desc, bowler_name, Season_Id;



/*Q8 8.	List all the players who have average runs scored greater than overall average and who have taken wickets greater than overall average*/
WITH batsman_stat AS (
  SELECT 
    pm.Player_Id,
    SUM(bs.Runs_Scored) AS total_runs,
    COUNT(b.Match_Id) AS matches_played
  FROM 
    ball_by_ball b
  LEFT JOIN 
    batsman_scored bs ON b.Match_Id = bs.Match_Id 
      AND b.Over_Id = bs.Over_Id 
      AND b.Ball_Id = bs.Ball_Id 
      AND b.Innings_No = bs.Innings_No
  LEFT JOIN 
    player_match pm ON b.Match_Id = pm.Match_Id
  GROUP BY 
    pm.Player_Id
),
bowler_stat AS (
  SELECT 
    pm.Player_Id,
    SUM(w.Player_Out) AS total_wickets_taken,
    COUNT(b.Match_Id) AS matches_played
  FROM 
    ball_by_ball b
  LEFT JOIN 
    wicket_taken w ON w.Match_Id = b.Match_Id 
      AND w.Over_Id = b.Over_Id 
      AND w.Ball_Id = b.Ball_Id 
      AND w.Innings_No = b.Innings_No
  LEFT JOIN 
    player_match pm ON b.Match_Id = pm.Match_Id
  GROUP BY 
    pm.Player_Id
),
overall_avg AS (
  SELECT 
    AVG(bs.total_runs / bs.matches_played) AS overall_avg_runs,
    AVG(bw.total_wickets_taken / bw.matches_played) AS overall_avg_wickets_taken
  FROM 
    batsman_stat bs
  CROSS JOIN 
    bowler_stat bw
)
SELECT 
  p.Player_Name
FROM 
  player p
JOIN 
  batsman_stat bs ON p.Player_Id = bs.Player_Id
JOIN 
  bowler_stat bw ON p.Player_Id = bw.Player_Id
WHERE 
  (bs.total_runs / bs.matches_played) > (SELECT overall_avg_runs FROM overall_avg) 
  AND (bw.total_wickets_taken / bw.matches_played) > (SELECT overall_avg_wickets_taken FROM overall_avg)
ORDER BY 
  p.Player_Name;



/*Q9 Create a table rcb_record table that shows wins and losses of RCB in an individual venue.*/
CREATE TABLE rcb_record AS
SELECT 
    v.Venue_Name,
    s.Season_Id,
    SUM(CASE 
            WHEN (m.Team_1 = 2 OR m.Team_2 = 2) AND m.Match_Winner = 2 THEN 1
            ELSE 0
        END) AS WIN,
    SUM(CASE 
            WHEN (m.Team_1 = 2 OR m.Team_2 = 2) AND m.Match_Winner != 2 THEN 1
            ELSE 0
        END) AS LOSS
FROM Matches m
JOIN Venue v ON m.Venue_Id = v.Venue_Id
JOIN Season s ON m.Season_Id = s.Season_Id
WHERE m.Team_1 = 2 OR m.Team_2 = 2  
GROUP BY v.Venue_Name, s.Season_Id;

select * from rcb_record

/*Q10 What is the impact of bowling style on wickets taken.*/
with bowler_wickets 
as
(select p.Player_Id,bs.Bowling_Skill, count(w.Player_Out)as wickets_taken,
 count(b.Match_Id) as matches_played 
 from ball_by_ball b
 join bowling_style bs 
 on b.Team_Bowling=bs.Bowling_Id
join wicket_taken w on b.Match_Id=w.Match_Id and b.Over_Id=w.Over_Id and b.Ball_Id=w.Ball_Id and b.Innings_No=w.Innings_No
join player_match p on b.Match_Id=p.Match_Id group by 1,2)
select bw.Bowling_Skill,sum(bw.wickets_taken) as total_wickets, count(Player_Id) as no_of_bowlers, avg(wickets_taken) as avg_wickets_per_bowlers,avg(wickets_taken/matches_played) as avg_wickets_per_match
from bowler_wickets bw group by bw.Bowling_Skill, bw.wickets_taken order by avg_wickets_per_match;

/*Q11 11.	Write the sql query to provide a status of whether the performance of the team better than the previous year performance on the basis of number of runs scored by the team in the season and number of wickets taken */
with team_performance as (select m.Season_Id, t.Team_Id,t.Team_Name, count(distinct m.Match_Id) as matches_played, sum(bs.Runs_Scored) as total_runs, sum(w.Player_Out) as total_wickets
 from team t join matches m on t.Team_Id in (m.Team_1,m.Team_2)
 left join ball_by_ball b on b.Match_Id=m.Match_Id and t.Team_Id=b.Team_Batting
 left join batsman_scored bs on bs.Match_Id=b.Match_Id and bs.Over_Id=b.Over_Id and bs.Ball_Id=b.Ball_Id and bs.Innings_No=b.Innings_No
 left join wicket_taken w on w.Match_Id=b.Match_Id and w.Over_Id=b.Over_Id and w.Ball_Id=b.Ball_Id and w.Innings_No=b.Innings_No
 group by 1,2,3),
 performance_comparison as (
 select Season_Id,Team_Id,Team_Name, total_runs,total_wickets, lag(total_runs) over(partition by Team_Id order by Season_Id) as prev_year_runs,
 lag(total_wickets) over(partition by Team_Id order by Season_Id)as prev_year_wickets from team_performance)
 select Season_Id,Team_Name,total_runs,total_wickets, prev_year_runs,prev_year_wickets, 
 case 
    when total_runs > prev_year_runs and total_wickets > prev_year_wickets then 'Better' 
    when total_runs < prev_year_runs and total_wickets < prev_year_wickets then 'Worsed'
    else 'Mixed'
 end  as  Performance_status from performance_comparison 
 where prev_year_runs is not null and prev_year_wickets is not null order by Team_Name,Season_Id;


/*Q12 Can you derive more KPIs for the team strategy if possible?*/
WITH team_performance AS (
    SELECT  
        m.Season_Id, 
        t.Team_Id,
        t.Team_Name, 
        COUNT(DISTINCT m.Match_Id) AS matches_played,
        COUNT(b.Innings_No) AS total_innings, 
        SUM(bs.Runs_Scored) AS total_runs, 
        COUNT(w.Player_Out) AS total_wickets,
        SUM(CASE WHEN bs.Runs_Scored = 4 THEN 1 ELSE 0 END) AS fours,
        SUM(CASE WHEN bs.Runs_Scored = 6 THEN 1 ELSE 0 END) AS sixes, 
        SUM(CASE WHEN bs.Runs_Scored = 0 THEN 1 ELSE 0 END) AS dot_balls, 
        COUNT(b.Ball_Id) AS balls_faced,
        COUNT(DISTINCT CASE WHEN m.Win_Type = t.Team_Id THEN m.Match_Id END) AS matches_won
        
    FROM team t 
    JOIN matches m ON t.Team_Id IN (m.Team_1, m.Team_2)
    LEFT JOIN ball_by_ball b ON b.Match_Id = m.Match_Id
    LEFT JOIN batsman_scored bs ON b.Match_Id = bs.Match_Id AND b.Over_Id = bs.Over_Id AND b.Ball_Id = bs.Ball_Id AND b.Innings_No = bs.Innings_No
    LEFT JOIN wicket_taken w ON w.Match_Id = b.Match_Id AND w.Over_Id = b.Over_Id AND w.Ball_Id = b.Ball_Id AND w.Innings_No = b.Innings_No
    GROUP BY 1, 2, 3
),
performance_comparison AS (
    SELECT 
        Season_Id, 
        Team_Id,
        Team_Name,
        matches_played,
        total_innings, 
        total_runs,
        total_wickets,
        fours,
        sixes,
        dot_balls,
        balls_faced,
        matches_won,
       
        ROUND(total_runs/balls_faced * 100, 2) AS strike_rate,
        ROUND(total_runs/matches_played, 2) AS avg_runs_per_match,
        ROUND(total_wickets/matches_played, 2) AS avg_wickets_per_match,
        ROUND(dot_balls/matches_played * 100, 2) AS dot_balls_percentage,
        LAG(total_runs) OVER (PARTITION BY Team_Id ORDER BY Season_Id) AS prev_year_runs, 
        LAG(total_wickets) OVER (PARTITION BY Team_Id ORDER BY Season_Id) AS prev_year_wickets,
        
        LAG(ROUND(total_runs/balls_faced, 2)) OVER (PARTITION BY Team_Id ORDER BY Season_Id) AS prev_year_strike_rate 
    FROM team_performance
)
SELECT 
    Season_Id, 
    Team_Name, 
    matches_played,
    total_runs,
    total_wickets,
    fours,
    sixes,
    strike_rate,
    avg_runs_per_match,
    avg_wickets_per_match,
    
    prev_year_runs, 
    prev_year_wickets, 
    prev_year_strike_rate,
   
    CASE
        WHEN total_runs > prev_year_runs AND total_wickets > prev_year_wickets AND strike_rate > prev_year_strike_rate THEN 'Significantly Better'
        WHEN total_runs > prev_year_runs AND total_wickets > prev_year_wickets THEN 'Better'
        WHEN total_runs < prev_year_runs AND total_wickets < prev_year_wickets AND strike_rate < prev_year_strike_rate THEN 'Significantly Worse'
        WHEN total_runs < prev_year_runs AND total_wickets < prev_year_wickets THEN 'Worse'
        WHEN strike_rate > prev_year_strike_rate THEN 'Improved Scoring Rate'
        ELSE 'Mixed'
    END AS performance_status 
FROM performance_comparison 
WHERE prev_year_runs IS NOT NULL AND prev_year_wickets IS NOT NULL 
ORDER BY Team_Name, Season_Id;


/*Q13 	Using SQL, write a query to find out average wickets taken by each bowler in each venue. Also rank the gender according to the average value. */

WITH bowler_performance AS (
    SELECT 
        b.Bowler,
        v.Venue_Name, 
        COUNT(w.Player_Out) AS total_wickets 
    FROM 
        matches m 
    JOIN 
        ball_by_ball b ON m.Match_Id = b.Match_Id
    JOIN 
        wicket_taken w ON b.Match_Id = w.Match_Id 
            AND w.Over_Id = b.Over_Id 
            AND w.Ball_Id = b.Ball_Id 
            AND w.Innings_No = b.Innings_No
    JOIN 
        venue v ON v.Venue_Id = m.Venue_Id
    GROUP BY 
        1, 2
),
avg_wickets AS (
    SELECT 
        Bowler, 
        Venue_Name, 
        total_wickets,
        AVG(total_wickets) OVER(PARTITION BY Bowler) AS avg_wickets
    FROM 
        bowler_performance
),
ranked_bowler AS (
    SELECT  
        Bowler, 
        Venue_Name, 
        total_wickets,
        avg_wickets, 
        DENSE_RANK() OVER(ORDER BY avg_wickets DESC) AS bowler_rank
    FROM 
        avg_wickets
)
        
/*Q14	Which of the given players have consistently performed well in past seasons? */

WITH player_performance AS (
    SELECT 
        m.Season_Id,
        p.Player_Id,
        p.Player_Name,
        SUM(bs.Runs_Scored) AS total_runs,
        COUNT(DISTINCT m.Match_Id) AS matches_played,
        
        -- Count the number of wickets where the player was the bowler
        SUM(CASE WHEN w.Player_Out IS NOT NULL OR p.Player_Id = b.Bowler THEN 1 ELSE 0 END) AS wickets_taken,
        
        COUNT(b.Ball_Id) AS balls_faced,
        SUM(CASE WHEN bs.Runs_Scored = 4 THEN 1 ELSE 0 END) AS fours,
        SUM(CASE WHEN bs.Runs_Scored = 6 THEN 1 ELSE 0 END) AS sixes,
        
        -- Calculate averages for each season
        ROUND(SUM(bs.Runs_Scored) / COUNT(DISTINCT m.Match_Id), 2) AS avg_runs_per_match,
        ROUND(SUM(CASE WHEN w.Player_Out IS NOT NULL OR p.Player_Id = b.Bowler THEN 1 ELSE 0 END) 
              / COUNT(DISTINCT m.Match_Id), 2) AS avg_wickets_per_match
    FROM 
        player p
    JOIN 
        player_match pm ON p.Player_Id = pm.Player_Id
    JOIN 
        matches m ON pm.Match_Id = m.Match_Id
    JOIN 
        ball_by_ball b ON m.Match_Id = b.Match_Id AND p.Player_Id = b.Striker
    JOIN 
        batsman_scored bs ON b.Match_Id = bs.Match_Id AND b.Over_Id = bs.Over_Id AND b.Ball_Id = bs.Ball_Id
    LEFT JOIN 
        wicket_taken w ON b.Match_Id = w.Match_Id AND b.Over_Id = w.Over_Id AND b.Ball_Id = w.Ball_Id
    GROUP BY 
        m.Season_Id, p.Player_Id, p.Player_Name
)
SELECT 
    Player_Id,
    Player_Name,
    COUNT(DISTINCT Season_Id) AS seasons_played,
    AVG(avg_runs_per_match) AS avg_runs_across_seasons,
    AVG(avg_wickets_per_match) AS avg_wickets_across_seasons,
    COUNT(CASE WHEN avg_runs_per_match > 50 THEN 1 END) AS seasons_above_30_runs,
    COUNT(CASE WHEN avg_wickets_per_match > 2 THEN 1 END) AS seasons_above_2_wickets
FROM 
    player_performance
GROUP BY 
    Player_Id, Player_Name
HAVING 
    seasons_above_30_runs >= 2 OR seasons_above_2_wickets >= 2
ORDER BY 
    avg_runs_across_seasons DESC, avg_wickets_across_seasons DESC;

/*Q15 	Are there players whose performance is more suited to specific venues or conditions? */
WITH player_performance AS (
    SELECT 
        m.Season_Id,
        v.Venue_Name,  -- Include the venue name
        p.Player_Id,
        p.Player_Name,
        SUM(bs.Runs_Scored) AS total_runs,
        COUNT(DISTINCT m.Match_Id) AS matches_played,
        
        -- Count the number of wickets where the player was the bowler
        SUM(CASE WHEN w.Player_Out IS NOT NULL OR p.Player_Id = b.Bowler THEN 1 ELSE 0 END) AS wickets_taken,
        
        COUNT(b.Ball_Id) AS balls_faced,
        SUM(CASE WHEN bs.Runs_Scored = 4 THEN 1 ELSE 0 END) AS fours,
        SUM(CASE WHEN bs.Runs_Scored = 6 THEN 1 ELSE 0 END) AS sixes,
        
        -- Calculate averages for each season
        ROUND(SUM(bs.Runs_Scored) / COUNT(DISTINCT m.Match_Id), 2) AS avg_runs_per_match,
        ROUND(SUM(CASE WHEN w.Player_Out IS NOT NULL or p.Player_Id = b.Bowler THEN 1 ELSE 0 END) 
              / COUNT(DISTINCT m.Match_Id), 2) AS avg_wickets_per_match
    FROM 
        player p
    JOIN 
        player_match pm ON p.Player_Id = pm.Player_Id
    JOIN 
        matches m ON pm.Match_Id = m.Match_Id
    JOIN 
        venue v ON m.Venue_Id = v.Venue_Id  -- Join to get venue information
    JOIN 
        ball_by_ball b ON m.Match_Id = b.Match_Id AND p.Player_Id = b.Striker
    JOIN 
        batsman_scored bs ON b.Match_Id = bs.Match_Id AND b.Over_Id = bs.Over_Id AND b.Ball_Id = bs.Ball_Id
    LEFT JOIN 
        wicket_taken w ON b.Match_Id = w.Match_Id AND b.Over_Id = w.Over_Id AND b.Ball_Id = w.Ball_Id
    GROUP BY 
        m.Season_Id, v.Venue_Name, p.Player_Id, p.Player_Name
)
SELECT 
    Player_Id,
    Player_Name,
    Venue_Name,  -- Include the venue name in the final output
    COUNT(DISTINCT Season_Id) AS seasons_played,
    AVG(avg_runs_per_match) AS avg_runs_across_seasons,
    AVG(avg_wickets_per_match) AS avg_wickets_across_seasons,
    COUNT(CASE WHEN avg_runs_per_match > 50 THEN 1 END) AS seasons_above_50_runs,
    COUNT(CASE WHEN avg_wickets_per_match > 2 THEN 1 END) AS seasons_above_2_wickets
FROM 
    player_performance
GROUP BY 
    Player_Id, Player_Name, Venue_Name  -- Group by Venue_Name as well
HAVING 
    seasons_above_50_runs >= 2 OR seasons_above_2_wickets >= 2
ORDER BY 
    avg_runs_across_seasons DESC, avg_wickets_across_seasons DESC;


 
--  Answer to the subjective que.1
-- How does toss decision have affected the result of the match ? (which visualisations could be used to better present your answer) 
select v.Venue_Name, 
case when m.Toss_Decide=1 then 'Field'else 'Bat' end as toss_decide,
sum(case when m.Toss_Winner=m.Match_Winner then 1 else 0 end ) as toss_winner_wins,
sum(case when m.Toss_Winner!=m.Match_Winner then 1 else 0 end ) as toss_winner_losses, 
count(m.Match_Id) as total_matches,
round(sum(case when m.Toss_Winner=m.Match_Winner then 1 else 0 end)/count(m.Match_Id) *100 , 2) as win_percentage from matches m join venue v on m.Venue_Id=v.Venue_Id
group by v.Venue_Name,m.Toss_Decide order by v.Venue_Name,m.Toss_Decide;


-- Answer to subjective que.2
-- Suggest some of the players who would be best fit for the team?

SELECT p.Player_Name, 
       COUNT(w.Player_Out) AS Wickets_Taken, 
       ROUND(SUM(bb.Ball_Id) / COUNT(w.Player_Out),2) AS Strike_Rate, 
       ROUND(SUM(bs.Runs_Scored) / (SUM(bb.Ball_Id)/6),2) AS Economy_Rate
FROM ball_by_ball bb
JOIN batsman_scored bs 
ON bb.Match_Id = bs.Match_Id AND bb.ball_Id = bs.ball_Id AND bb.Over_Id = bs.Over_Id
JOIN Player p 
ON bb.bowler = p.Player_Id
JOIN matches m ON bb.Match_Id = m.Match_Id
JOIN wicket_taken w 
ON bb.Match_Id = w.Match_Id AND bb.Over_Id = w.Over_Id AND bb.Innings_No = w.Innings_No AND bb.Ball_Id = w.Ball_Id
WHERE m.Season_Id >=4
GROUP BY p.Player_Name
ORDER BY Wickets_Taken DESC, Economy_Rate ASC, Strike_Rate ASC
LIMIT 10;


-- batsman consistent performance
SELECT p.Player_Name, 
       SUM(bs.Runs_Scored) AS Total_Runs, 
       COUNT(bb.Ball_Id) AS Balls_Faced, 
       ROUND((SUM(bs.Runs_Scored) / COUNT(bb.Ball_Id))*100,2) AS Strike_Rate, 
       ROUND(SUM(bs.Runs_Scored) / COUNT(DISTINCT m.Match_Id), 2) AS Average_Runs
FROM player p
JOIN ball_by_ball bb ON p.Player_Id = bb.Striker
JOIN batsman_scored bs ON bb.Match_Id = bs.Match_Id AND bb.Innings_No = bs.Innings_No AND bb.Over_Id = bs.Over_Id AND bb.Ball_Id = bs.Ball_Id
JOIN matches m ON bb.Match_Id = m.Match_Id
WHERE m.Season_Id >= 4
GROUP BY p.Player_Name
ORDER BY Total_Runs DESC,Strike_Rate DESC
LIMIT 10;


-- Answer to the subjective que.3 
-- What are some of parameters that should be focused while selecting the players?

#Key parameters for selecting players

# A. Death over bowling performance
SELECT p.Player_Name, 
       SUM(CASE WHEN bb.Over_Id >= 16 AND bb.Over_Id <= 20  AND p.Player_Id IN (SELECT Bowler FROM ball_by_ball) THEN b.Runs_Scored ELSE 0 END) AS Death_Over_Runs_Conceded
FROM player p
JOIN ball_by_ball bb ON p.Player_Id = bb.Striker OR p.Player_Id = bb.Bowler
JOIN batsman_scored b ON bb.Match_Id = b.Match_Id AND bb.Over_Id = b.Over_Id AND bb.Ball_Id = b.Ball_Id AND bb.Innings_No = b.Innings_No
GROUP BY p.Player_Name
HAVING COUNT(bb.Ball_Id) > 100 AND Death_Over_Runs_Conceded != 0
ORDER BY Death_Over_Runs_Conceded ASC
LIMIT 10;


# B. Batting performance accross different venues

SELECT p.Player_Name, 
       v.Venue_Name, 
       SUM(b.Runs_Scored) AS Total_Runs, 
       COUNT(b.Ball_Id) AS Balls_Faced, 
       ROUND(SUM(b.Runs_Scored) / COUNT(b.Ball_Id), 2)*100 AS Strike_Rate
FROM player p
JOIN ball_by_ball bb ON p.Player_Id = bb.Striker
JOIN matches m ON bb.Match_Id = m.Match_Id
JOIN venue v ON m.Venue_Id = v.Venue_Id
JOIN batsman_scored b 
ON b.Match_Id = bb.Match_Id AND b.Over_Id = bb.Over_Id AND b.Ball_Id = bb.Ball_Id AND b.Innings_No = bb.Innings_No
GROUP BY p.Player_Name, v.Venue_Name
ORDER BY Total_Runs DESC, Strike_Rate DESC
LIMIT 10;



-- answer to the subjective que.4
-- Which players offer versatility in their skills and can contribute effectively with both bat and ball? (can you visualize the data for the same)
WITH batting_performance AS (
    SELECT p.Player_Id, p.Player_Name,
           SUM(b.Runs_Scored) AS Total_Runs,
           COUNT(bb.Ball_Id) AS Balls_Faced,
           ROUND((SUM(b.Runs_Scored) / COUNT(bb.Ball_Id))*100,2) AS Batting_Strike_Rate
    FROM player p
    JOIN ball_by_ball bb ON p.Player_Id = bb.Striker
    JOIN batsman_scored b ON bb.Match_Id = b.Match_Id 
                          AND bb.Over_Id = b.Over_Id 
                          AND bb.Ball_Id = b.Ball_Id 
                          AND bb.Innings_No = b.Innings_No
    GROUP BY p.Player_Id, p.Player_Name
),
bowling_performance AS (
    SELECT p.Player_Id, p.Player_Name, 
           COUNT(w.Player_Out) AS Total_Wickets,
           ROUND(SUM(bb.Team_Batting) / COUNT(bb.Ball_Id),2) AS Economy_Rate
    FROM player p
    JOIN ball_by_ball bb ON p.Player_Id = bb.Bowler
    JOIN wicket_taken w ON bb.Match_Id = w.Match_Id 
                        AND bb.Over_Id = w.Over_Id 
                        AND bb.Ball_Id = w.Ball_Id 
                        AND bb.Innings_No = w.Innings_No
    GROUP BY p.Player_Id, p.Player_Name
)
SELECT bp.Player_Id, bp.Player_Name, 
       bp.Total_Runs, bp.Batting_Strike_Rate, bp.Balls_Faced,
       bw.Total_Wickets, bw.Economy_Rate
FROM batting_performance bp
JOIN bowling_performance bw ON bp.Player_Id = bw.Player_Id
ORDER BY bp.Batting_Strike_Rate  DESC, bw.Economy_Rate ASC
LIMIT 10;



-- Answer to the subjectice question 5
-- Are there players whose presence positively influences the morale and performance of the team? (justify your answer using visualisation)
select * from matches; select * from win_by;select * from team;
WITH player_influence AS (
    -- Check team's win rate when player is in the playing 11
    SELECT pm.Player_Id, p.Player_Name,
           SUM(CASE WHEN m.Match_Winner = pm.Team_Id THEN 1 ELSE 0 END) AS Wins_With_Player,
           COUNT(pm.Match_Id) AS Matches_With_Player
    FROM player_match pm
    JOIN matches m ON pm.Match_Id = m.Match_Id
    JOIN player p ON pm.Player_Id = p.Player_Id
    WHERE pm.Team_Id = 2  
    GROUP BY pm.Player_Id, p.Player_Name
),
team_win_rate AS (
    -- Calculate overall team win rate
    SELECT m.Team_1 AS Team_Id,
           SUM(CASE WHEN m.Match_Winner = 2 THEN 1 ELSE 0 END) AS Wins_Without_Player,
           COUNT(m.Match_Id) AS Total_Matches
    FROM matches m
    WHERE (m.Team_1 = 2 OR m.Team_2 = 2)  -- RCB
    GROUP BY m.Team_1
)
SELECT pi.Player_Name, pi.Wins_With_Player, pi.Matches_With_Player,
       ROUND((pi.Wins_With_Player / pi.Matches_With_Player) * 100, 2) AS Win_Rate_With_Player,
       tw.Wins_Without_Player, tw.Total_Matches,
       ROUND((tw.Wins_Without_Player / tw.Total_Matches) * 100, 2) AS Win_Rate_Without_Player
FROM player_influence pi
JOIN team_win_rate tw ON pi.Player_Id = tw.Team_Id
ORDER BY Win_Rate_With_Player DESC;




-- Answer to the subjective question 6
-- What would you suggest to RCB before going to mega auction ?
WITH batting_performance AS (
    SELECT p.Player_Id, p.Player_Name,
           SUM(b.Runs_Scored) AS Total_Runs,
           COUNT(bb.Ball_Id) AS Balls_Faced,
           ROUND((SUM(b.Runs_Scored) / COUNT(bb.Ball_Id)),2) * 100 AS Batting_Strike_Rate
    FROM player p
    JOIN ball_by_ball bb ON p.Player_Id = bb.Striker
    JOIN batsman_scored b ON bb.Match_Id = b.Match_Id 
                          AND bb.Over_Id = b.Over_Id 
                          AND bb.Ball_Id = b.Ball_Id 
                          AND bb.Innings_No = b.Innings_No
    GROUP BY p.Player_Id, p.Player_Name
),
bowling_performance AS (
    SELECT p.Player_Id, p.Player_Name, 
           COUNT(w.Player_Out) AS Total_Wickets,
           ROUND(SUM(bs.Runs_Scored) / (COUNT(bb.Ball_Id) / 6.0), 2) AS Economy_Rate -- Correct Economy Rate Calculation
    FROM player p
    JOIN ball_by_ball bb ON p.Player_Id = bb.Bowler
    LEFT JOIN wicket_taken w ON bb.Match_Id = w.Match_Id 
                        AND bb.Over_Id = w.Over_Id 
                        AND bb.Ball_Id = w.Ball_Id 
                        AND bb.Innings_No = w.Innings_No
    JOIN batsman_scored bs ON bs.Match_Id = bb.Match_Id
                           AND bb.Over_Id = bs.Over_Id 
                           AND bb.Ball_Id = bs.Ball_Id 
                           AND bb.Innings_No = bs.Innings_No
    GROUP BY p.Player_Id, p.Player_Name
    HAVING COUNT(bb.Ball_Id) > 100
)
SELECT DISTINCT bp.Player_Id, bp.Player_Name, 
       bp.Total_Runs, bp.Batting_Strike_Rate, bp.Balls_Faced,
       bw.Total_Wickets, bw.Economy_Rate
FROM batting_performance bp
JOIN bowling_performance bw ON bp.Player_Id = bw.Player_Id
JOIN player_match pm ON bp.Player_Id = pm.Player_Id
WHERE pm.Role_Id NOT IN (SELECT Role_Id FROM rolee WHERE Role_Desc IN ("Keeper","CaptainKeeper"))
AND bp.Balls_Faced > 100
ORDER BY bp.Batting_Strike_Rate DESC, bw.Economy_Rate ASC
LIMIT 10;




-- Answer to the subjective que.7
-- What do you think could be the factors contributing to the high-scoring matches and the impact on viewership and team strategies

SELECT t.Team_Name,
       SUM(CASE WHEN bb.Over_Id BETWEEN 1 AND 6 THEN b.Runs_Scored ELSE 0 END) AS Powerplay_Runs,
       SUM(CASE WHEN bb.Over_Id BETWEEN 16 AND 20 THEN b.Runs_Scored ELSE 0 END) AS Death_Over_Runs
FROM team t
JOIN matches m ON t.Team_Id = m.Team_1 OR t.Team_Id = m.Team_2
JOIN ball_by_ball bb ON m.Match_Id = bb.Match_Id
JOIN batsman_scored b ON bb.Match_Id = b.Match_Id AND bb.Over_Id = b.Over_Id AND bb.Ball_Id = b.Ball_Id
GROUP BY t.Team_Name
ORDER BY Powerplay_Runs DESC, Death_Over_Runs DESC;


/* High Scoring Venues: Some venues favour the batsmen more then others, venues play a significant role in a high-scoring match */

SELECT v.Venue_Name, 
       AVG(match_runs.Total_Runs) AS Avg_Runs_Per_Match,
       COUNT(m.Match_Id) AS Total_Matches
FROM venue v
JOIN matches m ON v.Venue_Id = m.Venue_Id
JOIN (
    SELECT bb.Match_Id, SUM(b.Runs_Scored) AS Total_Runs
    FROM ball_by_ball bb
    JOIN batsman_scored b ON bb.Match_Id = b.Match_Id 
        AND bb.Over_Id = b.Over_Id 
        AND bb.Ball_Id = b.Ball_Id
    GROUP BY bb.Match_Id
) AS match_runs ON m.Match_Id = match_runs.Match_Id
GROUP BY v.Venue_Name
ORDER BY Total_Matches DESC,Avg_Runs_Per_Match DESC
LIMIT 10;




-- Answer to the subjective question 9
-- Come up with a visual and analytical analysis with the RCB past seasons performance and potential reasons for them not winning a trophy.
# A. Win-Loss Performance Over Seasons

WITH win_loss_record AS (
    SELECT m.Season_Id,CASE WHEN m.Match_Winner = 2 THEN 'Win' ELSE 'Loss' END AS Result
    FROM matches m
    WHERE (m.Team_1 = 2 OR m.Team_2 = 2) AND Outcome_type != 2
)
SELECT Season_Id,COUNT(CASE WHEN Result = 'Win' THEN 1 END) AS Wins,
    COUNT(CASE WHEN Result = 'Loss' THEN 1 END) AS Losses,
    COUNT(*) AS Total_Matches,
    ROUND(COUNT(CASE WHEN Result = 'Win' THEN 1 END) / COUNT(*) * 100, 2) AS Win_Percentage
FROM win_loss_record
GROUP BY Season_Id
ORDER BY Season_Id;

# B. Batting performance each season

WITH rcb_batting_in_death_overs AS (
    SELECT bs.Match_Id, bs.Innings_No, bb.Striker AS Batsman_Id, p.Player_Name,
           SUM(bs.Runs_Scored) AS total_runs_in_power_play,
           COUNT(bb.Ball_Id) AS balls_faced_in_power_play
    FROM Batsman_Scored bs
    JOIN Ball_by_Ball bb ON bs.Match_Id = bb.Match_Id 
                        AND bs.Over_Id = bb.Over_Id
                        AND bs.Ball_Id = bb.Ball_Id
                        AND bs.Innings_No = bb.Innings_No
    JOIN Matches m ON bs.Match_Id = m.Match_Id
    JOIN Player p ON bb.Striker = p.Player_Id 
    WHERE (m.Team_1 = 2 OR m.Team_2 = 2)  
      AND bs.Over_Id BETWEEN 1 AND 6  
    GROUP BY bs.Match_Id, bs.Innings_No, bb.Striker, p.Player_Name
)
SELECT p.Player_Name,
       SUM(rcb.total_runs_in_power_play) AS total_runs_in_power_play,
       SUM(rcb.balls_faced_in_power_play) AS total_balls_faced_in_death_overs,
       ROUND((SUM(rcb.total_runs_in_power_play) / SUM(rcb.balls_faced_in_power_play)) * 100, 2) AS strike_rate_in_power_play
FROM rcb_batting_in_death_overs rcb
JOIN Player p ON rcb.Batsman_Id = p.Player_Id
GROUP BY p.Player_Name
HAVING total_balls_faced_in_death_overs >100
ORDER BY strike_rate_in_power_play DESC;

# C. Bowling performance each season

WITH death_overs_bowling AS (
    SELECT bb.Match_Id, bb.Innings_No, bb.Bowler, p.Player_Name,
           SUM(bs.Runs_Scored) AS runs_conceded,
           COUNT(bb.Ball_Id) AS balls_bowled,
           COUNT(w.Player_Out) AS wickets_taken
    FROM ball_by_ball bb
    JOIN batsman_scored bs ON bb.Match_Id = bs.Match_Id
                          AND bb.Over_Id = bs.Over_Id
                          AND bb.Ball_Id = bs.Ball_Id
                          AND bb.Innings_No = bs.Innings_No
    LEFT JOIN wicket_taken w ON bb.Match_Id = w.Match_Id
                             AND bb.Over_Id = w.Over_Id
                             AND bb.Ball_Id = w.Ball_Id
                             AND bb.Innings_No = w.Innings_No
    JOIN player p ON bb.Bowler = p.Player_Id
    JOIN matches m ON bb.Match_Id = m.Match_Id
    WHERE (m.Team_1 = 2 OR m.Team_2 = 2)  
    AND bb.Over_Id BETWEEN 16 AND 20
    GROUP BY bb.Match_Id, bb.Innings_No, bb.Bowler, p.Player_Name
)
SELECT p.Player_Name,
       SUM(d.runs_conceded) AS runs_conceded_in_death,
       SUM(d.balls_bowled) AS total_balls_bowled_in_death,
       SUM(d.wickets_taken) AS total_wickets_in_death,
       ROUND((SUM(d.runs_conceded) / (SUM(d.balls_bowled) / 6)), 2) AS economy_rate_in_death
FROM death_overs_bowling d
JOIN player p ON d.Bowler = p.Player_Id
JOIN matches m ON d.Match_Id = m.Match_Id
WHERE (m.Team_1 = 2 OR m.Team_2 = 2) 
GROUP BY p.Player_Name
HAVING total_balls_bowled_in_death > 100
ORDER BY economy_rate_in_death DESC;

#subjective 11

UPDATE team 
SET Team_Name = "Delhi Capitals" 
WHERE Team_Name = "Delhi Daredevils";

-- Re-enable safe mode (recommended)
SET SQL_SAFE_UPDATES = 1;
select * from team;


