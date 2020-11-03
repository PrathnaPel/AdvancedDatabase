
/*

SW 505 - Midterm Examination
Due: 11/6/2020 @ 23:59:59

This is a programming project.  It must be done in Microsoft SQL Server Transact-SQL, 
version 2017+, and will be graded based on operation in that  environment.  The project 
must be submitted by email to tom.galasso@gmail.com by the due date or no credit will be given. 
Please submit a single file with a .SQL extension.  THIS file.

This is an individual programming project.  In the course of working on this program,
you may consult any textbook, personal notes, or internet reference that is STATIC.  You 
may not communicate with any human being in any way regarding the solution to this test.
This includes asynchronous communications like emails, posts, texts, and tweets, in addition
to verbal, phone, Skype or other synchronous communications.  If I suspect collaboration 
has occurred, I will mark the work of all suspected collaborators as 0 points, which will 
result in failing the course.  Please, please, don't take risks; do your own work by yourself.

PROBLEM DESCRIPTION: The Fairfield University Mars Automated Rover (FUMAR) is a 
motorized robot that sits on a flat plane on the surface of Mars and takes 4 soil samples 
every day.  The four locations are determined at random, but are all within 100 meters on
the X and Y axis of the point where the probe came to rest the previous day.  The software 
you are writing will determine the shortest path that the probe can possibly take to reach 
all four points.

The FUMAR always travels in a straight line between sites.  There are no obstructions on
the Martian plane for it to avoid.

Consider the following diagram:
                                                  
                                                  |+100  
                                                  |
                                                  |  X <-- Site 4 (4, 90)
                                                  |
                                                  |+80
                                                  |
     X <-- Site 3 (-92, 70)                       |
                                                  |
                                                  |+60
                                                  |
                                                  |
                                                  |
                                                  |+40
                                                  |                 X <-- Site 2 (36, 34)
                                                  |
                                                  |
                                                  |+20
                                                  | 
-100     -80       -60       -40       -20        |        +20       +40       +60       +80	  +100 
|---------|---------|---------|---------|---------O---------|---------|---------|---------|---------|
                                                 /|
                                                / |
                                               /  |
                  Original FUMAR Location (0,0)   |-20      X <-- Site 1 (20, -20)
                                                  |
                                                  |
                                                  |
                                                  |-40
                                                  |
                                                  |
                                                  |
                                                  |-60
                                                  |
                                                  |
                                                  |
                                                  |-80
                                                  |
                                                  |
                                                  |
                                                  |-100

The FUMAR must move from the origin to all 4 sites in the order that makes for the overall shortest path.
The FUMAR *will not* neccessarily move from Site 1, to Site 2, etc.
The FUMAR comes to rest at the last point reached, it does not return to the origin.

This is a variation of a travelling salesman problem.  The expected solution will use brute force, which
is appropriate in this case (the number of points are very small, and the cost of making the FUMAR travel
an imperfect path is very expensive).  A brute force solution calculates all possible paths, and picks
the shortest one.  Numerous other potential solutions exist.

There are two parts to this solution.

First, construct the view FUMAR_PATHS which represents all vertices in a connected graph; that is to say,
a straight line vertex between every site and every other site.  
HINT: All the math required for this is at http://www.mathopenref.com/coorddist.html

Second, construct the stored procedure GET_SHORTEST_FUMAR_PATH which will output (select) a result set 
as follows:
	Distance                                ThePath
	--------------------------------------- --------------------------------------------------------------------------------------------------------------
	247.16                                  Original Position (0, 0) --> Site 1 (20, -20) --> Site 2 (36, 34) --> Site 4 (4, 90) --> Site 3 (-92, 70)
    (1 row(s) affected)
HINT: This is the correct solution given the points shown in the example...

You *MAY NOT* alter the table structures, procedures, or views I have put in this file except where comments 
indicate you should.

The test will be graded as follows:
* 20 points for correctly constructing the FUMAR_PATHS view.
* 20 points for getting the correct answer, by any means, on 2 random sets of sites 
  (generated by the provided "GENERATE_FUMAR_SITES" procedure)

The testing procedure will be as follows:
* I will execute GENERATE_FUMAR_SITES
* I will look at your view FUMAR_PATHS, and determine if it contains correct data.
* I will execute your procedure GET_SHORTEST_FUMAR_PATHS and see what happens.
* If I get bad results in either of theose, I will determine if partial credit should be awarded.
   * In doing this, your comments will be very important.
* I will try the same thing on a different set of random coordinates.

EXTRA CREDIT - attempt only AFTER you have completed the main problem
* 2 points - make a procedure "GENERATE_N_FUMAR_SITES (@siteCount int)" which creates @siteCount 
  sites in the underlying table instead of 4
* 5 points - validate that GET_SHORTEST_FUMAR_PATHS works for @siteCount sites, instead of 4
* 3 points - (as text in this file) record how long it takes for GET_SHORTEST_FUMAR_PATHS to 
  run on a variety of site of counts.  Are the results as you expected?  Why or why not?

OVERALL:
* Partial credit will be awared to solutions that are valid SQL, execute, 
  but have errors in logic that cause the answer to be wrong.
* Partial credit will be given for solutions that do not execute only if the programmer explains the problems
  and what he or she did to try and fix them.
* NO CREDIT will be given to a solution that does not run and does not have any description of what was 
  done.

GOOD LUCK.  My advice to you is to start early.  If you aren't halfway done by Sunday, you will probably not succeed.

*/

-- DO NOT ALTER THIS TABLE.  It is set up to allow you to solve the problem easily
drop table FUMAR_SITES
go

create table FUMAR_SITES (
    SiteNumber int primary key nonclustered,
    SiteName nvarchar(100),
    XCoordinate int check (XCoordinate between -100 and 100),
    YCoordinate int check (YCoordinate between -100 and 100)
)
go

-- DO NOT ALTER THIS PROCEDURE.  It builds your data set for testing.
drop procedure GENERATE_FUMAR_SITES
go

create procedure GENERATE_FUMAR_SITES
as begin
    delete from FUMAR_SITES

    insert into FUMAR_SITES select 0, 'Original Position', 0, 0

    declare @siteNumber int
    set @siteNumber = 1

    while @siteNumber <= 4 begin
        insert into FUMAR_SITES 
        select @siteNumber, 'Site #' + convert(nvarchar, @siteNumber),
               100 - floor(rand()*200), 100 - floor(rand()*200)
        
        set @siteNumber = @siteNumber + 1
    end
end
go

exec GENERATE_FUMAR_SITES
go


-- HERE'S YOUR STUFF.  You should only put stuff where the comments are.

drop view FUMAR_PATHS
go

create view FUMAR_PATHS (StartSite, EndSite, Distance) as
    -- *** PART 1:
    -- Write this view such that every combination of sites
    -- Appear as (StartSite, EndSite, Distance), including the Original
    -- Position.  There should be 20.  Distance is the length
    -- of a line segment between the two points on a plane.
	------------------------------Modified--------------------------
	-- cross join, and set condition where it shouldn't point to itself
	-- At first, I thought that using sitenumber might be a good idea, 
	-- but if I use string_split to retrive value to build 'ThePath' it doesn't guarantee the order
	select 
		concat(f.SiteName,' (',f.XCoordinate,', ',f.YCoordinate,')'), 
		concat(fs.SiteName,' (',fs.XCoordinate,', ',fs.YCoordinate,')'), 
		sqrt(square(fs.XCoordinate-f.XCoordinate)+square(fs.YCoordinate-f.YCoordinate))
	from FUMAR_SITES as f 
	cross join FUMAR_SITES as fs
	where f.SiteNumber != fs.SiteNumber
go

select * from FUMAR_PATHS

drop procedure GET_SHORTEST_FUMAR_PATH
go

create procedure GET_SHORTEST_FUMAR_PATH
as begin
    -- *** PART 2:
    -- Write this procedure so it calculates the shortest past from the
    -- Original Position to ALL nodes (but not back).
    -------------------Modified------------------------------
	-- Use '/' as separator
	-- ReachableSites will generate all possible paths it can take
	declare @sitesCount int = (select count(*) from FUMAR_SITES)
	;with ReachableSites as (
		select EndSite, 1 Hops, Distance, convert(varchar(max),StartSite+'/' +EndSite) thePath from FUMAR_PATHS where StartSite = 'Original Position (0, 0)'
		union all
		select FP.EndSite, R.Hops+1, R.Distance+FP.Distance, convert(varchar(max),thePath+'/'+FP.EndSite) from ReachableSites R, FUMAR_PATHS FP
		where R.EndSite = FP.StartSite
		and R.Hops < @sitesCount
		and FP.EndSite not in(select value from string_split(thePath,'/'))
	)
	select top 1 cast(Distance as decimal(10,2)) as Distance, REPLACE(thePath,'/', ' --> ') ThePath
	from ReachableSites
	-- Must traverse all nodes
	where @sitesCount = (select count(*) from string_split(thePath,'/'))
	order by Distance
end
go

exec GET_SHORTEST_FUMAR_PATH
go

---------------------------EXTRA CREDIT----------------------
/*
* 2 points - make a procedure "GENERATE_N_FUMAR_SITES (@siteCount int)" which creates @siteCount 
  sites in the underlying table instead of 4
* 5 points - validate that GET_SHORTEST_FUMAR_PATHS works for @siteCount sites, instead of 4
* 3 points - (as text in this file) record how long it takes for GET_SHORTEST_FUMAR_PATHS to 
  run on a variety of site of counts.  Are the results as you expected?  Why or why not?
*/

drop procedure GENERATE_N_FUMAR_SITES
go

create procedure GENERATE_N_FUMAR_SITES (@siteCount int)
as begin
    delete from FUMAR_SITES

    insert into FUMAR_SITES select 0, 'Original Position', 0, 0

    declare @siteNumber int
    set @siteNumber = 1
	-- changed 4 to @siteCount
    while @siteNumber <= @siteCount begin
        insert into FUMAR_SITES 
        select @siteNumber, 'Site #' + convert(nvarchar, @siteNumber),
               100 - floor(rand()*200), 100 - floor(rand()*200)
        
        set @siteNumber = @siteNumber + 1
    end
end
go

exec GENERATE_N_FUMAR_SITES 5
--exec GENERATE_N_FUMAR_SITES 1
--exec GENERATE_N_FUMAR_SITES 8
--exec GENERATE_N_FUMAR_SITES 9
--exec GENERATE_N_FUMAR_SITES 10
go

------ Validate-----------
exec GET_SHORTEST_FUMAR_PATH
go
/* Result
Distance                                ThePath
--------------------------------------- -------------------------------------------------------------------------------------------------------------------------------------------
321.15                                  Original Position (0, 0) --> Site #4 (71, -18) --> Site #2 (-39, 11) --> Site #1 (-29, 52) --> Site #3 (-56, 44) --> Site #5 (-98, 92)

(1 row affected)
*/

/*
-- Conclusion
Sitecount = 5 , instant
Sitecount = 1 , instant
Sitecount = 8 , 23 seconds
Sitecount = 9 , 6 minutes 36 seconds
Sitecount = 10, takes too long. Terminated at 10 minutes 11 seconds
I expected to computation time to increase but I didn't expect it to increase that much.
The different between sitecount 8 and 9 is 6 minutes, and I think it's even bigger between 9 and 10.
As you have said, this algorithm has the time complxity of O(n!) which would explain such growth.
*/