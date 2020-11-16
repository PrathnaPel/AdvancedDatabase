--Homework7------

/*
A bank stores check information in a partitioned table. Each partition is on
its own file group. The partitions are monthly partitions on check cleared
date. Assuming the data starts 7/1/2020, write the SQL that defines their
partitioned table environment.

Write the SQL that the bank would have to run to create a new partition on
11/1/2020
*/

--create database will drop at the end
create database PartitionTestDatabase
go

use PartitionTestDatabase
go
--create filegroup
alter database PartitionTestDatabase
add filegroup m1fg;
go
alter database PartitionTestDatabase
add filegroup m2fg;
go
alter database PartitionTestDatabase
add filegroup m3fg;
go
alter database PartitionTestDatabase
add filegroup m4fg;
go

/*********************
Since we know it start with 7/1/2020,
if we add one month to this date, and use right range
it would get everything before 8/1/2020 not including august 1st

m1fg contains 7/1/2020 to 7/31/2020
m2fg contains 8/1/2020 to 8/31/2020
m3fg contains 9/1/2020 to 9/30/2020
m4fg contains 10/1/2020 to infinity

*/
--partition fuction
create partition function DateRangePF (date)
as range right for values ('8/1/2020','9/1/2020','10/1/2020');
--partition scheme
create partition scheme DateRangePS
as partition DateRangePF
to (m1fg,m2fg,m3fg,m4fg);

CREATE TABLE PartitionTable (id int identity(1,1), pdate date, col2 char(10))  
    ON DateRangePS (pdate) ;  
GO

---------create a new partition on 11/1/2020--------------
/*
1-Make new filegroup
2-do alter partition scheme with one additional filegroup (empty filegroup --> allow to use alter partition function)
3-alter partition function and use split range 11/1/2020
 this will split the range 8/1/2019 to infinity --> 8/1/2020 to 11/1/2020 to infinity
 
 increase 1 filegroup per month

m4fg 10/1/2020 to 11/1/2020
m5fg 11/1/2020 to infinity
*/
alter database PartitionTestDatabase
add filegroup m5fg;

--m5fg is an empty filegroup
ALTER PARTITION SCHEME DateRangePS  
NEXT USED m5fg;

--With an empty filegroup, we can use this function
alter partition function DateRangePF()
split range ('11/1/2020');


select * from sys.filegroups

--check boundaries
select * from sys.partition_range_values

--There should be there 5 fanouts since there are 4 boundaries
select * from sys.partition_functions

use master
go

drop database PartitionTestDatabase
go