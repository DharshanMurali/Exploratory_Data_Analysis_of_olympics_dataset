create database olympics_project;
use olympics_project;

create table athlete_events(
ID int,
Name varchar(255),
Sex varchar(10),
Age varchar(20),
Height varchar(20),
Weight varchar(20),
Team varchar(100),
NOC varchar(50),
Games varchar(50),
Year int,
Season varchar(50),
City varchar(50),
Sport varchar(50),
Event varchar(100),
Medal varchar(50));

show variables like "secure_file_priv";

-- Data loading
/*Load data infile "C://Mysql dataset//athlete_events.csv"
into table athlete_events
fields terminated by ","
ignore 1 rows;*/

drop table athlete_events;
select * from athlete_events;
select * from noc_regions;

-- Removing unwanted punctuations like (), "", -
Delimiter $$
create function remove_punctuation(input varchar(255))
Returns varchar(255)
Deterministic
Begin
Declare output varchar(255);
Set output = Regexp_replace(input, '[[:punct:]]|\(\)\-\"]', "");
Return output;
End $$

Delimiter ;
set sql_safe_updates = 0;

update athlete_events
Set Name = remove_punctuation(Name);

-- Removing extra spaces
update athlete_events
set Medal = TRIM(regexp_replace(Medal, "\\s+",""));

-- 1. No.of olympics games held
select count(distinct games) as no_of_games
from athlete_events;

-- 2. List of all Olympics games held so far
select distinct games
from athlete_events
order by games;

-- 3. The total no of nations who participated in each olympics game
 select ae.games, count(distinct nr.region) as countries
 from athlete_events ae inner join noc_regions nr on ae.noc = nr.noc
 group by games
 order by games;
 
 -- 4. The year that saw the highest and lowest no of countries participating in olympics
 select * from noc_regions;
 with all_countries as(
 select ae.games, nr.region
 from athlete_events ae inner join noc_regions nr on ae.noc = nr.noc
 group by ae.games, nr.region),
 no_of_countries as(
 select games, count(*) as total_countries
 from all_countries
 group by games)
 
 select distinct 
 concat(first_value(games) over(order by total_countries), '-',
 first_value(total_countries) over(order by total_countries)) as lowest_participating_countries,
 concat(first_value(games) over(order by total_countries desc), '-',
 first_value(total_countries) over(order by total_countries desc)) as highest_participating_countries
 from no_of_countries;
 
 -- 5. Nation participated in all of the olympic games
with countries as (
select ae.games as games, nr.region as country
from athlete_events ae inner join noc_regions nr on ae.noc=nr.noc
group by ae.games, nr.region)

select distinct country, count(*) as total_games
from countries
group by country
having count(*) = 51;

-- 6. The sport which was played in all summer olympics
with cte1 as(
select count(distinct games) as no_of_games
from athlete_events
where season = "Summer"),
cte2 as(
select distinct games, sport
from athlete_events
where season ="Summer"),
cte3 as(
select sport, count(*) as no_of_sports
from cte2
group by sport)

select * 
from cte3 join cte1 on cte3.no_of_sports = cte1.no_of_games;

-- 7. Sports just played only once in the olympics
with cte1 as(
select distinct sport, games
from athlete_events
group by sport, games),
cte2 as(
select distinct sport, count(*) as no_of_games
from cte1
group by sport)

select cte2.*, cte1.games
from cte2 join cte1 on cte2.sport = cte1.sport
where cte2.no_of_games = 1
order by sport;

-- 8. The total no of sports played in each olympic games
with cte1 as(
select distinct games, sport
from athlete_events),
cte2 as(
select games, count(*) as no_of_games
from cte1
group by games)

select * from cte2
order by no_of_games desc;

-- 9. Details of the oldest athletes to win a gold medal
with t1 as(
select Name, sex, cast(case when age = "NA" then "0" else age end as unsigned) as age , team, games, city, sport, event, medal
from athlete_events),
t2 as(
select *, rank() over(order by age desc) as rnk
from t1
where medal = "Gold")

select * from t2
where rnk =1;

-- 10. The Ratio of male and female athletes participated in all olympic games
select * from athlete_events;
with male_count as(
select distinct count(sex) as total_males
from athlete_events
where sex = "M"
group by sex),
female_count as(
select distinct count(sex) as total_females
from athlete_events
where sex = "F"
group by sex)

select concat("1 : ", round(total_males/total_females,2)) as ratio
from male_count, female_count;

-- 11. The top 5 athletes who have won the most gold medals
with t1 as(
select name, count(*) as total_medals
from athlete_events
where medal = "Gold"
group by name
order by total_medals desc),
t2 as (
select *, dense_rank() over(order by total_medals desc) as rnk
from t1)

select *
from t2
where rnk <=5;

-- 12. The top 5 athletes who have won the most medals (gold/silver/bronze)
with t1 as(
select name, count(*) as total_medals
from athlete_events
where medal <> "NA"
group by name
order by total_medals desc),
t2 as(
select *, dense_rank() over(order by total_medals desc) as rnk
from t1)

select * from t2
where rnk<=5;

-- 13. The top 5 most successful countries in olympics (Success is defined by no of medals won)
with t1 as(
select nr.region as region, count(1) as total_medals
from noc_regions nr join athlete_events ae on nr.noc=ae.noc
where ae.medal <> "NA"
group by nr.region
order by total_medals desc),
t2 as(
select *, dense_rank() over(order by total_medals desc) as rnk
from t1)

select * from t2
where rnk <=5;

-- 14. List of total gold, silver and broze medals won by each country
select nr.region,
count(case when ae.medal = "Gold" then 1 end) as Gold,
count(case when ae.medal = "Silver" then 1 end) as Silver,
count(case when ae.medal = "Bronze" then 1 end) as Bronze
from athlete_events ae join noc_regions nr on ae.noc=nr.noc
where medal <> "NA"
group by nr.region
order by gold desc, silver desc, bronze desc;

-- 15. List of total gold, silver and broze medals won by each country corresponding to each olympic games
select ae.games, nr.region as country,
count(case when ae.medal = "Gold" then 1 end) as Gold,
count(case when ae.medal = "Silver" then 1 end) as Silver,
count(case when ae.medal = "Bronze" then 1 end) as Bronze
from athlete_events ae join noc_regions nr on ae.noc=nr.noc
where ae.medal <> "NA"
group by ae.games, nr.region
order by ae.games, country;

-- 16. The country that won the most gold, most silver and most bronze medals in each olympic games
with cte1 as(
select ae.games, nr.region,
count(case when ae.medal = "Gold" then 1 end) as Gold,
count(case when ae.medal = "Silver" then 1 end) as Silver,
count(case when ae.medal = "Bronze" then 1 end) as Bronze
from athlete_events ae join noc_regions nr on ae.noc=nr.noc
where medal <> "NA"
group by ae.games, nr.region
order by ae.games)

select distinct games,
concat(
first_value(region) over(partition by games order by gold desc), " - ",
first_value(gold) over(partition by games order by gold desc)) as max_gold_medals,
concat(
first_value(region) over(partition by games order by silver desc), " - ",
first_value(silver) over(partition by games order by silver desc)) as max_silver_medals,
concat(
first_value(region) over(partition by games order by bronze desc), " - ",
first_value(bronze) over(partition by games order by bronze desc)) as max_bronze_medals
from cte1;

-- 17. The Sport/event in which India has won highest medals
select ae.sport, count(1) as total_medals_won
from athlete_events ae join noc_regions nr on ae.noc=nr.noc
where nr.region = "India" and ae.medal <> "NA" and ae.sport = "Hockey"
group by ae.sport;

-- 18. Break down of all olympic games where india won medal for Hockey and no.of medals in each olympic game
select distinct team, sport, games, count(1) as no_of_medals
from athlete_events
where medal <> "NA" and sport = "Hockey" and team = "India"
group by team, games
order by no_of_medals desc;








 
 
 
 
 
 
