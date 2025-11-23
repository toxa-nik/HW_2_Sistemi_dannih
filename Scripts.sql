-- Задание № 2.1 --
-- Я всё-таки передумал и почистил таблицу от неуникальных product_id 
-- Раньше была уникальная связка product_id + standart_cost, например. Там была некоторая проблема, т.к. если так смотреть на данные, ответ к этому заданию будет пустой.
-- Было всего 4 действительно уникальных продукта, проданных в количестве более 1000шт, и все они имели standart_cost меньше 1500. 
-- Теперь же я просто считаю так, как написал ниже, надеюсь я правильно понял это задание.


select distinct brand
from HW2.product_cor
where (standard_cost > 1500) and product_id in 
	(SELECT product_id
	FROM HW2.order_items
	GROUP BY product_id
	having sum(quantity)>=1000);


-- Задание № 2.2 --	
-- Для каждого дня в диапазоне с 2017-04-01 по 2017-04-09 включительно вывести количество подтвержденных онлайн-заказов и количество уникальных клиентов, совершивших эти заказы.
	

select	order_date, 
		count(distinct customer_id) as uniq_customers_count, 
		count(order_id) as Approved_online_orders_count
from HW2.orders as od
where od.order_status='Approved' 
		and od.online_order = true 
		and od.order_date between '2017-04-01' and '2017-04-09'
group by od.order_date
order by od.order_date;
	

-- Задание № 2.3 --	
-- Вывести профессии клиентов:
-- 	из сферы IT, чья профессия начинается с Senior;
-- 	из сферы Financial Services, чья профессия начинается с Lead.
-- 	Для обеих групп учитывать только клиентов старше 35 лет. Объединить выборки с помощью UNION ALL.


select job_title
from HW2.customer c
where c.job_title like 'Senior%' 
	  and c.job_industry_category = 'IT' 
	  and AGE(c."DOB") > INTERVAL '35 years'
union all
select job_title
from HW2.customer c
where c.job_title like 'Lead%' 
	  and c.job_industry_category = 'Financial Services' 
	  and AGE(c."DOB") > INTERVAL '35 years';


-- Задание № 2.4 --
-- Вывести бренды, которые были куплены клиентами из сферы Financial Services, но не были куплены клиентами из сферы IT.

-- Либо я не понял задания, либо это просто проверка на составления запросов, 
-- т.к. с таким количеством заказов и всего 6 брендами все всё попокупают и не по одному разу.


--drop view big_table

create or replace view big_table as (		
select 
    pr_c.brand,
    cust.job_industry_category
from HW2.order_items oi
join HW2.product_cor pr_c on oi.product_id = pr_c.product_id 
join HW2.orders ord on oi.order_id = ord.order_id 
join HW2.customer cust on ord.customer_id = cust.customer_id 
where ord.order_status = 'Approved');			
		
select distinct brand 
from big_table
where job_industry_category = 'Financial Services' 
		and brand NOT IN (
						select distinct brand 
						from big_table
						where job_industry_category = 'IT');
						
									
-- Задание № 2.5 --					
-- Вывести 10 клиентов (ID, имя, фамилия), которые совершили наибольшее количество онлайн-заказов (в штуках) 
-- брендов Giant Bicycles, Norco Bicycles, Trek Bicycles, при условии, что они активны и имеют оценку имущества (property_valuation) 
-- выше среднего среди клиентов из того же штата.

-- У меня получилось 1 клиент с 6 заказами и 12 клиент с 5 заказами, 
-- и, чтобы выбрать оставшиеся 9 клиентов (из 12 с 5 заказами), я отобрал первых 9 с наименьшим customer_id (наши любимые первые клиенты).
-- Count, с вашего позволения, я тоже выведу, для наглядности
	

select customer_id, first_name, last_name, count(distinct order_id)   		
from (
		select cust.customer_id, cust.first_name, cust.last_name, cust.property_valuation, ord.order_id,  avg(property_valuation) OVER (PARTITION BY state) as state_man_prop_val
		from HW2.order_items oi
			join HW2.product_cor pr_c on oi.product_id = pr_c.product_id 
			join HW2.orders ord on oi.order_id = ord.order_id 
			join HW2.customer cust on ord.customer_id = cust.customer_id 						
		where cust.deceased_indicator = 'N' 
				and ord.online_order = true 
				and ord.order_status = 'Approved' 
				and (pr_c.brand = 'Giant Bicycles' 
					or pr_c.brand = 'Norco Bicycles' 
					or pr_c.brand = 'Trek Bicycles') -- не хочу использовать in
	 )
where property_valuation > state_man_prop_val
group by customer_id, first_name, last_name
order by count(order_id) desc, customer_id
limit 10;

		
-- Задание № 2.6 --		
-- Вывести всех клиентов (ID, имя, фамилия), у которых нет подтвержденных онлайн-заказов за последний год, 
-- но при этом они владеют автомобилем и их сегмент благосостояния не Mass Customer.


select cust.customer_id, cust.first_name, cust.last_name
from HW2.customer cust
where   cust.owns_car = 'Yes' 
		and cust.wealth_segment <> 'Mass Customer' 
		and cust.customer_id not in (select ord.customer_id
						from HW2.orders ord
						where
						ord.online_order = true
						and ord.order_status = 'Approved'
						and ord.order_date between '2017-01-01' and '2017-12-31' -- Я решил, что последний год, это последний год из имеющихся в таблице
						)
order by cust.customer_id;

-- Задание № 2.7 --	
-- Вывести всех клиентов из сферы 'IT' (ID, имя, фамилия), 
-- которые купили 2 из 5 продуктов с самой высокой list_price в продуктовой линейке Road.


select cust.customer_id, cust.first_name, cust.last_name 
from HW2.order_items oi
join HW2.product_cor pr_c on oi.product_id = pr_c.product_id 
join HW2.orders ord on oi.order_id = ord.order_id 
join HW2.customer cust on ord.customer_id = cust.customer_id 
where cust.job_industry_category = 'IT' 
		and ord.order_status = 'Approved'
		and pr_c.product_id in (select product_id
								from HW2.product_cor
								where product_line = 'Road'
								order by list_price desc
								limit 5)
group by cust.customer_id, cust.first_name, cust.last_name
having count(distinct pr_c.product_id) = 2; -- Немного непонятное условие, =2 или >=2.

-- Задание № 2.8 --	
-- Вывести клиентов (ID, имя, фамилия, сфера деятельности) из сфер IT или Health,
-- которые совершили не менее 3 подтвержденных заказов в период 2017-01-01 по 2017-03-01,
-- и при этом их общий доход от этих заказов превышает 10 000 долларов.
-- Разделить вывод на две группы (IT и Health) с помощью UNION.


select  cust.customer_id, 
		cust.first_name, 
		cust.last_name, 
		cust.job_industry_category 
from HW2.order_items oi
join HW2.orders ord on oi.order_id = ord.order_id 
join HW2.customer cust on ord.customer_id = cust.customer_id 
where   cust.job_industry_category = 'IT' 
		and ord.order_status = 'Approved' 
		and ord.order_date between '2017-01-01' and '2017-03-01' 
group by 
		 cust.customer_id, 
		 cust.first_name, 
		 cust.last_name, 
		 cust.job_industry_category
having count(distinct ord.order_id) >= 3 
	and sum(oi.quantity * oi.item_list_price_at_sale) > 10000
union
select  cust.customer_id, 
		cust.first_name, 
		cust.last_name, 
		cust.job_industry_category 
from HW2.order_items oi
join HW2.orders ord on oi.order_id = ord.order_id 
join HW2.customer cust on ord.customer_id = cust.customer_id 
where cust.job_industry_category = 'Health' 
	  and ord.order_status = 'Approved' 
	  and ord.order_date between '2017-01-01' and '2017-03-01' 
group by cust.customer_id, 
		 cust.first_name, 
		 cust.last_name,
		 cust.job_industry_category
having  count(distinct ord.order_id) >= 3 
		and sum(oi.quantity * oi.item_list_price_at_sale) > 10000
order by job_industry_category, customer_id;
