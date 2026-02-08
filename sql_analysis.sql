SELECT * FROM `empyrean-maxim-457912-r9.mydata.rides` LIMIT 1000;

SELECT * FROM `empyrean-maxim-457912-r9.mydata.stations` LIMIT 1000;

SELECT * FROM `empyrean-maxim-457912-r9.mydata.users` LIMIT 1000;


-- GET COUNT OF ROWS PER TABLE
select
  (SELECT COUNT(*) FROM `empyrean-maxim-457912-r9.mydata.rides`) as total_rides,
  (SELECT COUNT(*) FROM `empyrean-maxim-457912-r9.mydata.stations`) as total_stations,
  (SELECT COUNT(*) FROM `empyrean-maxim-457912-r9.mydata.users`) as total_users;

-- missing for missing values
-- for rides
select
countif(ride_id is null) as null_ride_ids,
countif(user_id is null) as null_user_id,
countif(start_time is null) as null_start_time,
countif(end_time is null) as null_end_time,
countif(distance_km is null) as null_distance_km
FROM `empyrean-maxim-457912-r9.mydata.rides`;

-- for stations
select
countif(station_name is null) as null_station_name,
countif(capacity is null) as null_capacity
FROM `empyrean-maxim-457912-r9.mydata.stations`;

-- for users
select
countif(user_id is null) as null_user_id,
countif(username is null) as null_username,
countif(age is null) as null_age,
countif(membership_level is null) as null_membership_level,
countif(created_at is null) as null_created_at
FROM `empyrean-maxim-457912-r9.mydata.users`;



-- summary statistics for the rides table

select
  min(distance_km) as min_dist,
  max(distance_km) as max_dist,
  avg(distance_km) as avg_dist,
  min(TIMESTAMP_DIFF(end_time,start_time,MINUTE)) as   min_duration_mins,
  max(TIMESTAMP_DIFF(end_time,start_time,MINUTE)) as   max_duration_mins,
  avg(TIMESTAMP_DIFF(end_time,start_time,MINUTE)) as   avg_duration_mins

FROM `empyrean-maxim-457912-r9.mydata.rides`;


-- checking for false starts for the rides

select
  countif(TIMESTAMP_DIFF(end_time,start_time,MINUTE)<2) as   short_duration_trips,
  countif(distance_km=0) as zero_distance_trips
FROM `empyrean-maxim-457912-r9.mydata.rides`;


-- different memebrship

select
  u.membership_level,
  count(r.ride_id) as total_rides,
  avg(r.distance_km) as avg_distance_km,
  avg(TIMESTAMP_DIFF(r.end_time,r.start_time,MINUTE)) as   avg_duration_mins

FROM `empyrean-maxim-457912-r9.mydata.rides` as r
join `empyrean-maxim-457912-r9.mydata.users` as u
on r.user_id = u.user_id
group by u.membership_level
order by total_rides DESC;

-- peek hours
select

  extract(hour from start_time) as hour_of_day,
  count(*) as rides_count

FROM `empyrean-maxim-457912-r9.mydata.rides` 
group by hour_of_day
order by hour_of_day;


-- check for popular stations
select
  s.station_name,
  count(r.ride_id) as total_starts   
FROM `empyrean-maxim-457912-r9.mydata.rides` as r
join `empyrean-maxim-457912-r9.mydata.stations` as s
on r.start_station_id = s.station_id
group by s.station_name
order by total_starts DESC
limit 10;

-- Categorizing ridesn into short,medium and long

select
  case
    when TIMESTAMP_DIFF(end_time,start_time,MINUTE)<=10 then "short (<=10)"
    when TIMESTAMP_DIFF(end_time,start_time,MINUTE) between 11 and 30 then "Medium (11 to 30)"
    else "long(>30)"
  end as ride_category,
  count(*) as count_of_rides
FROM `empyrean-maxim-457912-r9.mydata.rides`
group by ride_category
order by count_of_rides Desc;

-- net flow for each stations

 with departures as (
  select
    start_station_id,count(*) as total_departures
  FROM `empyrean-maxim-457912-r9.mydata.rides`
  group by start_station_id
 ),
 arrivals as(
  select
    end_station_id,count(*) as total_arrivals
  FROM `empyrean-maxim-457912-r9.mydata.rides`
  group by end_station_id
 )

select
  s.station_id,
  d.total_departures,
  a.total_arrivals,
  (a.total_arrivals-d.total_departures) as net_flow

FROM `empyrean-maxim-457912-r9.mydata.stations` as s
join departures d on s.station_id=d.start_station_id
join arrivals a on s.station_id=a.end_station_id
order by net_flow;


-- user retention

with monthly_signups as (
  select
    DATE_TRUNC(created_at,month) as signup_month,
    COUNT(user_id) as new_user_count
  FROM `empyrean-maxim-457912-r9.mydata.users`
  group by signup_month

)

select
  signup_month,
  new_user_count,
  lag(new_user_count) over (order by signup_month) as previous_month_count,
  (new_user_count - lag(new_user_count) over (order by signup_month))/
  (nullif(lag(new_user_count) over (order by signup_month),0))*100 as month_growth
from monthly_signups

















