/*### Задача 1. Средняя стоимость заказа по категориям товаров
Вывести среднюю cуммарную стоимость товаров в заказе для каждой категории товаров, учитывая только заказы, созданные в марте 2023 года. */
WITH order_totals AS (
    SELECT 
        orders.id AS order_id, 
        categories.name AS category_name,
        SUM(order_items.quantity * products.price) AS order_total
    FROM orders
    INNER JOIN order_items ON orders.id = order_items.order_id
    INNER JOIN products ON order_items.product_id = products.id
    INNER JOIN categories ON products.category_id = categories.id
    WHERE orders.created_at >= '2023-03-01' AND orders.created_at < '2023-04-01'
    GROUP BY orders.id, categories.name
)
SELECT 
    category_name, 
    AVG(order_total) AS avg_order_amount
FROM order_totals
GROUP BY category_name;

/*### Задача 2. Рейтинг пользователей по сумме оплаченных заказов {10 баллов}
Вывести топ-3 пользователей, которые потратили больше всего денег на оплаченные заказы. Учитывать только заказы со статусом "Оплачен".
В отдельном столбце указать, какое место пользователь занимает*/

WITH order_totals AS (
    SELECT 
        users.name AS nm, 
        orders.status AS st, 
        SUM(products.price * order_items.quantity) AS fn --просто захотел попрактиковаться с cte
    FROM users
    INNER JOIN orders ON orders.user_id = users.id
    INNER JOIN order_items ON orders.id = order_items.order_id
    INNER JOIN products ON products.id = order_items.product_id
    WHERE orders.status = 'Оплачен'
    GROUP by users.name, orders.status
	order by SUM(products.price * order_items.quantity) desc
)
SELECT 
    nm, 
    st, 
    fn,
    RANK() OVER (ORDER BY fn DESC) AS rank -- Проставляем ранг
FROM order_totals
LIMIT 3;

/*### Задача 3. Количество заказов и сумма платежей по месяцам {10 баллов}
Вывести количество заказов и общую сумму платежей по каждому месяцу в 2023 году.*/

with purchase_per_month as(
	select TO_CHAR(orders.created_at, 'YYYY-MM') AS year_month,
	count(orders.id) as count
	from orders  
	GROUP BY TO_CHAR(orders.created_at, 'YYYY-MM')
	order by TO_CHAR(orders.created_at, 'YYYY-MM')

),
summary as(
	select TO_CHAR(orders.created_at, 'YYYY-MM') as date,
	SUM(order_items.quantity*products.price) as total
	from order_items 
	inner join products on order_items.product_id=products.id
	inner join orders on order_items.order_id=orders.id
	GROUP BY TO_CHAR(orders.created_at, 'YYYY-MM')
	order by TO_CHAR(orders.created_at, 'YYYY-MM')

)

select summary.date, purchase_per_month.count, summary.total
from summary
inner join purchase_per_month on purchase_per_month.year_month = summary.date;


/*### Задача 4. Рейтинг товаров по количеству продаж {10 баллов}
Вывести топ-5 товаров по количеству продаж, а также их долю в общем количестве продаж. 
Долю округлить до двух знаков после запятой*/

WITH product_sales AS (
    SELECT 
        p.name AS product_name,
        SUM(oi.quantity) AS total_sold
    FROM products p
    INNER JOIN order_items oi ON p.id = oi.product_id
    GROUP BY p.name
),
total_sales AS (
    SELECT SUM(total_sold) AS total
    FROM product_sales
)
SELECT 
    ps.product_name,
    ps.total_sold,
    ROUND((ps.total_sold * 100.0 / ts.total), 2) AS sales_percentage
FROM product_sales ps, total_sales ts
ORDER BY ps.total_sold DESC
LIMIT 5;


/*### Задача 5. Пользователи, которые сделали заказы на сумму выше среднего {10 баллов}
Вывести пользователей, общая сумма оплаченных заказов которых превышает 
среднюю сумму оплаченных заказов по всем пользователям.*/

WITH order_totals AS (
    SELECT 
        users.name AS nm, 
        orders.status AS st, 
        SUM(products.price * order_items.quantity) AS fn,
        AVG(SUM(products.price * order_items.quantity)) OVER () AS avg_fn 
    FROM users
    INNER JOIN orders ON orders.user_id = users.id
    INNER JOIN order_items ON orders.id = order_items.order_id
    INNER JOIN products ON products.id = order_items.product_id
    WHERE orders.status = 'Оплачен'
    GROUP by users.name, orders.status
	order by SUM(products.price * order_items.quantity) desc
)

select nm, fn from order_totals
where fn>avg_fn;

/*### Задача 6. Рейтинг товаров по количеству продаж в каждой категории
Для каждой категории товаров вывести топ-3 товара по количеству проданных единиц. 
Используйте оконную функцию для ранжирования товаров внутри каждой категории.*/

with popular as(select categories.name as name, products.name as pr_name, sum(order_items.quantity) as total,
ROW_NUMBER() OVER (PARTITION BY categories.name ORDER BY sum(order_items.quantity) DESC) AS rank from orders
inner join order_items on order_items.order_id = orders.id
inner join products on order_items.product_id = products.id
inner join categories on products.category_id = categories.id
group by  categories.name, products.name)

SELECT 
    name,
    pr_name,
    total
FROM popular
WHERE rank <= 3
ORDER BY name, rank;

/*### Задача 7. Категории товаров с максимальной выручкой в каждом месяце
Вывести категории товаров, которые принесли максимальную выручку 
в каждом месяце первого полугодия 2023 года.*/

WITH monthly_revenue AS (
    SELECT
        TO_CHAR(orders.created_at, 'YYYY-MM') AS month,
        categories.name AS category_name,
        SUM(order_items.quantity * products.price) AS total_revenue,
        RANK() OVER (PARTITION BY TO_CHAR(orders.created_at, 'YYYY-MM') ORDER BY SUM(order_items.quantity * products.price) DESC) AS rank
    FROM orders
    INNER JOIN order_items ON orders.id = order_items.order_id
    INNER JOIN products ON order_items.product_id = products.id
    INNER JOIN categories ON products.category_id = categories.id
    WHERE orders.created_at >= '2023-01-01' AND orders.created_at < '2023-07-01'
    GROUP BY TO_CHAR(orders.created_at, 'YYYY-MM'), categories.name
)

SELECT
    month,
    category_name,
    total_revenue
FROM monthly_revenue
WHERE rank = 1
ORDER BY month;

/*### Задача 8. Накопительная сумма платежей по месяцам
Вывести накопительную сумму платежей по каждому месяцу в 2023 году. 
Накопительная сумма должна рассчитываться нарастающим итогом. Подсказка: нужно понять, как работает ROWS BETWEEN,
и какое ограничение используется по умолчанию для SUM BY*/

select to_char(p.payment_date, 'YYYY-MM') as month,
sum(p.amount) as monthly_payments,
sum(sum(p.amount)) over ( order by to_char(p.payment_date, 'YYYY-MM') rows between unbounded preceding and current row
) as cumulative_payments
from payments p
inner join orders o on p.order_id = o.id
where p.payment_date is not null
group by to_char(p.payment_date, 'YYYY-MM')
order by month;
