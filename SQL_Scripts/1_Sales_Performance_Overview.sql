-- # 1. Sales Performance Overview
-- KPI's for total Sales, Orders, Profit and Average_order_Vlaue
CREATE VIEW walmart_summary AS
with big_daddy as 
(
	select round(sum(total)) as sales, sum(quantity) as orders, round(sum(net_profit)) as profit
	from walmart
)
select sales, orders, profit,
round((sales/orders),2) as avg_order_value
from big_daddy; 

-- Top 5 and bottom 5 branches in terms of yearly sales 
create view branch_analysis as 
with branch_performance as 
(
	select branch, city, year, round(sum(total),2) as total_sales, 
	rank() over(partition by year order by sum(total) desc) as sales_rank
	from walmart
	group by branch, city, year
	order by year, sales_rank
)
SELECT * 
FROM branch_performance
WHERE sales_rank <= 5 
UNION ALL
SELECT * 
FROM branch_performance
WHERE sales_rank > (SELECT MAX(sales_rank) - 5 FROM branch_performance bp WHERE bp.year = branch_performance.year);


create view quarter_growth_analysis as
(
select branch,year, quarter, sum(total) as sales
from walmart 
group by branch, year, quarter
order by branch, year, quarter
);

with groth_analyser as 
(
select branch, year, quarter, sales, lag(sales) over(partition by branch order by year, quarter) as prev_q_sales from quarter_growth_analysis
)
select branch,year,quarter,sales,prev_q_sales,
case 
	when prev_q_sales is null then 0
    else ROUND(((sales - prev_q_sales) / NULLIF(prev_q_sales, 0)) * 100, 2) 
    end AS sales_growth_percentage
from groth_analyser
order by branch, year, quarter;



create view yearly_growth_analysis as
(
select branch,year, sum(total) as sales
from walmart 
group by branch, year
order by branch, year
);

with groth_analyser as 
(
select branch, year, sales, lag(sales) over(partition by branch order by year) as prev_y_sales from yearly_growth_analysis
)
select branch,year,sales,prev_y_sales,
case 
	when prev_y_sales is null then 0
    else ROUND(((sales - prev_y_sales) / NULLIF(prev_y_sales, 0)) * 100, 2) 
    end AS sales_growth_percentage
from groth_analyser
order by branch, year;


select count(distinct(branch)) from walmart 