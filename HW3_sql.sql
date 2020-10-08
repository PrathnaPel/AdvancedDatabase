--- Homework 3 ---
---Part A ---
--Incremental increase the value of DATEDIFF of year, month etc for each variable
--store values, and setup switch cases to remove 0 value
--This Function, and Test Table will be drop
CREATE FUNCTION StringDateDuration (@smallDate DATETIME)
RETURNS NVARCHAR(MAX)
AS
BEGIN
	DECLARE @bigDate DATETIME
	DECLARE @year INT , @month INT, @day INT, @hour INT,@minute INT
	DECLARE @output NVARCHAR(MAX)
	SET @bigDate = GETDATE()
	--Switch value
	IF (@smallDate > @bigDate)
		SET @bigDate = @smallDate
	IF (@smallDate = @bigDate)
		SET @smallDate = GETDATE()

	SET @year = DATEDIFF(YY,@smallDate,@bigDate)
	IF (DATEADD(YY, @year, @smallDate) > @bigDate)
		SET @year = @year -1
	SET @smallDate = DATEADD(YY, @year, @smallDate)
	
	SET @month = DATEDIFF(MM,@smallDate,@bigDate)
	IF (DATEADD(MM, @month, @smallDate) > @bigDate)
		SET @month = @month - 1
	SET @smallDate = DATEADD(MM, @month, @smallDate)

	SET @day = DATEDIFF(DD,@smallDate,@bigDate)
	IF (DATEADD(DD, @day, @smallDate) > @bigDate)
		SET @day = @day - 1
	SET @smallDate = DATEADD(DD, @day, @smallDate)

	SET @hour = DATEDIFF(HH,@smallDate,@bigDate)
	IF (DATEADD(HH, @hour, @smallDate) > @bigDate)
		SET @hour = @hour -1
	SET @smallDate = DATEADD(HH, @hour, @smallDate)

	SET @minute = DATEDIFF(MI,@smallDate,@bigDate)
	IF (DATEADD(MI, @minute, @smallDate) > @bigDate)
		SET @minute = @minute -1
	SET @smallDate = DATEADD(MI, @minute, @smallDate)

	SET @output =(SELECT 
	CONCAT(
	CASE
    WHEN @year != 0 THEN CONVERT(nvarchar(max),@year) + ' Years, '
	END,
	CASE
    WHEN @month != 0 THEN CONVERT(nvarchar(max),@month) + ' Months, '
	END,
	CASE
    WHEN @day != 0 THEN CONVERT(nvarchar(max),@day) + ' Days, '
	END,
	CASE
    WHEN @hour != 0 THEN CONVERT(nvarchar(max),@hour) + ' Hours, '
	END,
	CASE
    WHEN @minute != 0 THEN CONVERT(nvarchar(max),@minute) + ' Minutes'
END
	))
	RETURN @output

END
GO

CREATE TABLE TEST_DATE (
     Dkey INT PRIMARY KEY,
     Ddate DATETIME NOT NULL );

INSERT INTO TEST_DATE VALUES (1, '10/15/2003 22:13:00');
INSERT INTO TEST_DATE VALUES (2, '10/05/2020 00:00:00');
INSERT INTO TEST_DATE VALUES (3, '12/15/2031 00:00:00');

SELECT dbo.StringDateDuration(Ddate) AS DateDuration, Ddate FROM TEST_DATE;

--Drop All
DROP FUNCTION dbo.StringDateDuration;
DROP TABLE TEST_DATE;

---PART B---
---USING AdventureWorks2017 Database
---When EVEN number get value at RowNumber of total/2 and total/2 + 1 divide by 2
---When ODD get value at RowNumber equal to CEILING total/2
DECLARE @sum INT;
SET @sum = (SELECT count(UnitPrice) FROM AdventureWorks2017.Sales.SalesOrderDetail);

SELECT
CASE
	WHEN @sum%2 = 0 THEN --EVEN
		(SELECT SUM(sub.UnitPrice)/2 
		FROM 
		(SELECT UnitPrice,ROW_NUMBER() OVER (ORDER BY UnitPrice ASC) as RowNumber FROM AdventureWorks2017.Sales.SalesOrderDetail )sub 
		WHERE sub.RowNumber = @sum/2 OR sub.RowNumber = @sum/2 +1)
	ELSE --ODD
		(SELECT sub.UnitPrice
		FROM 
		(SELECT UnitPrice,ROW_NUMBER() OVER (ORDER BY UnitPrice ASC) as RowNumber FROM AdventureWorks2017.Sales.SalesOrderDetail )sub 
		WHERE sub.RowNumber = CEILING( @sum/2.0))
END AS MedianValue;