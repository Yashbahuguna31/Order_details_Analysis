
--find top 10 highest reveue generating products 

select product_id, sum(sale_price) as revenue
from df_orders
group by product_id
order by sum(sale_price) desc
limit 10

--find top 5 highest selling products in each region

with cte as (
             select region,product_id,sum(sale_price) as sales
             from df_orders
             group by region,product_id)
select * 
from (
      select *
              , row_number() over(partition by region order by sales desc) as rn
      from cte) A
where rn<=5

--find month over month growth comparison for 2022 and 2023 sales eg : jan 2022 vs jan 2023

with cte as (
	          select to_char(order_date,'Mon')as month, 
			         extract(year from order_date)as year,
			         extract(month from order_date) as month_number,
			         sum(sale_price) as sales
		     from df_orders
		     group by to_char(order_date,'Mon'), extract(year from order_date),extract(month from order_date)
		     order by month_number asc
            )
select month, sales_2022, sales_2023,
       round(((sales_2023 - sales_2022)/sales_2022)*100.0,2) as percentage_change
from (
		select month,
			   sum(case when year = 2022 then sales else 0 end) as sales_2022,
			   sum(case when year = 2023 then sales else 0 end) as sales_2023,
			   month_number
		from cte
		group by month,month_number
		order by month_number  asc
	) x

--for each category which month had highest sales

with cte as (
				select category,to_char(order_date,'Mon-yyyy') as month_year,sum(sale_price) as sales
				from df_orders
				group by category,to_char(order_date,'Mon-yyyy')
	        )
select category, month_year
from (
		select category,
			   month_year, sales,
			   dense_rank() over(partition by category order by sales desc) as rnk
		from cte
	 ) x
where rnk = 1

--which sub category had highest growth by profit in 2023 compare to 2022

with cte as (
				select category,sub_category, 
					   extract(year from order_date) as year_order,
					   sum(profit) as profit
				from df_orders
				group by  category,sub_category,extract(year from order_date)
	        ),
new_cte as (
				select category,sub_category,
					   sum(case when year_order = 2022 then profit else 0 end ) as year_2022,
					   sum(case when year_order = 2023 then profit else 0 end ) as year_2023
				from cte 
				group by category,sub_category
	        )
select sub_category, 
       round(((year_2023 - year_2022)/year_2022)*100,2) as percentage_change
from new_cte
order by round(((year_2023 - year_2022)/year_2022)*100,2) desc
limit 1

--which sub category had highest growth by profit in 2023 compare to 2022 for respective category

with cte as (
				select category,sub_category, 
					   extract(year from order_date) as year_order,
					   sum(profit) as profit
				from df_orders
				group by  category,sub_category,extract(year from order_date)
	        ),
new_cte as (
				select category,sub_category,
					   sum(case when year_order = 2022 then profit else 0 end ) as year_2022,
					   sum(case when year_order = 2023 then profit else 0 end ) as year_2023
				from cte 
				group by category,sub_category
	        )
select category, sub_category, percentage_change
from (
		select *,
			   dense_rank() over(partition by category order by percentage_change desc) as rnk
		from (
			   select sub_category,category, 
					  round(((year_2023 - year_2022)/year_2022)*100,2) as percentage_change
			   from new_cte
			  ) x
	  ) y
where rnk = 1





