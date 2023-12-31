--ИТОГОВОЕ ЗАДАНИЕ
--Ашкинадзи SQL-46

--ВОПРОС №1
--Какие самолеты имеют более 50 посадочных мест?

select a.model, t.count number_of_seats
from aircrafts a 
join (
	select distinct aircraft_code, count(seat_no) over (partition by aircraft_code)
	from seats s) t on a.aircraft_code = t.aircraft_code
where t.count > 50

--ВОПРОС №2
--В каких аэропортах есть рейсы, в рамках которых можно 
--добраться бизнес - классом дешевле, чем эконом - классом?
--ИСПОЛЬЗОВАТЬ: СТЕ

with cte_business as(
	select flight_id, fare_conditions, min(amount)
	from ticket_flights tf 
	where fare_conditions = 'Business'
	group by flight_id, fare_conditions),
cte_economy as(
	select flight_id, fare_conditions, max(amount)
	from ticket_flights tf 
	where fare_conditions = 'Economy'
	group by flight_id, fare_conditions)
 select f.flight_id, f.departure_airport, f.arrival_airport, cte_business.min min_business, cte_economy.max max_economy
 from flights f 
 join cte_economy on cte_economy.flight_id = f.flight_id 
 join cte_business on cte_business.flight_id = f.flight_id 
 where cte_business.min < cte_economy.max

--ВОПРОС №3
--Есть ли самолеты, не имеющие бизнес - класса?
--ИСПОЛЬЗОВАТЬ: array_agg 
 
select r.aircraft_code, a.model, r.fare_condition_array
from (
	select t.aircraft_code, fare_condition_array
	from (
		select distinct aircraft_code, array_agg(fare_conditions::text) over (partition by aircraft_code) fare_condition_array
		from seats s) t
	where array_position(fare_condition_array, 'Business') is null) r
join aircrafts a on r.aircraft_code = a.aircraft_code

--ВОПРОС №4
--Найдите количество занятых мест для каждого рейса, 
--процентное отношение количества занятых мест к общему количеству мест в самолете, 
--добавьте накопительный итог вывезенных пассажиров по каждому аэропорту на каждый день.
--ИСПОЛЬЗОВАТЬ: оконная функция, подзапрос 

select f.flight_id, 
	count(bp.seat_no) taken_seats,
	t.total_seats,
	count(bp.seat_no)::numeric*100/t.total_seats taken_seats_percentage,
	departure_airport,
	actual_departure::date,
	sum(count(bp.seat_no)) over (partition by departure_airport order by actual_departure)
from flights f
join boarding_passes bp on f.flight_id = bp.flight_id  
join (
	select aircraft_code, count(s.seat_no) total_seats
	from seats s  
	group by s.aircraft_code) t on t.aircraft_code = f.aircraft_code 
group by f.flight_id, t.total_seats

--ВОПРОС №5
--Найдите процентное соотношение перелетов по маршрутам от общего количества перелетов. 
--Выведите в результат названия аэропортов и процентное отношение.
--ИСПОЛЬЗОВАТЬ: оконная функция, оператор ROUND 

select distinct  
	a.airport_name,  
	a2.airport_name, 
	round((count(flight_id) over (partition by flight_no)*100)/(count(flight_id) over ())::numeric, 5) percentage
from flights f 
join airports a on a.airport_code = f.departure_airport 
join airports a2 on a2.airport_code = f.arrival_airport

--ВОПРОС №6
--Выведите количество пассажиров по каждому коду сотового оператора, 
--если учесть, что код оператора - это три символа после +7

select code, count(passenger_id) number_of_passengers
from (
	select substring(contact_data::varchar from strpos(contact_data::varchar, '+7')+2 for 3) code, passenger_id
	from tickets t) r
group by r.code

--ВОПРОС №7
--Между какими городами не существует перелетов?
--ИСПОЛЬЗОВАТЬ: декартово произведение, оператор EXCEPT


select t1.city1, t1.city2
from (
	select a1.airport_code airport_code1, a1.city city1, a2.airport_code airport_code2, a2.city city2 
	from airports a1, airports a2
	where a1.airport_code  < a2.airport_code) t1
except select t2.city3, t2.city4
from (																													
	select departure_airport , a3.airport_name city3, arrival_airport, a4.airport_name city4
	from flights f
	join airports a3 on f.departure_airport = a3.airport_code
	join airports a4 on f.arrival_airport = a4.airport_code) t2

--ВОПРОС №8
--Классифицируйте финансовые обороты (сумма стоимости билетов) по маршрутам:
--До 50 млн - low
--От 50 млн включительно до 150 млн - middle
--От 150 млн включительно - high
--Выведите в результат количество маршрутов в каждом классе.
--ИСПОЛЬЗОВАТЬ: Оператор CASE

select t.category, count(t.flight_no) number_of_routes
from (
select flight_no, sum(tf.amount),
	case 
		when sum(amount) < 50000000 then 'low' 
		when sum(amount) < 150000000 and sum(amount) >= 50000000 then 'middle'
		when sum(amount) >= 150000000 then 'high'
	end category
from flights f 
join ticket_flights tf on tf.flight_id = f.flight_id
group by flight_no) t
group by t.category

--ВОПРОС №9
--Выведите пары городов между которыми расстояние более 5000 км
--ИСПОЛЬЗОВАТЬ: Оператор RADIANS или использование sind/cosd

select a1.city, 
	a2.city,
	acos(sin(a1.latitude)*sin(a2.latitude)+cos(a1.latitude)*cos(a2.latitude)*cos(a1.longitude - a2.longitude))*6371 distance
from airports a1, airports a2
where a1.airport_code  < a2.airport_code and acos(sin(a1.latitude)*sin(a2.latitude)+cos(a1.latitude)*cos(a2.latitude)*cos(a1.longitude - a2.longitude))*6371 > 5000

