# Stamp Registration

select * from fact_ts_ipass ; 
select * from fact_stamps ;
select * from dim_date ;

select s.dist_code , sum(s.documents_registered_rev) as d_rev,
d.district
from fact_stamps s
join dim_districts d 
on s.dist_code = d.dist_code
group by s.dist_code, d.district
order by d_rev desc
limit 5 offset 0 ;

select year(date_add("2020-12-1", interval -3 month)) ;

select * from fact_stamps ;

select  year((`month` + interval -(3) month)) ;

# Q1. How does the revenue generated from document registration vary across districts in Telangana? List down
-- the top 5 districts that showed the highest document registration revenue growth between FY 2019 and 2022

with rev2019 as (
select d.district , sum(documents_registered_rev) / 10000000 revincr19
	from fact_stamps s
	join dim_districts d
	on s.dist_code = d.dist_code
where fiscal_year = 2019
group by d.district
order by revincr19 desc ) , 
rev2022 as (
select d.district , sum(documents_registered_rev) / 10000000 revincr22
	from fact_stamps s
	join dim_districts d
	on s.dist_code = d.dist_code
where fiscal_year = 2022
group by d.district
order by revincr22 desc )

select a.district , revincr22 - revincr19 as diff, a.revincr19, b.revincr22
	from rev2019 a 
	join rev2022 b
	on a.district = b.district 
    group by a.district 
    order by diff desc
    limit 5 ;


# Q2. How does the revenue generated from document registration compare to the revenue generated from e-stamp 
-- challans across districts? List down the top 5 districts where e-stamps revenue contributes 
-- significantly more to the revenue than the documents in FY 2022?

with revenue as
(
select d.district , sum(documents_registered_rev) / 10000000 document_revenue,
sum(estamps_challans_rev) / 10000000 estamp_revenue
	from fact_stamps s
	join dim_districts d
	on s.dist_code = d.dist_code
where fiscal_year = 2022
group by d.district )
select district, estamp_revenue - document_revenue as difference
from revenue 
group by district 
order by difference desc 
limit 5 offset 0;

# Q3. Is there any alteration of e-Stamp challan count and document registration count pattern since 
-- the implementation of e-Stamp challan? If so, what suggestions would you propose to the government?

select  fiscal_year, date,  sum(documents_registered_cnt) as document_count, 
sum(estamps_challans_cnt) as estamp_count
from fact_stamps
group by date, fiscal_year
order by date, fiscal_year asc;

# Q4. Categorize districts into three segments based on their stamp registration revenue generation 
-- during the fiscal year 2021 to 2022.

with a as (
select d.district, sum(estamps_challans_rev) / 10000000 as estamp_revenue_202122
from fact_stamps s
	join dim_districts d
	on s.dist_code = d.dist_code
where fiscal_year in (2021, 2022) 
group by d.district
order by estamp_revenue_202122 desc)
select *,
	case 
	when estamp_revenue_202122 > 1000 then "High Revenue"
    when estamp_revenue_202122 > 100 then "Medium Revenue"
    when estamp_revenue_202122 < 100 then "Low Revenue"
    End as categoty from a
group by district
order by estamp_revenue_202122 desc ;   

# Transportation
#Q5. Investigate whether there is any correlation between vehicle sales and specific months or 
-- seasons in different districts. Are there any months or seasons that consistently show higher  or 
-- lower sales rate, and if yes, what could be the driving factors? (Consider Fuel-Type category only)

with a as (
select dist_code,month, 'fuel_type_petrol' as fuel_type, fuel_type_petrol as Vehicles_sold from fact_transport
union all
select dist_code,month,'fuel_type_diesel' as fuel_type ,fuel_type_diesel as Vehicles_sold from fact_transport
union all
select dist_code,month, 'fuel_type_electric' as fuel_type, fuel_type_electric as Vehicles_sold from fact_transport
union all
select dist_code,month,  'fuel_type_others' as fuel_type , fuel_type_others as Vehicles_sold from fact_transport )
select 
d.district, month, sum(vehicles_sold) as Vehicle_Sale
	from a
    join dim_districts d 
    on a.dist_code = d.dist_code
    group by d.district, month
    order by month asc;
	
#Q6. How does the distribution of vehicles vary by vehicle class (MotorCycle, MotorCar, AutoRickshaw, 
-- Agriculture) across different districts? Are there any districts with a predominant preference for a 
-- specific vehicle class? Consider FY 2022 for analysis.

with a as (
select dist_code,month, 'vehicleClass_Agriculture' as vehicle_class, 
vehicleClass_Agriculture as Vehicles_sold from fact_transport where fiscal_year = 2022
union all
select dist_code,month, 'vehicleClass_AutoRickshaw' as vehicle_class, 
vehicleClass_AutoRickshaw as Vehicles_sold from fact_transport where fiscal_year = 2022
union all
select dist_code,month, 'vehicleClass_MotorCar' as vehicle_class, 
vehicleClass_MotorCar as Vehicles_sold from fact_transport where fiscal_year = 2022
union all
select dist_code,month,  'vehicleClass_MotorCycle' as vehicle_class, 
vehicleClass_MotorCycle as Vehicles_sold from fact_transport where fiscal_year = 2022
union all
select dist_code,month,  'vehicleClass_others' as vehicle_class, 
vehicleClass_others as Vehicles_sold from fact_transport where fiscal_year = 2022 )
select d.district, month,a.vehicle_class, sum(vehicles_sold) as vehicles_sold from a 
	join dim_districts d 
	on a.dist_code = d.dist_code
group by d.district, month ,a.vehicle_class
order by month asc;

# VIEW --> fact_fueltype_vehiclesold

select dist_code,month,fiscal_year, 'fuel_type_petrol' as fuel_type, fuel_type_petrol as Vehicles_sold from fact_transport
union all
select dist_code,month,fiscal_year,'fuel_type_diesel' as fuel_type ,fuel_type_diesel as Vehicles_sold from fact_transport
union all
select dist_code,month,fiscal_year, 'fuel_type_electric' as fuel_type, fuel_type_electric as Vehicles_sold from fact_transport
union all
select dist_code,month,fiscal_year,  'fuel_type_others' as fuel_type , fuel_type_others as Vehicles_sold from fact_transport ;

#Q7. List down the top 3 and bottom 3 districts that have shown the highest and lowest vehicle sales 
-- growth during FY 2022 compared to FY 2021? (Consider and compare categories: Petrol, Diesel and Electric)

#TOP 3 BOTTOM 3

with cte21 as (
select d.district, sum(f.vehicles_sold) as vehicles_sold21
from  fact_fueltype_vehiclesold  f
join dim_districts d
on f.dist_code = d.dist_code
where fiscal_year = 2021 
and f.fuel_type in ('fuel_type_electric','fuel_type_diesel','fuel_type_petrol')
group by d.district
order by vehicles_sold21 desc ),

cte22 as (
select d.district, sum(f.vehicles_sold) as vehicles_sold22
from  fact_fueltype_vehiclesold  f
join dim_districts d
on f.dist_code = d.dist_code
where fiscal_year = 2022 
and f.fuel_type in ('fuel_type_electric','fuel_type_diesel','fuel_type_petrol')
group by d.district
order by vehicles_sold22 desc )

select a.* ,b.vehicles_sold22, ( vehicles_sold22  - vehicles_sold21 ) / vehicles_sold21 * 100 as per_diff
	from cte21 a
	join cte22 b
	on a.district = b.district
group by a.district
order by per_diff desc ;
    
#Q8. List down the top 5 sectors that have witnessed the most significant investments in FY 2022.

select sector, round(sum(investment_in_cr),2) as investment_in_cr
from fact_ts_ipass 
 where fiscal_year = 2022
group by sector 
order by investment_in_cr desc
limit 5 offset 0;

#Q9. List down the top 3 districts that have attracted the most significant sector investments during FY 2019 to 2022?

select d.district, round(sum(t.investment_in_cr),2)  as investment_in_cr
from fact_ts_ipass t
join dim_districts d
	on t.dist_code = d.dist_code
    group by d.district 
    order by investment_in_cr desc
    limit 3 offset 0;
    
#Q10. Are there any particular sectors that have shown substantial investment in multiple districts 
-- between FY 2021 and 2022?

select sector, count(distinct dist_code) multiple_districts
from fact_ts_ipass 
 where fiscal_year in (2021,2022) 
group by sector 
order by multiple_districts desc;

#Q11. Can we identify any seasonal patterns or cyclicality in the investment trends for specific sectors? 
-- Do certain sectors experience higher investments during particular months?

select fiscal_year, month ,sector , round(sum(investment_in_cr), 2) as invst
from fact_ts_ipass
group by fiscal_year, month , sector
order by fiscal_year, invst desc ;













