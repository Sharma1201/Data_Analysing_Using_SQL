-- Create database retails
create database retails;  
  
use retails;
show tables;
select * from customer_profiles;
select * from product_inventory;
select * from sales_transaction;

-- changing the coloumn name of table
ALTER TABLE product_inventory CHANGE ï»¿ProductID ProductID int(11);
ALTER TABLE customer_profiles CHANGE ï»¿CustomerID CustomerID int(11);
ALTER TABLE sales_transaction CHANGE ï»¿TransactionID TransactionID int(11);

select * from customer_profiles;

-- cleaning the dataset first 

-- disable safe update mode
set sql_safe_updates = 0;

-- clean nulls
update customer_profiles
set location = null
where Trim(location) = " ";

select location , count(*)
from customer_profiles
group by 1;

update customer_profiles
set location = 'West'
where location is null;

select * from customer_profiles
where location is null;                 

select * from customer_profiles;    -- now no nulls in location

-- update date datatype
update customer_profiles
set JoinDate = str_to_date(JoinDate, '%d/%m/%y');

select * from customer_profiles;

desc customer_profiles;

alter table customer_profiles
 modify JoinDate date;         -- now date is in correct datatype
 
-- outlier remove
delete from customer_profiles
where age = 131;           -- because in real life 131 age is not possible..only some % chance
                           -- so we remove the 131 age

-- cleaning of sales_transaction
select * from sales_transaction;
-- duplicates
select TransactionID, count(*) from sales_transaction
group by TransactionID
having count(*) > 1;           -- TransactionID 4999 & 5000 have duplicates value we have to remove

-- create a separate table containing the unique values and remove
-- the original table from the databases and replace the name of the 
-- new table with the original name
-- create separate table containing unique values
create table new_sales_transaction as 
select distinct * from sales_transaction;
-- deleting table with duplicates rows
drop table sales_transaction;
-- renaming  table with distinct table to original table
alter table new_sales_transaction rename to sales_transaction;

-- no duplicates now in sales_transaction table
select TransactionID, count(*) from sales_transaction
group by TransactionID
having count(*) > 1;   

-- date clean for sales_transaction
update sales_transaction
set TransactionDate = str_to_date(TransactionDate , '%d/%m/%y');

desc sales_transaction;

alter table sales_transaction
 modify TransactionDate date;
 
 -- identify the descrepancies in the price of the same product in
 -- sales_transaction and product_inventory
 select * from product_inventory;
 select * from sales_transaction;
 
 select pi.ProductID, st.TransactionID,
 st.Price as TransactionPrice,
 pi.Price as InventoryPrice
 from sales_transaction st 
 join product_inventory pi
 on st.ProductID = pi.ProductID
 where st.Price <> pi.Price;
 
 -- fix the price
 update sales_transaction st
 set price = ( select pi.price
 from product_inventory pi where
 st.ProductID = pi.ProductID )
 where st.ProductID IN
 (select ProductID from product_inventory
 where st.price <> product_inventory.price );
 
 select * from sales_transaction;
 -- 
 select * from product_inventory;

  -- cleaning of data is done
  
  -- Select statement - Used to retrieve specific columns or rows from a table.
  select * from customer_profiles;
  select * from product_inventory;
  select * from sales_transaction;
  
  -- Use Of WHERE and ORDER BY
  -- Where - Filters rows based on a given condition
  -- let's say we have to show all customers from 'west' location
  select *
  from customer_profiles
  where Location = 'west';
  
  -- Use of ORDER BY - Sorts the result set in ascending or descending order.
  -- let's say we have to find the list of products priced above 50,
  -- sorted from highest to lowest price.
  
Select ProductID, ProductName, Price 
From product_inventory
Where Price > 50
Order by Price DESC;

-- GROUP BY with Aggregate Functions - Groups rows with the same values for aggregate calculations
-- Find the total quantity sold for each product
-- I use group by with sum(Aggregate function)

Select ProductID, SUM(QuantityPurchased) AS TotalQuantitySold
From sales_transaction
Group by ProductID;

-- Find the average age of customers per location.  
Select Location, AVG(Age) AS Avg_age
From customer_profiles
Group by Location;

-- Get the total sales amount per customer
Select CustomerID, SUM(Price * QuantityPurchased) AS Total_Spent
From sales_transaction
Group by CustomerID
Order by Total_Spent DESC;

-- For each product,find the minimum and maximum
-- quantity purchased in a single transaction.
 
 Select 
    ProductID,
    MIN(QuantityPurchased) AS MinQtyPurchased,
    MAX(QuantityPurchased) AS MaxQtyPurchased
From sales_transaction
Group by ProductID;

-- Use of JOINS - JOIN is a clause that combines rows
-- from two or more tables based on a related column between them

-- LEFT JOIN - Returns all rows from the left table
-- & matching rows from the right table (NULL if no match).

-- Show all products and their total quantity sold
-- Using LEFT JOIN 

Select p.ProductName, SUM(s.QuantityPurchased) AS TotalQuantitySold
From product_inventory p
Left Join sales_transaction s ON p.ProductID = s.ProductID
Group by p.ProductName;

-- RIGHT JOIN - Returns all rows from the right table
-- & matching rows from the left table (NULL if no match).

-- Find all customers who have not purchased anything

Select c.CustomerID, c.Location
From sales_transaction s
Right Join customer_profiles c ON s.CustomerID = c.CustomerID
Where s.TransactionID IS NULL;

-- INNER JOIN - Returns rows where there is a match in both tables.
-- Find total quantity sold per location

Select c.Location, SUM(s.QuantityPurchased) AS TotalQuantitySold
From sales_transaction s
Inner Join customer_profiles c 
ON s.CustomerID = c.CustomerID
Group by c.Location
Order by TotalQuantitySold DESC;

-- SELF JOIN - Joins a table to itself to compare rows within the same table.
-- Find customers from the same location

Select c1.CustomerID AS Customer1, c2.CustomerID AS Customer2, c1.Location
From customer_profiles c1
Join customer_profiles c2 
ON c1.Location = c2.Location
Where c1.CustomerID <> c2.CustomerID;


-- USE OF SUBQUERIES - A query nested inside another query to provide intermediate results
-- Get all customers who spent more than the average spending of all customers

Select CustomerID,ROUND(SUM(Price * QuantityPurchased),2) AS TotalSpent,
    ROUND((Select AVG(CustomerTotal) 
         From (Select SUM(Price * QuantityPurchased) AS CustomerTotal
             From sales_transaction
             Group by CustomerID) AS avg_spending), 2) AS AverageSpending
From sales_transaction
Group by CustomerID
Having TotalSpent > (
    Select AVG(CustomerTotal) 
    From (
         Select SUM(Price * QuantityPurchased) AS CustomerTotal
         From sales_transaction
         Group by CustomerID
     ) AS avg_spending
);

-- Find the top 3 most expensive products using a subquery in WHERE
Select ProductName, Price
From product_inventory
Where Price IN (
    Select Price
    From (
        Select Price
        From product_inventory
        Order by Price DESC
        Limit 3
    ) AS top_prices
)
Order by Price DESC;
-- Creating Views
-- views - A virtual table created from a query,used to simplify complex queries and reuse logic.
-- Create a view to show customer spending summary
Create View customer_spending_summary AS
Select c.CustomerID, c.Location, 
       SUM(s.Price * s.QuantityPurchased) AS TotalSpent,
       COUNT(s.TransactionID) AS TotalTransactions
From customer_profiles c
Left Join sales_transaction s ON c.CustomerID = s.CustomerID
Group by c.CustomerID, c.Location;

-- querying the created views
Select * From customer_spending_summary
Order by TotalSpent DESC;

-- Creating indexes for optimization
-- indexes - Indexing in SQL involves creating a data structure
-- to improve the speed of data retrieval operations from a database table.

-- Create indexes to speed up joins and filtering.

Create Index idx_customer_id ON sales_transaction(CustomerID);
Create Index idx_product_id ON sales_transaction(ProductID);
Create Index idx_location ON customer_profiles(Location);

-- Optimizing a WHERE Filter
-- Query (Before Optimization)
Select * 
From sales_transaction
Where TransactionDate >= '2023-02-10';

-- Problem - Full table scan for all rows, even if we only need recent transactions

-- Optimization
CREATE Index idx_transaction_date ON sales_transaction(TransactionDate); 

SELECT * 
FROM sales_transaction
WHERE TransactionDate >= '2023-02-10';

-- Optimizing a JOIN
-- Query (Before Optimization):
Select c.CustomerID, c.Location, SUM(s.QuantityPurchased) AS TotalQuantity
From customer_profiles c
Inner Join sales_transaction s ON c.CustomerID = s.CustomerID
Group by c.CustomerID, c.Location;

-- Problem - Joins are slow if sales_transaction is big.

-- Optimization
Create Index idx_sales_customer_id ON sales_transaction(CustomerID);

Select c.CustomerID, c.Location, SUM(s.QuantityPurchased) AS TotalQuantity
From customer_profiles c
Inner Join sales_transaction s ON c.CustomerID = s.CustomerID
Group by c.CustomerID, c.Location;

