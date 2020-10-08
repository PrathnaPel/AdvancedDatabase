-- HW2--
--Find minutes
select DATEDIFF (MINUTE,'1/1/2020 12:00 AM', '7/4/2020 9:15 PM') AS minutes;

--Identify the first Wednesday of 2020 which is 1/1/2020
--recursively add 7 days
--continue only when the year is 2020
WITH re_wednesday(n_day,wednesday) 
AS (
    SELECT 0, DATEADD(DAY,0, '1/1/2020')
    UNION ALL
    SELECT n_day+7, DATEADD(DAY,n_day+7,'1/1/2020')
    FROM re_wednesday
    WHERE 2020 = DATEPART(YEAR,DATEADD(DAY,n_day+7,'1/1/2020'))
)
SELECT * FROM re_wednesday;