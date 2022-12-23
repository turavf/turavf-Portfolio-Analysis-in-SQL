#Find max date
SELECT MAX(date)
from prices;

#Most recent 12 months, 18 months, 24 months return for each of the securities
SELECT a.date, a.ticker, 
        LN(a.value / a.price_12m) AS continuous_return_12M,
        LN(a.value / a.price_18m) AS continuous_return_18M,
        LN(a.value / a.price_24m) AS continuous_return_24M        
FROM    
(SELECT *, 
	LAG(value, 250) 
	OVER(PARTITION BY ticker 
	ORDER BY date)
		AS price_12M,
	LAG(value, 375) 
	OVER(PARTITION BY ticker 
	ORDER BY date)
		AS price_18M,
	LAG(value, 500) 
	OVER(PARTITION BY ticker 
	ORDER BY date)
		AS price_24M 
   FROM prices
   WHERE price_type = "Adjusted") a
   WHERE date = '2022-12-09';

#Portfolio's Return
SELECT a.date, 
        SUM(LN(a.value / a.price_12M)*(b.quantity)) as portfolio_return_12M,
        SUM(LN(a.value / a.price_18M)*(b.quantity)) as portfolio_return_18M,
        SUM(LN(a.value / a.price_24M)*(b.quantity)) as portfolio_return_24M
FROM    
(SELECT *, 
	LAG(value, 250) 
	OVER(PARTITION BY ticker 
	ORDER BY date)
		AS price_12M,
	LAG(value, 375) 
	OVER(PARTITION BY ticker 
	ORDER BY date)
		AS price_18M,
	LAG(value, 500) 
	OVER(PARTITION BY ticker 
	ORDER BY date)
		AS price_24M 
   FROM prices
   WHERE price_type = "Adjusted") a
   left join holdings as b
   on a.ticker=b.ticker
   WHERE date = '2022-12-09';

----------------------------------------------------------------------------
#Variances
SELECT z.ticker,
VARIANCE(z.continuous_returns) AS variance
FROM
(SELECT a.*, (a.value - a.lagged_price)/a.lagged_price as discrete_returns,
LN(a.value/a.lagged_price)as continuous_returns
FROM
(SELECT *, LAG(value, 125) OVER(
								PARTITION BY ticker
                                ORDER BY date)
                                AS lagged_price
FROM prices
WHERE price_type = 'Adjusted'
AND date >= '2022-06-09') a
) as z
GROUP BY z.ticker;

----------------------------------------------------------------------------
#Most recent 12 months sigma (risk) for each of the securities
SELECT z.ticker,
	AVG(z.continuous_return) AS mu,
    STD(z.continuous_return) AS sigma,
    (AVG(z.continuous_return) / STD(z.continuous_return)) AS risk_adj_return
FROM
(SELECT a.*,
        LN(a.value / a.lagged_price) AS continuous_return    
FROM    
(SELECT *, 
	LAG(value, 250)
	OVER(PARTITION BY ticker
	ORDER BY date)
		AS lagged_price
   FROM prices
   WHERE price_type = "Adjusted") a
   WHERE a.date >= '2021-12-09') z
   GROUP BY z.ticker;
      
#Portfolio 
SELECT sum(sigma*(b.quantity)) as sigma_portfolio, 
SUM(risk_adj_return*b.quantity) as risk_adj_return_portfolio
FROM (
SELECT z.ticker,
	AVG(z.continuous_return) AS mu,
    STD(z.continuous_return) AS sigma,
    (AVG(z.continuous_return) / STD(z.continuous_return)) AS risk_adj_return
FROM
(SELECT a.*,
        LN(a.value / a.lagged_price) AS continuous_return    
FROM    
(SELECT *, 
	LAG(value, 250)
	OVER(PARTITION BY ticker
	ORDER BY date)
		AS lagged_price
   FROM prices
   WHERE price_type = "Adjusted") a
   WHERE a.date >= '2021-12-09') z
   GROUP BY z.ticker) s
   left join holdings as b
   on s.ticker=b.ticker;

----------------------------------------------------------------------------
#Change in risk and expected returns after portfolio changes
SELECT a.date, a.ticker, 
        LN(a.value / a.price_12m) AS new_return_12M,
        LN(a.value / a.price_18m) AS new_return_18M,
        LN(a.value / a.price_24m) AS new_return_24M        
FROM    
(SELECT *, 
	LAG(value, 250) 
	OVER(PARTITION BY ticker 
	ORDER BY date)
		AS price_12M,
	LAG(value, 375) 
	OVER(PARTITION BY ticker 
	ORDER BY date)
		AS price_18M,
	LAG(value, 500) 
	OVER(PARTITION BY ticker 
	ORDER BY date)
		AS price_24M 
   FROM mytable
   WHERE price_type = "Adjusted") a
   WHERE date = '2022-12-09';

SELECT z.ticker,
	AVG(z.continuous_return) AS new_mu,
    STD(z.continuous_return) AS new_sigma
FROM
(SELECT a.*,
        LN(a.value / a.lagged_price) AS continuous_return    
FROM    
(SELECT *, 
	LAG(value, 250)
	OVER(PARTITION BY ticker
	ORDER BY date)
		AS lagged_price
   FROM mytable
   WHERE price_type = "Adjusted") a
   WHERE a.date >= '2021-12-09') z
   GROUP BY z.ticker;
   
#Portfolio's Return
SELECT a.date, 
        SUM(LN(a.value / a.price_12M)*(b.quantity)) as return_new_portfolio_12M,
        SUM(LN(a.value / a.price_18M)*(b.quantity)) as return_new_portfolio_18M,
        SUM(LN(a.value / a.price_24M)*(b.quantity)) as return_new_portfolio_24M
FROM    
(SELECT *, 
	LAG(value, 250) 
	OVER(PARTITION BY ticker 
	ORDER BY date)
		AS price_12M,
	LAG(value, 375) 
	OVER(PARTITION BY ticker 
	ORDER BY date)
		AS price_18M,
	LAG(value, 500) 
	OVER(PARTITION BY ticker 
	ORDER BY date)
		AS price_24M 
   FROM mytable
   WHERE price_type = "Adjusted") a
   left join holdings_new as b
   on a.ticker=b.ticker
   WHERE date = '2022-12-09';

SELECT sum(sigma*(b.quantity)) as sigma_portfolio
FROM (
SELECT z.ticker,
	AVG(z.continuous_return) AS mu,
    STD(z.continuous_return) AS sigma
FROM
(SELECT a.*,
        LN(a.value / a.lagged_price) AS continuous_return    
FROM    
(SELECT *, 
	LAG(value, 250)
	OVER(PARTITION BY ticker
	ORDER BY date)
		AS lagged_price
   FROM mytable
   WHERE price_type = "Adjusted") a
   WHERE a.date >= '2021-12-09') z
   GROUP BY z.ticker) s
   left join holdings_new as b
   on s.ticker=b.ticker;
   