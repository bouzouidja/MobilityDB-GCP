---distribute vehicle table to all worker 
SELECT create_reference_table('vehicles');

explain SELECT COUNT(*), SUM(duration(Trip)), SUM(length(Trip)) / 1e3 FROM Trips;

---
SELECT
CASE
WHEN T.sourcenode = V.homenode AND date_part('dow', T.day) BETWEEN 1 AND 5 AND
date_part('hour', startTimestamp(trip)) < 12 THEN 'home_work'
WHEN T.sourcenode = V.worknode AND date_part('dow', T.day) BETWEEN 1 AND 5 AND
date_part('hour', startTimestamp(trip)) > 12 THEN 'work_home'
WHEN date_part('dow', T.day) BETWEEN 1 AND 5 THEN 'leisure_weekday'
ELSE 'leisure_weekend'
END AS TripType, COUNT(*), MIN(duration(Trip)), MAX(duration(Trip)), AVG(duration(Trip))
FROM Trips T, vehiclenodes V
WHERE T.vehid = V.vehid
GROUP BY TripType;

---

SELECT vehicle, seq, source, target, round(length(Trip)::numeric / 1e3, 3),
startTimestamp(Trip), duration(Trip)
FROM Trips
WHERE length(Trip) > 50000 LIMIT 1;

---
SELECT vehid, seqno, sourcenode, targetnode, round(length(Trip)::numeric / 1e3, 3),
startTimestamp(Trip), duration(Trip)
FROM Trips
WHERE length(Trip) > 50000 LIMIT 1;

--

SELECT MIN(twavg(speed(Trip))) * 3.6, MAX(twavg(speed(Trip))) * 3.6,
AVG(twavg(speed(Trip))) * 3.6
FROM Trips;

--- take more than 8 mins(canceled) without distributing edges table 
CREATE TABLE HeatMap AS
SELECT E.id, E.geom, count(*)
FROM Edges E, Trips T
WHERE st_intersects(E.geom, T.trajectory)
GROUP BY E.id, E.geom;
