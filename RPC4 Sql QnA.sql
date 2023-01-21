select * from dim_customer;
select * from dim_product;
select * from fact_gross_price;
select * from fact_manufacturing_cost;
select * from fact_pre_invoice_deductions;
select * from fact_sales_monthly;


-- Codebasics SQL Challenge
-- Requests:

use gdb023;


-- Q 1. Provide the list of markets in which customer "Atliq Exclusive" operates its
 --  business in the APAC region.

select distinct market as Markets_List 
from dim_customer
where customer = "Atliq Exclusive" and region = "APAC";
   
   
   
-- 2. What is the percentage of unique product increase in 2021 vs. 2020? The
-- final output contains these fields,
-- unique_products_2020
-- unique_products_2021
-- percentage_chg

with unique_products_2020 as 
(select count(distinct dim_product.product_code) as unique_products_2020
from dim_product 
inner join fact_sales_monthly
on dim_product.product_code = fact_sales_monthly.product_code
where fact_sales_monthly.fiscal_year = 2020 ),

unique_products_2021 as 
(select count(distinct dim_product.product_code) as unique_products_2021
from dim_product 
inner join fact_sales_monthly
on dim_product.product_code = fact_sales_monthly.product_code
where fact_sales_monthly.fiscal_year = 2021)

select unique_products_2020.*,
	unique_products_2021.*,
    round((unique_products_2021-unique_products_2020)/unique_products_2020 *100 ,2) as percentage_chg
from unique_products_2020, unique_products_2021;





-- 3. Provide a report with all the unique product counts for each segment and
-- sort them in descending order of product counts. The final output contains
-- 2 fields,
-- segment
-- product_count

select segment, count(distinct product) as product_count
from dim_product
group by segment 
order by product_count desc;




-- 4. Follow-up: Which segment had the most increase in unique products in
-- 2021 vs 2020? The final output contains these fields,
-- segment
-- product_count_2020
-- product_count_2021
-- difference

with 
product_count_2020 as
(select dim_product.segment, count(distinct dim_product.product) as product_count_2020
 from dim_product
inner join fact_sales_monthly
on dim_product.product_code = fact_sales_monthly.product_code
where fact_sales_monthly.fiscal_year = 2020
group by dim_product.segment
order by  product_count_2020 ),

product_count_2021 as
(select dim_product.segment, count(distinct dim_product.product) as product_count_2021
 from dim_product
inner join fact_sales_monthly
on dim_product.product_code = fact_sales_monthly.product_code
where fact_sales_monthly.fiscal_year = 2021
group by dim_product.segment
order by  product_count_2021 )

select product_count_2020.segment, product_count_2020, product_count_2021, (product_count_2021-product_count_2020) as difference
from product_count_2020, product_count_2021
where product_count_2020.segment = product_count_2021.segment
order by  difference desc;





-- 5. Get the products that have the highest and lowest manufacturing costs.
-- The final output should contain these fields,
-- product_code
-- product
-- manufacturing_cost

select dim_product.product_code, dim_product.product, fact_manufacturing_cost.manufacturing_cost
from dim_product
inner join fact_manufacturing_cost
on dim_product.product_code = fact_manufacturing_cost.product_code
where fact_manufacturing_cost.manufacturing_cost in ( 
													(select max(manufacturing_cost) from fact_manufacturing_cost),
												    (select min(manufacturing_cost) from fact_manufacturing_cost)
                                                     );



-- 6. Generate a report which contains the top 5 customers who received an
-- average high pre_invoice_discount_pct for the fiscal year 2021 and in the
-- Indian market. The final output contains these fields,
-- customer_code
-- customer
-- average_discount_percentage

select dim_customer.customer_code, dim_customer.customer, 
	   round( avg( fact_pre_invoice_deductions.pre_invoice_discount_pct)*100, 2) as average_discount_percentage
from dim_customer
inner join fact_pre_invoice_deductions
on dim_customer.customer_code = fact_pre_invoice_deductions.customer_code
where fact_pre_invoice_deductions.fiscal_year = 2021 and 
	  dim_customer.market = "India" 
group by dim_customer.customer_code, dim_customer.customer
having average_discount_percentage > (select  round(avg(fact_pre_invoice_deductions.pre_invoice_discount_pct)*100,2) from fact_pre_invoice_deductions)
order by average_discount_percentage desc
limit 5;




-- 7. Get the complete report of the Gross sales amount for the customer “Atliq
-- Exclusive” for each month. This analysis helps to get an idea of low and
-- high-performing months and take strategic decisions.
-- The final report contains these columns:
-- Month
-- Year
-- Gross sales Amount

select monthname(fact_sales_monthly.date) as Month,
		fact_sales_monthly.fiscal_year as Year,
        round(sum(fact_gross_price.gross_price * fact_sales_monthly.sold_quantity),2) as Gross_Sales_Amount
from fact_sales_monthly 
inner join dim_customer on fact_sales_monthly.customer_code = dim_customer.customer_code
inner join fact_gross_price on fact_sales_monthly.product_code = fact_gross_price.product_code
where dim_customer.customer = "Atliq Exclusive"
group by year(fact_sales_monthly.date) , monthname(fact_sales_monthly.date)  
order by Year;		



-- 8. In which quarter of 2020, got the maximum total_sold_quantity? The final
-- output contains these fields sorted by the total_sold_quantity,
-- Quarter
-- total_sold_quantity

select case 
		when month(date) = 9 then 1
		when month(date) = 10 then 1
		when month(date) = 11 then 1
		when month(date) = 12 then 2
		when month(date) = 1 then 2
		when month(date) = 2 then 2
		when month(date) = 3 then 3
		when month(date) = 4 then 3
		when month(date) = 5 then 3
		when month(date) = 6 then 4
		when month(date) = 7 then 4
		when month(date) = 8 then 4
        end as month_no ,
    sum(sold_quantity) as total_sold_quantity
from fact_sales_monthly
where fiscal_year = 2020 
group by month_no
order by  total_sold_quantity desc ;


-- 9. Which channel helped to bring more gross sales in the fiscal year 2021
-- and the percentage of contribution? The final output contains these fields,
-- channel
-- gross_sales_mln
-- percentage

with cwgs as 
(select dim_customer.channel,
        round(sum(fact_gross_price.gross_price * fact_sales_monthly.sold_quantity)/1000000,2) as Gross_Sales_mln -- converted Rs to millions
from fact_sales_monthly 
inner join dim_customer on fact_sales_monthly.customer_code = dim_customer.customer_code
inner join fact_gross_price on fact_sales_monthly.product_code = fact_gross_price.product_code
where fact_sales_monthly.fiscal_year = 2021
group by dim_customer.channel)

select cwgs.channel, cwgs.Gross_Sales_mln, 
		round(((cwgs.Gross_Sales_mln/(sum(cwgs.Gross_Sales_mln) over())) *100) , 2) as percentage
from cwgs
group by cwgs.channel, cwgs.Gross_Sales_mln
order by percentage desc;



-- 10. Get the Top 3 products in each division that have a high
-- total_sold_quantity in the fiscal_year 2021? The final output contains these fields,
-- division
-- product_code
-- product
-- total_sold_quantity
-- rank_order

with t3p as
(select dim_product.division, dim_product.product_code, dim_product.product,
		sum(fact_sales_monthly.sold_quantity) as total_sold_quantity, 
        dense_rank() over (partition by division order by sum(fact_sales_monthly.sold_quantity) desc) as rank_order
from dim_product 
inner join fact_sales_monthly
on dim_product.product_code = fact_sales_monthly.product_code
where fact_sales_monthly.fiscal_year = 2021
group by dim_product.division,dim_product.product_code, dim_product.product
)
select * from t3p where t3p.rank_order <= 3 ;



