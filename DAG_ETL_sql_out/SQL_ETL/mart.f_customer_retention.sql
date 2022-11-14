
delete from mart.f_customer_retention where period_id = pg_catalog.date_part('week', cast('{{ds}}' as timestamp without time zone)) ;

insert into mart.f_customer_retention 
(new_customers_count, returning_customers_count,refunded_customer_count, period_name, period_id, item_id, 
new_customers_revenue, returning_customers_revenue, customers_refunded)
with shipped_cust as (select  --total 615
	dc.week_of_year,
	fs1.item_id,
	fs1.customer_id,
	case when count(fs1.id) = 1 then 1 else 0
	end as ncc,
	case when count(fs1.id) > 1 then 1 else 0
	end as rtcc,
	case when count(fs1.id) = 1 then sum(fs1.payment_amount) else 0
	end as ncc_payment,
	case when count(fs1.id) > 1 then sum(fs1.payment_amount) else 0
	end as rtcc_payment
from mart.f_sales fs1
left join mart.d_calendar as dc on fs1.date_id = dc.date_id
where dc.week_of_year = pg_catalog.date_part('week', cast('{{ds}}' as timestamp without time zone))
		and fs1.status = 'shipped'
group by dc.week_of_year, fs1.item_id, fs1.customer_id),
refunded_cust as (select  --total 23
	dc.week_of_year,
	fs1.item_id,
	fs1.customer_id,
	count(fs1.id) as refunded_count,
	case when count(fs1.id) >= 1 then 1 else 0
	end as rfcc
from mart.f_sales fs1
left join mart.d_calendar as dc on fs1.date_id = dc.date_id
where dc.week_of_year = pg_catalog.date_part('week', cast('{{ds}}' as timestamp without time zone))
		and fs1.status = 'refunded'
group by dc.week_of_year, fs1.item_id, fs1.customer_id),
shipped_cust_count as (select
	coalesce(sum(ncc), 0) as new_customers_count,
	coalesce(sum(rtcc), 0) as returning_customers_count,
	coalesce(sum(ncc_payment), 0) as new_customers_revenue,
	coalesce(sum(rtcc_payment), 0) as returning_customers_revenue,
	'weekly' as period_name,
	coalesce(sc.week_of_year, pg_catalog.date_part('week', cast('{{ds}}' as timestamp without time zone))) as period_id,
	di.item_id as item_id
from mart.d_item di
left join shipped_cust sc on di.item_id = sc.item_id
group by coalesce(sc.week_of_year, pg_catalog.date_part('week', cast('{{ds}}' as timestamp without time zone))), di.item_id),
refunded_cust_count as (select
	coalesce(sum(rfcc), 0) as refunded_customer_count,
	coalesce(sum(refunded_count), 0) as customers_refunded,
	'weekly' as period_name,
	coalesce(rc.week_of_year, pg_catalog.date_part('week', cast('{{ds}}' as timestamp without time zone))) as period_id,
	di.item_id as item_id
from mart.d_item di
left join refunded_cust rc on di.item_id = rc.item_id
group by coalesce(rc.week_of_year, pg_catalog.date_part('week', cast('{{ds}}' as timestamp without time zone))), di.item_id)
select 
	 scc.new_customers_count,
	 scc.returning_customers_count,
	 rfcc.refunded_customer_count,
	 scc.period_name,
	 scc.period_id,
	 scc.item_id,
	 scc.new_customers_revenue,
	 scc.returning_customers_revenue,
	 rfcc.customers_refunded
from refunded_cust_count rfcc
join shipped_cust_count scc on scc.period_id = rfcc.period_id and scc.item_id = rfcc.item_id;