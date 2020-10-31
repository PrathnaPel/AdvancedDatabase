create table CITIES (
    NAME varchar(30) primary key
)
go

create table ROUTES (
    FROM_CITY varchar(30) references CITIES,
    TO_CITY varchar(30) references CITIES,
    MILES int not null,
    primary key (from_city, to_city)
)
go


insert into cities values ('New York')
insert into cities values ('Washington')
insert into cities values ('Miami')
insert into cities values ('Chicago')
insert into cities values ('St. Louis')
insert into cities values ('Dallas')
insert into cities values ('Denver')
insert into cities values ('Phoenix')
insert into cities values ('Los Angeles')
insert into cities values ('San Francisco')
insert into cities values ('Seattle')

insert into routes values ('New York', 'Washington', 200)
insert into routes values ('New York', 'Chicago', 700)
insert into routes values ('Miami', 'Washington', 900)
insert into routes values ('St. Louis', 'Washington', 700)
insert into routes values ('St. Louis', 'Miami', 1050)
insert into routes values ('St. Louis', 'Chicago', 250)
insert into routes values ('St. Louis', 'Dallas', 550)
insert into routes values ('St. Louis', 'Denver', 800)
insert into routes values ('Chicago', 'Denver', 900)
insert into routes values ('Seattle', 'Denver', 1000)
insert into routes values ('San Francisco', 'Denver', 950)
insert into routes values ('San Francisco', 'Seattle', 700)
insert into routes values ('San Francisco', 'Los Angeles', 350)
insert into routes values ('Phoenix', 'Los Angeles', 350)
insert into routes values ('Phoenix', 'Dallas', 900)
insert into routes values ('Miami', 'Dallas', 1100)
go

-- because the vertexes are undirected, this view makes them seem directed
-- having two rows would be a DENORMALIZATION!  (if we change or add one...)
create  view ALL_ROUTES (FROM_CITY, TO_CITY, MILES) as 
    select FROM_CITY, TO_CITY, MILES from ROUTES
    union
    select TO_CITY, FROM_CITY, MILES from ROUTES
go

--------HOMEWORK 6-----
/*
*Add an additional column called thePath. Similar to Iztik Ben-Gan, just concat TO_CITY to thePath
---Optimization---
*set condition where TO_CITY is NOT IN ReachableCities, which effectively stop it from going backward
*To get all TO_CITY from ReachableCities, I string_split thePath to list, then use NOT IN 
*Basically I'm marking path that it already traverse and tell it not to go to the marked path.
*/
-----------------------
create or alter procedure SHORTEST_PATH @fromCity varchar(30), @toCity varchar(30)
as
    set nocount on
    if not exists (select * from CITIES where NAME = @fromCity) begin
        print 'No service is offered from ' + @fromCity + '.'
        return
    end
    if not exists (select * from CITIES where NAME = @toCity) begin
        print 'No service is offered to ' + @toCity + '.'
        return
    end
    if @toCity = @fromCity begin
        print 'You can pretty much walk from ' + @fromCity + ' to ' + @toCity + '.'
        return
    end

	declare @CityCount int = (select count(*) from cities) -- to stop iteration!
	declare @mark int = (select count(*) from ALL_ROUTES)
	declare @shortestPath int
	declare @path nvarchar(max) --save output
	;with ReachableCities as (
		--add one column thePath
		select TO_CITY, 1 HOPS, MILES, convert(nvarchar(max), @fromCity+','+ALL_ROUTES.TO_CITY) thePath from ALL_ROUTES where FROM_CITY = @fromCity

		union all
		--concat TO_CITY to thePath
		select A.TO_CITY, R.HOPS+1, R.MILES+A.MILES, convert(nvarchar(max),thePath + ','+A.TO_CITY) thePath
		from ReachableCities R, ALL_ROUTES A
		where R.TO_CITY = A.FROM_CITY
		and R.HOPS < @CityCount
		--split thePath to list, and check
		and A.TO_CITY not in(select value from string_split(thePath,','))
	)
	--order by mile ascending and get top value
	select top 1 @shortestPath = MILES, @path=thePath
	from ReachableCities
	where TO_CITY = @toCity
	order by MILES

    if @shortestPath is not null
        print 'It is ' + convert(varchar, @shortestPath) + ' miles from ' + 
              replace(@path,',',' => ') + '.'
    else
        -- this should never happen!
        print 'No trains exists from ' + @fromCity + ' to ' + @toCity + '.'
go

exec SHORTEST_PATH 'New York', 'New York'
exec SHORTEST_PATH 'New York', 'Los Angeles'
exec SHORTEST_PATH 'New York', 'Toledo'
exec SHORTEST_PATH 'New York', 'Miami'
exec SHORTEST_PATH 'Miami', 'New York'
exec SHORTEST_PATH 'Seattle', 'Dallas'
go

drop table ROUTES
go

drop table CITIES
go

drop view ALL_ROUTES
go

drop procedure SHORTEST_PATH
go