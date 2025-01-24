
-- Below queries are as per SQL Server

select * from incubyte;

-- Total revenue over a specific period.
select sum(TransactionAmount) as total_amount from incubyte where returned = 'No'

-- Monthly revenue
select datepart(month,transactiondate) as MonthWise, sum(TransactionAmount) as total_amount 
from incubyte 
where returned = 'No' 
group by datepart(month,transactiondate)

-- Revenue contribution by region
select isnull(region, 'others') as Region, round(sum(TransactionAmount),2) as total_amount ,
row_number() over(order by sum(TransactionAmount) desc) as region_wise_rank
from incubyte 
where returned = 'No' 
group by region

-- revenue by city
select isnull(city, 'others') as city, round(sum(TransactionAmount),2) as total_amount ,
concat(ROUND(SUM(TransactionAmount) * 100.0 / SUM(SUM(TransactionAmount)) OVER (), 2) ,'%') AS percentage_of_total,
row_number() over(order by sum(TransactionAmount) desc) as region_wise_rank
from incubyte 
where returned = 'No' 
group by city

--Revenue of top 3 cities region wise
with cte1 as (
select isnull(region, 'others') as Region,city, round(sum(TransactionAmount),2) as total_amount ,
row_number() over(partition by region order by sum(TransactionAmount) desc) as rank
from incubyte 
where returned = 'No' 
group by region, city)
SELECT * from cte1 where rank <= 3

-- Revenue by store type
select coalesce(storetype, 'Other'), round(sum(TransactionAmount),2)  as total_amount
from incubyte 
where returned = 'No' 
group by storetype order by sum(TransactionAmount) desc

-- revenue % paymentmethod
select coalesce(paymentmethod, 'Other') as paymentmethod, round(sum(TransactionAmount),2)  as total_amount,
concat(ROUND(SUM(TransactionAmount) * 100.0 / SUM(SUM(TransactionAmount)) OVER (), 2) ,'%') AS percentage_of_total
from incubyte 
where returned = 'No' 
group by paymentmethod order by sum(TransactionAmount) desc


-- Impact of discounts on sales revenue.

SELECT 
    CASE WHEN DiscountPercent > 0 THEN 'Discounted' ELSE 'Non-Discounted' END AS SaleType,
    SUM(TransactionAmount) AS TotalRevenue
FROM incubyte
GROUP BY CASE WHEN DiscountPercent > 0 THEN 'Discounted' ELSE 'Non-Discounted' END;

-- number of sales discount wise

SELECT 
    CASE 
        WHEN DiscountPercent BETWEEN 0 AND 5 THEN '0-5%'
        WHEN DiscountPercent BETWEEN 6 AND 10 THEN '6-10%'
        WHEN DiscountPercent > 10 THEN '>10%'
    END AS DiscountBracket,
    COUNT(*) AS NumberOfSales,
    SUM(TransactionAmount) AS TotalRevenue
FROM incubyte
GROUP BY 
    CASE 
        WHEN DiscountPercent BETWEEN 0 AND 5 THEN '0-5%'
        WHEN DiscountPercent BETWEEN 6 AND 10 THEN '6-10%'
        WHEN DiscountPercent > 10 THEN '>10%'
    END;


--top 50 customer
SELECT top 50
    coalesce(cast(customerid as varchar) , 'other'),
    COUNT(*) AS NumberOfSales,
    round(SUM(TransactionAmount),2) AS TotalRevenue
FROM incubyte 
WHERE Returned = 'No'
group by customerid 
order by sum(TransactionAmount) desc

-- revenue as per age distribution
SELECT 
    CASE
        WHEN CustomerAge BETWEEN 18 AND 24 THEN '18-24'
        WHEN CustomerAge BETWEEN 25 AND 34 THEN '25-34'
        WHEN CustomerAge BETWEEN 35 AND 44 THEN '35-44'
        WHEN CustomerAge BETWEEN 45 AND 54 THEN '45-54'
        WHEN CustomerAge >= 55 THEN '55+'
        ELSE 'Unknown'
    END AS AgeGroup,
    COUNT(DISTINCT CustomerID) AS CustomerCount
FROM incubyte
WHERE Returned = 'No'
GROUP BY 
    CASE
        WHEN CustomerAge BETWEEN 18 AND 24 THEN '18-24'
        WHEN CustomerAge BETWEEN 25 AND 34 THEN '25-34'
        WHEN CustomerAge BETWEEN 35 AND 44 THEN '35-44'
        WHEN CustomerAge BETWEEN 45 AND 54 THEN '45-54'
        WHEN CustomerAge >= 55 THEN '55+'
        ELSE 'Unknown'
    END
ORDER BY AgeGroup;

-- total, avg revenue by gender 
SELECT 
    CustomerGender,
    ROUND(SUM(TransactionAmount), 2) AS TotalSpent,
    ROUND(AVG(TransactionAmount), 2) AS AvgSpentPerTransaction,
    COUNT(*) AS TotalTransactions
FROM incubyte
GROUP BY CustomerGender
ORDER BY TotalSpent DESC;

-- top 10 customners with most loyalty points
SELECT top 10 
    CustomerID,
    SUM(LoyaltyPoints) AS TotalPointsEarned
FROM incubyte
GROUP BY CustomerID
ORDER BY TotalPointsEarned DESC;

--- top selling products
SELECT 
    coalesce(ProductName,'Other Products'),
    SUM(Quantity) AS TotalQuantitySold
FROM incubyte
WHERE Returned = 'No'
GROUP BY ProductName
ORDER BY TotalQuantitySold DESC;

-- most returned product
with actual_inventory as (
SELECT 
    COALESCE(ProductName, 'Other Products') AS ProductName,
    ROUND(SUM(CASE WHEN Returned = 'No' THEN TransactionAmount ELSE 0 END), 2) AS Revenue_Item_Sold,
    ROUND(SUM(CASE WHEN Returned = 'Yes' THEN TransactionAmount ELSE 0 END), 2) AS Revenue_Items_Returned,
    ROUND(SUM(TransactionAmount), 2) AS TotalTransactionAmt, -- Total revenue
    
    SUM(CASE WHEN Returned = 'No' THEN Quantity ELSE 0 END) AS Quantity_Items_Sold,
    SUM(CASE WHEN Returned = 'Yes' THEN Quantity ELSE 0 END) AS Quantity_Items_Returned,
    SUM(Quantity) AS TotalQuantity -- Total quantity including returned and non-returned items
FROM incubyte
GROUP BY ProductName)
select ProductName,
Revenue_Items_Sold - Revenue_Items_Returned as Actual_revenue,
Quantity_Items_Sold - Quantity_Items_Returned as Actual_quantity_sold
from actual_inventory
order by Quantity_Items_Sold - Quantity_Items_Returned desc;

-- most returned products
SELECT 
    ProductName,
    COUNT(*) AS TotalReturns
FROM incubyte
WHERE Returned = 'Yes'
GROUP BY ProductName
ORDER BY TotalReturns DESC; 

--avg delivery time 
SELECT 
    Region,
    ROUND(AVG(DeliveryTimeDays), 2) AS AvgDeliveryTime,
    COUNT(CASE WHEN DeliveryTimeDays > 7 THEN 1 END) AS DelayedDeliveries,
    ROUND(COUNT(CASE WHEN DeliveryTimeDays > 7 THEN 1 END) * 100.0 / COUNT(*), 2) AS DelayPercentage
FROM incubyte
GROUP BY Region
ORDER BY AvgDeliveryTime DESC;

-- shipping cost
SELECT 
    Region,
    ROUND(AVG(ShippingCost), 2) AS AvgShippingCost,
    ROUND(MIN(ShippingCost), 2) AS MinShippingCost,
    ROUND(MAX(ShippingCost), 2) AS MaxShippingCost,
    COUNT(*) AS TotalOrders
FROM incubyte
GROUP BY Region
ORDER BY AvgShippingCost DESC;

--region wise shipping cost
SELECT 
    Region,
    ROUND(SUM(ShippingCost), 2) AS TotalShippingCost,
    ROUND(SUM(TransactionAmount), 2) AS TotalTransactionValue,
    ROUND(SUM(ShippingCost) * 100.0 / SUM(TransactionAmount), 2) AS ShippingCostPercentage
FROM incubyte
GROUP BY Region
ORDER BY ShippingCostPercentage DESC;

--- DeliveryTimeDays
SELECT 
    Region,
    ROUND(AVG(DeliveryTimeDays), 2) AS AvgDeliveryTime,
    ROUND(MIN(DeliveryTimeDays), 2) AS MinDeliveryTime,
    ROUND(MAX(DeliveryTimeDays), 2) AS MaxDeliveryTime,
FROM incubyte
GROUP BY Region
ORDER BY AvgDeliveryTime DESC;

--  sale on day of the week

select isnull(datename(month,transactiondate), 'Other') as MonthWise,isnull(ProductName, 'other products') as Products,
sum(TransactionAmount)  as total_amount
from incubyte as i
where returned = 'No' 
group by datename(month,transactiondate),ProductName,datepart(month,transactiondate)
order by datepart(month,transactiondate), sum(TransactionAmount) desc

--feedback
SELECT 
    Region,
    AVG(FeedbackScore) AS AvgFeedbackScore,
    COUNT(*) AS TotalReviews
FROM incubyte
GROUP BY Region

--avg discount
SELECT 
    COALESCE(ProductName, 'Other Products'), 
    ROUND(AVG(DiscountPercent), 2) AS AvgDiscountPercentage
FROM incubyte
GROUP BY Productname;

--avg discount for repeat customers
SELECT 
    CustomerID,
    concat(round(AVG(DiscountPercent),2),'%') AS AvgDiscountPercentage,
    COUNT(DISTINCT TransactionID) AS TotalTransactions
FROM incubyte
WHERE CustomerID IN (
    SELECT CustomerID 
    FROM incubyte
    WHERE Returned = 'No'
    GROUP BY CustomerID 
    HAVING COUNT(DISTINCT TransactionID) > 1
)
GROUP BY CustomerID
ORDER BY TotalTransactions DESC;



-- number of discounted and non-discounted users
SELECT 
    CASE 
        WHEN DiscountPercent > 0 THEN 'Discounted Customer'
        ELSE 'Non-Discounted Customer'
    END AS CustomerType,
    COUNT(DISTINCT CustomerID) AS CustomerCount
FROM incubyte
GROUP BY 
    CASE 
        WHEN DiscountPercent > 0 THEN 'Discounted Customer'
        ELSE 'Non-Discounted Customer'
    END;

-- Assuming shiping cost is borne by the company not customer.
SELECT 
    Region,
    round(SUM(TransactionAmount - ShippingCost),2) AS NetProfit
FROM incubyte
WHERE Returned = 'No'
GROUP BY Region
ORDER BY NetProfit DESC;

-- return by city
SELECT 
    City,
    ROUND((SUM(CASE WHEN Returned = 'Yes' THEN 1 ELSE 0 END) * 100.0) / COUNT(*), 2) AS ReturnRate,
    COUNT(*) AS TotalTransactions
FROM incubyte
GROUP BY City
ORDER BY ReturnRate DESC;

--return rate by store
SELECT 
    StoreType,
    ROUND((SUM(CASE WHEN Returned = 'Yes' THEN 1 ELSE 0 END) * 100.0) / COUNT(*), 2) AS ReturnRate,
    COUNT(*) AS TotalTransactions
FROM incubyte
GROUP BY StoreType
ORDER BY ReturnRate DESC;

--avg feedback according to delivery days
SELECT 
    DeliveryTimeDays,
    ROUND(AVG(FeedbackScore), 2) AS AvgFeedbackScore,
    COUNT(*) AS TotalTransactions
FROM incubyte
WHERE Returned = 'No'
GROUP BY DeliveryTimeDays
ORDER BY DeliveryTimeDays;


-- the most loyal customers who has returned the prodcuts

SELECT * from incubyte 
where LoyaltyPoints > 9000 and returned = 'Yes' order by LoyaltyPoints desc ;



