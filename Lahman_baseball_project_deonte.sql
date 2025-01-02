SELECT *
FROM teams;

-- 1. What range of years for baseball games played does the provided database cover?
-- 1871 - 2017
SELECT * 
FROM people AS p
INNER JOIN appearances AS a
ON p.playerid = a.playerid
ORDER BY p.debut ASC;

-- 2. Find the name and height of the shortest player in the database. How many games did he play in? What is 
--    the name of the team for which he played?
--  Eddie Gaedal (43 in), 1, St. Louis Browns
SELECT p.namefirst, p.namelast, p.height, a.g_all, t.name
FROM people AS p
INNER JOIN appearances AS a
USING(playerid)
INNER JOIN teams AS t
ON a.teamid = t.teamid
ORDER BY p.height ASC;

-- 3. Find all players in the database who played at Vanderbilt University. Create a list showing each player’s 
--    first and last names as well as the total salary they earned in the major leagues. Sort this list in 
--    descending order by the total salary earned. Which Vanderbilt player earned the most money in the majors?
--  David Price
SELECT DISTINCT p.namefirst, p.namelast, s.schoolname, SUM(sal.salary)::NUMERIC::MONEY AS total_sal_earned
FROM people AS p
INNER JOIN (SELECT DISTINCT playerid, schoolid FROM collegeplaying) AS cp
ON cp.playerid = p.playerid
INNER JOIN schools AS s
ON s.schoolid = cp.schoolid
INNER JOIN salaries AS sal
ON sal.playerid = p.playerid
WHERE s.schoolname = 'Vanderbilt University'
GROUP BY p.namefirst, p.namelast, s.schoolname
ORDER BY total_sal_earned DESC;

-- 4. Using the fielding table, group players into three groups based on their position: label players with 
--    position OF as "Outfield", those with position "SS", "1B", "2B", and "3B" as "Infield", and those with 
--    position "P" or "C" as "Battery". Determine the number of putouts made by each of these three groups in 
--    2016.
--  Outfield = 29,560, Infield = 58,934, Battery = 41,424
SELECT SUM(po) AS total_outs,
	CASE WHEN pos = 'OF' THEN 'Outfield'
		 WHEN pos = 'SS' THEN 'Infield'
		 WHEN pos = '1B' THEN 'Infield'
		 WHEN pos = '2B' THEN 'Infield'
		 WHEN pos = '3B' THEN 'Infield'
		 WHEN pos = 'P' THEN 'Battery' 
		 WHEN pos = 'C' THEN 'Battery' END AS position
FROM fielding
WHERE yearid = '2016'
GROUP BY position
ORDER BY total_outs;

-- 5. Find the average number of strikeouts per game by decade since 1920. Round the numbers you report to 2 
--    decimal places. Do the same for home runs per game. Do you see any trends?
-- The avg strikeout increased each decade & avg hr leveled at 2 by the 2000s
SELECT CONCAT((yearid/ 10 * 10)::text, '''s') AS decade, 
	   ROUND(SUM(so)::numeric/ (SUM(g)/2), 2) AS avg_so,
	   ROUND(SUM(hr)::numeric/ (SUM(g)/2), 2) AS avg_hr
FROM teams
WHERE yearid > 1920
GROUP BY decade
ORDER BY decade;

-- 6. Find the player who had the most success stealing bases in 2016, where __success__ is measured as the 
--    percentage of stolen base attempts which are successful. (A stolen base attempt results either in a 
--    stolen base or being caught stealing.) Consider only players who attempted _at least_ 20 stolen bases.
-- Chris Owings 91.3%
SELECT CONCAT(namefirst, ' ' , namelast) AS full_name,
	   ROUND((sb::numeric / (cs + sb)) * 100, 2) AS sb_success_pct
FROM batting
INNER JOIN people USING (playerid)
WHERE yearid = '2016' AND (sb + cs)> 20
ORDER BY sb_success_pct DESC;

-- 7. From 1970 – 2016, what is the largest number of wins for a team that did not win the world series? 
--    What is the smallest number of wins for a team that did win the world series? Doing this will probably 
--    result in an unusually small number of wins for a world series champion – determine why this is the case. 
--    Then redo your query, excluding the problem year. How often from 1970 – 2016 was it the case that a team 
--    with the most wins also won the world series? What percentage of the time?
-- It happened 12 times | 26%
SELECT MAX(w)
FROM teams
WHERE wswin = 'N' AND yearid BETWEEN 1970 AND 2016;

SELECT MIN(w)
FROM teams
WHERE wswin = 'Y' AND yearid BETWEEN 1970 AND  2016 AND yearid <> 1981;

SELECT *
FROM teams
WHERE wswin = 'Y' AND w = (SELECT MIN(w) FROM teams WHERE wswin = 'Y' AND yearid BETWEEN 1970 AND  2016);

WITH most_wins AS (
					SELECT yearid, MAX(w) AS most_wins
					FROM teams
					WHERE yearid BETWEEN 1970 AND 2016
					GROUP BY yearid)
SELECT COUNT(*)
FROM most_wins
INNER JOIN teams USING(yearid)
WHERE wswin = 'Y' AND w = most_wins;

WITH most_wins AS (
					SELECT yearid, MAX(w) AS most_wins
					FROM teams
					WHERE yearid BETWEEN 1970 AND 2016
					GROUP BY yearid)
SELECT ROUND(AVG(CASE 
		WHEN w = most_wins THEN 1 ELSE 0 END) * 100, 2) as pct
FROM most_wins 
INNER JOIN teams USING(yearid)
WHERE wswin = 'Y';




-- 8. Using the attendance figures from the homegames table, find the teams and parks 
--    which had the top 5 average attendance per game in 2016 (where average attendance 
--    is defined as total attendance divided by number of games). Only consider parks 
--    where there were at least 10 games played. Report the park name, team name, and 
--    average attendance. Repeat for the lowest 5 average attendance.
-- TOP 5
(SELECT name, park_name, homegames.attendance / games AS avg_attendance, 'top_5' AS attendace_rank
FROM homegames
INNER JOIN parks USING(park)
INNER JOIN teams ON homegames.year = teams.yearid AND homegames.team = teams.teamid
WHERE year = 2016 AND games >= 10
ORDER BY avg_attendance DESC
LIMIT 5)

UNION

-- LOW 5 
(SELECT name, park_name, homegames.attendance / games AS avg_attendance, 'low_5' AS attendance_rank
FROM homegames
INNER JOIN parks USING(park)
INNER JOIN teams ON homegames.year = teams.yearid AND homegames.team = teams.teamid
WHERE year = 2016 AND games >= 10
ORDER BY avg_attendance
LIMIT 5)
ORDER BY avg_attendance DESC;

-- 9. Which managers have won the TSN Manager of the Year award in both the National League (NL) and the 
--    American League (AL)? Give their full name and the teams that they were managing when they won the award.
-- 
SELECT CONCAT(namefirst, ' ', namelast) AS full_name, name AS team, lgid, yearid
FROM people
INNER JOIN awardsmanagers USING(playerid)
INNER JOIN managers USING(playerid, yearid, lgid)
INNER JOIN teams USING(teamid, yearid, lgid)
WHERE (playerid, awardid) IN
	(SELECT playerid, awardid
	FROM awardsmanagers
	WHERE awardid LIKE 'TSN%' AND lgid IN ('AL', 'NL')
	GROUP BY playerid, awardid
	HAVING COUNT(DISTINCT lgid) = 2)
ORDER BY playerid;

-- 10. Find all players who hit their career highest number of home runs in 2016. Consider only players who have 
--     played in the league for at least 10 years, and who hit at least one home run in 2016. Report the 
--      players' first and last names and the number of home runs they hit in 2016.
--
WITH max_hr AS (
		SELECT playerid, MAX(hr) AS max_hr
		FROM batting
		GROUP BY playerid)

SELECT *
FROM max_hr
INNER JOIN batting USING(playerid)
WHERE yearid = 2016;




