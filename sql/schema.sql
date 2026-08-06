-- public.customer_data definition

-- Drop table

-- DROP TABLE public.customer_data;

CREATE TABLE public.customer_data (
	customer_id int4 NOT NULL,
	age int4 NULL,
	gender text NULL,
	purchase_amount_usd numeric NULL,
	"location" text NULL,
	"size" text NULL,
	color text NULL,
	season text NULL,
	review_rating numeric NULL,
	subscription_status text NULL,
	discount_applied text NULL,
	previous_purchases numeric NULL,
	payment_method text NULL,
	frequency_of_purchases text NULL,
	CONSTRAINT pk_customer_data PRIMARY KEY (customer_id)
);


-- public.order_data definition

-- Drop table

-- DROP TABLE public.order_data;

CREATE TABLE public.order_data (
	order_id int4 NOT NULL,
	order_date text NULL,
	ship_mode text NULL,
	segment text NULL,
	category text NULL,
	sub_category text NULL,
	product_id text NULL,
	cost_price numeric NULL,
	list_price numeric NULL,
	quantity int4 NULL,
	discount_percent numeric NULL,
	customer_id int4 NULL,
	CONSTRAINT pk_order_data PRIMARY KEY (order_id),
	CONSTRAINT fk_order_customer FOREIGN KEY (customer_id) REFERENCES public.customer_data(customer_id)
);