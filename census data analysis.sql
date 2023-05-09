 select * 
from `census.data1`
order by District;

select * 
from `census.data2`
order by District;

-- Number of rows in the tables

select count(*) from `census.data1`;
select count(*) from `census.data2`;

-- dataset for Maharashtra and UttarPradesh

-- select * 
-- from `census.data1`
-- where state like '%utttar prad%' or state like '%maharashtra%';

select * 
from `census.data1`
where state in ('Uttar Pradesh','Maharashtra');

-- total population of india

select 
sum(population) total_population_of_india
from `census.data2`;

-- avg growth, sex_ratio, Literacy rate

select
avg(Growth)*100 as avg_growth_percentage
from `census.data1`;

select
state,
avg(Growth)*100 as avg_growth_percentage
from `census.data1`
-- where state = 'Maharashtra'
group by state
order by avg_growth_percentage desc;

select
state,
round(avg(Sex_Ratio),0) as avg_sex_ratio
from `census.data1`
group by 1
order by 2 desc
limit 3; 

select
state,
round(avg(Literacy),0) as avg_literacy_rate
from `census.data1`
group by state
having avg_literacy_rate > 70
order by avg_literacy_rate desc;

-- top 3 state showing highest growth ratio

select
state,
round(avg(Growth)*100)as avg_growth_percentage
from `census.data1`
group by state
order by avg_growth_percentage desc
limit 3;

-- top  3 state showing lowest literacy ratio

select
state,
round(avg(Literacy),0) as avg_literacy_rate
from `census.data1`
group by state
order by avg_literacy_rate asc
limit 3;

-- top  3 and bottom 3 state in literacy rate (create table)

drop table if exists census.topstates;
create table census.topstates
(
  state string (255),
  topstate string

);

insert into topstates
select
state,
round(avg(Literacy),0) as avg_literacy_rate
from `census.data1`
group by state
order by avg_literacy_rate desc;

select *
from topstates
order by topstates.topstate desc
limit 3;


drop table if exists bottomstates;
create table census.bottomstates
(
  state string (255),
  bottomstate string

);

insert into bottomstates
select
state,
round(avg(Literacy),0) as avg_literacy_rate
from `census.data1`
group by state
order by avg_literacy_rate asc;

select *
from bottomstates
order by bottomstates.bottomstate asc
limit 3;

-- combining both top and bottom states

select * from
(select *
from topstates
order by topstates.topstate desc
limit 3)a

union distinct

select * from
(select *
from bottomstates
order by bottomstates.bottomstate asc
limit 3)b;

-- Joining both tables

select *
from `census.data1` d1 inner join `census.data2` d2
on d1.District =  d2.District;

select d1.district,d1.state,d1.Sex_Ratio,d2.Population
from `census.data1` d1 inner join `census.data2` d2
on d1.District =  d2.District;

-- total no of males and females

-- sex ratio  = total no of females / total no of males ....1
-- population = total no of females + total no of males ....2
-- total no of females = population - total no of males ....3
-- population - total no of males = sex ratio * total no of males....from 1,2,3
-- population = total no of males (sex ratio + 1)
-- total no of males = population / (sex ratio + 1)....4 
-- total no of females = population - (population / (sex ratio + 1))
-- total no of females = (population *sex ratio)/(sex ratio + 1)....5

with main as
(select state, district, round(population/(sex_ratio + 1)) as total_no_of_males, round((population * sex_ratio)/(sex_ratio + 1)) as total_no_of_females
from (
  select d1.district,d1.state,d1.Sex_Ratio/1000 as sex_ratio ,d2.Population
from `census.data1` d1 inner join `census.data2` d2
on d1.District =  d2.District
) a
)
select state,sum(total_no_of_males) as total_males ,sum(total_no_of_females) as total_females
from main 
group by 1
order by 1;

--  total literacy rate

-- literacy_ratio = total_literate_people /population
-- total_literate_people = literacy_ratio * population
-- total_illiterate_people = (1 -literacy_ratio )* population

with main as 
(select district , state,round(literacy_ratio * population) as total_literate_people,round((1 -literacy_ratio )* population )as total_illiterate_people 
from
(select d1.district,d1.state,d1.Literacy/100 as literacy_ratio,d2.Population
from `census.data1` d1 inner join `census.data2` d2
on d1.District =  d2.District)a
order by district)
select state ,sum (total_literate_people) as total_literate_people,sum(total_illiterate_people) as total_illiterate_people
from main
group by state;

-- population in previous census

-- previous_census_population + (growth * previous_census_population) = population
-- previous_census_population = population / (1 + growth)

with main as
(select district, state,round(population / (1 + growth)) as previous_census_population , population as current_census_population
from
(select  d1.district,d1.state,d1.growth,d2.population 
from `census.data1` d1 inner join `census.data2`  d2 
on d1.district=d2.district)a),
main2 as
(select state , sum(previous_census_population) as previous_census_population,sum(current_census_population) as current_census_population
from main
group by 1
order by 1)
select sum (previous_census_population) as previous_total ,sum(current_census_population) as previous_total
from main2;

-- population vs area 

select total_area/previous_total as previous_census_population_vs_area ,total_area/current_total as current_census_population_vs_area
from
(select y.*,x.* from 
(select '1' as indx, n.* 
from(select sum (previous_census_population) as previous_total ,sum(current_census_population) as current_total
from (select state , sum(previous_census_population) as previous_census_population,sum(current_census_population) as current_census_population
from(select district, state,round(population / (1 + growth)) as previous_census_population , population as current_census_population
from(select  d1.district,d1.state,d1.growth,d2.population 
from `census.data1` d1 inner join `census.data2`  d2 
on d1.district=d2.district))group by state))n)y
inner join
(select '1' as indx ,m.* 
from(select sum(area_km2) as total_area
from `census.data2`) m)x
on y.indx = x.indx
);

-- output top 3 districts from each state with highest literacy rate


select * 
from
(select district,state,literacy,rank() over (partition by state order by literacy desc) as rnk
from `census.data1`)
where rnk <= 3
order by state;