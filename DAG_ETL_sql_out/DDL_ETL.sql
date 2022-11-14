--1 Этап. Формирование столбца status
ALTER TABLE staging.user_order_log
ADD COLUMN status varchar(15); 
ALTER TABLE mart.f_sales
ADD COLUMN status varchar(15); 

--2 Этап. Создание mart.f_customer_retention
create table IF NOT EXISTS mart.f_customer_retention (
	new_customers_count int4 NOT NULL, --кол-во новых клиентов (тех, которые сделали только один заказ за рассматриваемый промежуток времени).
	returning_customers_count int4 NOT NULL,--кол-во вернувшихся клиентов (тех, которые сделали только несколько заказов за рассматриваемый промежуток времени).
	refunded_customer_count int4 NOT NULL,--кол-во клиентов, оформивших возврат за рассматриваемый промежуток времени.
	period_name varchar(6) not null,--weekly.
	period_id int4 NOT NULL, --идентификатор периода (номер недели или номер месяца).
	item_id int4 NOT NULL, --идентификатор категории товара.
	new_customers_revenue numeric(10, 2) NULL, --доход с новых клиентов.
	returning_customers_revenue numeric(10, 2) NULL, --доход с вернувшихся клиентов.
	customers_refunded int4 NOT NULL, --количество возвратов клиентов. 
	unique (period_id, item_id)
);