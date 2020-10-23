create or alter view HumanResources.OldEmployee as
    select hre2.BusinessEntityId ManagerId, hre1.* 
    from HumanResources.Employee hre1 left outer join HumanResources.Employee hre2
    on hre1.OrganizationNode.GetAncestor(1) = hre2.OrganizationNode
go

create table result_bft (rownumber int identity(1,1),
	ManagerID int,
	EmployeeID int,
	Title varchar(max),
	DeptID int, Level int,
	thePath varchar(max))

insert into result_bft
	SELECT e.ManagerID, e.BusinessEntityID, e.JobTitle, edh.DepartmentID, 
        0 AS Level,
        convert(varchar(max), '.0|') + convert(varchar(max), e.BusinessEntityID) thePath
    FROM HumanResources.OldEmployee AS e
    INNER JOIN HumanResources.EmployeeDepartmentHistory AS edh
        ON e.BusinessEntityID = edh.BusinessEntityID AND edh.EndDate IS NULL
    WHERE ManagerID IS NULL

--set
--internally it should get the root node, then the second level and so on, breadth first search
--not very efficient because not all root node has a child, so there are alot of 0 value insert
declare @counter int =  1
--variable for root 
declare @thePath_temp varchar(max)
declare @curr_employeeid int
declare @curr_level int
--every node is a root and loop through the entire table-not very efficient
while @counter <=(select count(*) from HumanResources.OldEmployee)
begin
	set @curr_employeeid = (select EmployeeID from result_bft where rownumber = @counter)
	set @thePath_temp = (select thePath from result_bft where EmployeeID = @curr_employeeid)
	set @curr_level = (select level from result_bft where EmployeeID = @curr_employeeid)

	insert into result_bft
		SELECT e.ManagerID, e.BusinessEntityID, e.JobTitle, edh.DepartmentID,
			@curr_level+1,
			convert(varchar(max), @thePath_temp + '.' + convert(varchar, @curr_level+1) + '|' + convert(varchar, e.BusinessEntityID)) thePath
		FROM HumanResources.OldEmployee AS e
		INNER JOIN HumanResources.EmployeeDepartmentHistory AS edh
			ON e.BusinessEntityID = edh.BusinessEntityID AND edh.EndDate IS NULL
		WHERE e.ManagerId = @curr_employeeid

	set @counter = @counter +1
end

--order by rownumber to check if it did breadth first search correctly
SELECT *
FROM result_bft
order by rownumber
GO

drop table result_bft

drop view HumanResources.OldEmployee

