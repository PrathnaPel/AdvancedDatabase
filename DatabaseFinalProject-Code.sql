---------------------Data Definition Language------------
create database PPEL_TEST_DATABASE
go
use PPEL_TEST_DATABASE
go

-- Create Table
create table FINGER(
finger_id int identity(1,1) primary key,
hand varchar(255) not null,
finger varchar(255) not null
);

create table TYPING_USER(
user_id int identity(1,1) primary key,
name varchar(255) not null
);

create table MAPPING(
mapping_id int identity(1,1) primary key,
finger_id int not null,
character varchar(2) not null,
foreign key (finger_id) references FINGER(finger_id)
);

create table MISTAKE_HISTORY(
mapping_id int not null,
user_id int not null,
mistake_id int identity(1,1),
number numeric,
date_time datetime default getdate(),
primary key (mistake_id),
foreign key (mapping_id) references MAPPING(mapping_id),
foreign key (user_id) references TYPING_USER(user_id)
);

create table FINGER_PROFICIENCY_HISTORY(
finger_id int not null,
user_id int not null,
proficiency_id int identity(1,1),
proficiency decimal(5,2) check (proficiency>=0 and proficiency<=1),
date_time datetime default getdate(),
primary key (proficiency_id),
foreign key (finger_id) references FINGER(finger_id),
foreign key (user_id) references TYPING_USER(user_id)
);
go

-- load data

create or alter procedure loadFinger
as begin
	delete from FINGER;
	--ignore thumb because it only use for spacebar
	declare @fingers varchar(max) = 'index,middle,ring,pinky';
	insert into FINGER(hand,finger) select 'left', value from string_split(@fingers,',');
	insert into FINGER(hand,finger) select 'right', value from string_split(@fingers,',');
end
go

exec loadFinger
go

create or alter procedure loadMapping
as begin 
	declare @mapinput varchar(max)= ''

	declare @max int = (select count(*) from FINGER);
	print @max
	declare @counter int = 1
	while @counter <= @max
	begin
		--finger mapping
		select @mapinput =
			case
				-- left
				when hand = 'left' and finger = 'index' then '$,%,4,5,r,t,f,g,v,b'
				when hand = 'left' and finger = 'middle' then '#,3,e,d,c'
				when hand = 'left' and finger = 'ring' then '@,2,w,s,x'
				when hand = 'left' and finger = 'pinky' then '`,~,!,1,q,a,z'
				--right
				when hand = 'right' and finger = 'index' then '^,&,6,7,y,u,h,j,n,m'
				when hand = 'right' and finger = 'middle' then '*,8,i,k,<'
				when hand = 'right' and finger = 'ring' then '(,9,o,l,>,.'
				when hand = 'right' and finger = 'pinky' then '),0,p,:,;,?,/,-,_,+,=,{,[,},],|,\,",'''
			end
		from FINGER where finger_id = @counter;
		insert into MAPPING(finger_id,character) select @counter, value from string_split(@mapinput,',');
		set @counter = @counter + 1
	end

	-- write an insert for ","
	insert into MAPPING(finger_id,character) select finger_id,',' from FINGER where hand ='right' and finger = 'middle'

end
go

exec loadMapping
go
---------------------Programmability---------------------
-- views
-- Using newid() to randomize 
create or alter view getNewID as select newid() as new_id
go

-- For testing input values for GENERATE_TYPING procedure
create or alter view getHandFinger
as
	select concat(hand,'-',finger) as handfinger from FINGER
go

--------------------Functions--------------------------
/*
Get one character randomly from a given finger
Params: fingerid - finger info
Returns: one random character that mapped to the input finger
*/

create or alter function getRandomCharacter(@fingerid int)
returns varchar(2)
as begin
	return (select Top 1 character from MAPPING 
	where finger_id = @fingerid 
	order by (select new_id from getNewID))
end
go

/*
Get one character randomly based on mistake history
Params: fingerid - finger info
		userid - user info
		days - maximum number of days between now and the recorded date
		num - minimum number of mistakes
Returns: one random character that mapped to the input finger and user info
*/
create or alter function getRandomCharacterFromMistakeHistory(@fingerid int,@userid int, @days int, @num int)
returns varchar(2)
as begin
	declare @result varchar(2)
	return (select top 1 character from MAPPING 
			INNER JOIN
			-- get mapping_id of all mistake that are 
			-- n days or less
			-- m mistake or more
			(select mapping_id from MISTAKE_HISTORY where user_id = @userid and DATEDIFF(DAY,date_time,GETDATE()) <=@days and number >=@num)sub 
			on MAPPING.mapping_id = sub.mapping_id
			-- filter to pick character that mapped to selected finger
			where finger_id = @fingerid
			-- randomize it
			order by (select new_id from getNewID))
end
go

/*
Get the finger id based on the user proficiency
Params: userid- user info
		MaximumProficiency - highiest proficiency
		days - maximum number of days between now and the recorded date
Return: one fingerid based on given proficiency value and days recorded
*/

create or alter function getOneRandomFingerIdFromProficiencyHistory(@userid int, @MaximumProficiency decimal(5,2), @days int)
returns int
as begin
	return (select top 1 fp.finger_id 
	from FINGER_PROFICIENCY_HISTORY as fp 
	where fp.user_id = @userid and DATEDIFF(DAY,fp.date_time,GETDATE()) <= @days and fp.proficiency <= @MaximumProficiency
	group by finger_id
	order by (select new_id from getNewID))
end
go

/*
Split hand and finger
Assumption: dash(-) character is separator
Params: handfinger - combination of hand and finger with dash(-) as separator
Return: Fingerid
*/
create or alter function splitHandAndFinger(@handfinger varchar(max))
returns int
as
begin
	return (select FINGER.finger_id as fingerid from FINGER,
	(select substring(@handfinger, 0, charindex('-',@handfinger)) as hand,
	substring(@handfinger, charindex('-',@handfinger)+1, len(@handfinger)) as finger)sub
	where sub.hand = FINGER.hand and sub.finger = FINGER.finger)
end
go

/*
Get one random finger id from finger list input
Params: List on hand-finger input separated by commas(,)
Returns: one fingerid
*/
create or alter function getOneRandomFingerIdFromFingerList(@listpf varchar(max))
returns int
as begin
	declare @result int
	select @result =
	case value
		when 'left-hand' then (select top 1 finger_id from FINGER where hand = 'left' order by (select new_id from getNewID))
		when 'right-hand' then (select top 1 finger_id from FINGER where hand = 'right' order by (select new_id from getNewID))
		when 'both-hand' then (select top 1 finger_id from FINGER order by (select new_id from getNewID))
		else (select top 1 dbo.splitHandAndFinger(value))
	end
	from string_split(@listpf,',') order by (select new_id from getNewID)
	return @result
end
go

/*
From homework solution, I modified a little bit to fit my problem
Count the number of each character in the string
*/
create or alter function characterCountHardWay (@string nvarchar(255))
returns @words table (
	word nvarchar(2),
	wordcount int
)
as begin
	declare @thisword nvarchar(2) = ''
	
	while len(@string) > 0 begin 
		set @thisword = @thisword + substring(@string, 1, 1)
		set @string = substring(@string, 2, len(@string)-1)
		
		-- if it is in the table update it
		if exists (select * from @words where word = @thisword)
			update @words set wordcount = wordcount+1 where word = @thisword
		-- otherwise insert it
		else
			insert into @words select @thisword, 1
		
		set @thisword = ''

	end

	return
end
go


------------------ Procedures-----------------------------

/*
Default typing practice that doesn't require user info
Generate typing practice from listed of given hand-finger
Params: list of hand-fingers
		blocklen - number of words
Returns: Combination of n words with space in between
Acceptable inputs: 
	left-index,left-middle,left-ring,left-pinky,right-index,right-middle,right-ring,right-pinky
	left-hand, right-hand, both-hand
Can include a combination of both set, like 'left-index,right-hand'
*/
create or alter procedure GENERATE_TYPING (@listpf varchar(max), @blocklen int)
as begin
	-- remove whitespace
	set @listpf = (select REPLACE(@listpf, ' ', ''))
	-- making sure input is valid
	declare @iftest int = 0
	declare @varc int =(select count(*) from string_split(@listpf,',')) 
	select @iftest += 
	case
		when value = 'left-hand' then 1
		when value = 'right-hand' then 1
		when value = 'both-hand' then 1
		when value in (select * from getHandFinger) then 1
		else 0
	end
	from string_split(@listpf,',')
	-- Input not above values, all invalid or some invalid
	if @iftest < @varc or @blocklen <= 0
		begin
			print 'invalid input'
			return
		end
	declare @result varchar(max)
	-- number of words or block
	declare @blockcounter int = 0
	while @blockcounter < @blocklen
	begin
		-- number of characters per word is between 3-10
		declare @wordlen int = (SELECT FLOOR(RAND()*(10-3+1))+3)
		declare @word varchar(max) = ''
		declare @wordcounter int = 0
		while @wordcounter < @wordlen
		begin
			-- select one random finger from the given list
			declare @fingerid int = (select dbo.getOneRandomFingerIdFromFingerList(@listpf))
			-- select one random character
			set @word +=(select dbo.getRandomCharacter(@fingerid))
			set @wordcounter += 1
		end
		set @result = CONCAT(@result,@word,' ')
		set @blockcounter += 1
	end
	print @result
end
go

/*
Typing practice for user
Generate typing practice based on fingerProficiencyHistory, and user mistake_history
Params: blocklen - determine number of words
		userid - userid
		MaximumProficiency - the highiest proficiency that user's can pull from
		MaximumNumberofMistakes - the highiest total of mistake it should pull from
Return: A typing text that based on user typing proficiency, and mistake
*/
create or alter procedure GENERATE_TYPING_MODIFIER (@userid int, @MaximumProficieny decimal(5,2), @MinimumNumberofMistakes int, @days int, @blocklen int)
as begin
	-- Check if user exist
	if (select count(*) from TYPING_USER where user_id = @userid) = 0
		begin
			print 'User does not exist'
			return
		end
	if (select count(*) from FINGER_PROFICIENCY_HISTORY where user_id = @userid and proficiency < @MaximumProficieny) = 0
		begin
			print 'User does not have finger proficiency record. OR MaximumProficiency is too low'
			return
		end
	declare @result varchar(max)
	-- number of words or block
	declare @blockcounter int = 0
	while @blockcounter < @blocklen
	begin
		-- number of character per sentence
		declare @wordlen int = (SELECT FLOOR(RAND()*(10-3+1))+3)
		declare @word varchar(max) = ''
		declare @wordcounter int = 0
		while @wordcounter < @wordlen
		begin
			-- select one finger from finger proficiency history
			declare @fingerid int = (select dbo.getOneRandomFingerIdFromProficiencyHistory(@userid,@MaximumProficieny,@days))
			declare @character varchar(2) = ''
			-- generate character 
			if @MinimumNumberofMistakes > 0
				select @character = dbo.getRandomCharacterFromMistakeHistory(@fingerid, @userid, @days, @MinimumNumberofMistakes)
			-- if character is null then get random number
			if isnull(@character,'') = ''
				select @character = dbo.getRandomCharacter(@fingerid)
			-- concat characters
			set @word = CONCAT(@word,@character)
			set @wordcounter += 1
		end
		-- concat words
		set @result = CONCAT(@result,@word,' ')
		set @blockcounter += 1
	end
	print @result
end
go

/*
Procedure for calclating proficiency score and number of mistakes each character made,
and insert operation for both
Params: right - list of characters that type correctly no space in between
		wrong - list of character that type incorrectly no space in between
Assumption: right, wrong input characters exist in table
Returns: None
*/
create or alter procedure addProficiencyAndMistakes (@userid int,@right varchar(255),@wrong varchar(255))
WITH RECOMPILE
as begin
	SET NOCOUNT ON; 
	-- removing any whitespace
	set @right = (select REPLACE(@right, ' ', ''))
	set @wrong = (select REPLACE(@wrong, ' ', ''))
	-- verify input
	if (select count(*) from TYPING_USER where user_id = @userid) = 0
		begin
			print 'User does not exist'
			return
		end
	if @right ='' or @wrong =''
		begin
			print 'invalid input'
			return
		end
	/*
	Accuracy calculation
	right/total

	*/
	-- proficiency of each individual finger
	insert into FINGER_PROFICIENCY_HISTORY(user_id,finger_id,proficiency)
	select @userid, tsub.tfg, isnull(rsub.r,0)/tsub.t from
	-- word count of correctly typed
		(select finger_id as rfg, cast(sum(wordcount) as decimal(5,2)) r from dbo.characterCountHardWay(@right) inner join MAPPING on character = word group by finger_id)rsub
	right join
	-- word count of correctly and incorrectly typed
		(select finger_id as tfg, cast(sum(wordcount)as decimal(5,2)) t from dbo.characterCountHardWay(@right+@wrong) inner join MAPPING on character = word group by finger_id)tsub
	on tsub.tfg = rsub.rfg
	-- number of mistakes per character
	insert into MISTAKE_HISTORY(user_id,mapping_id,number)
	select @userid,mapping_id, wordcount from dbo.characterCountHardWay(@wrong)
	inner join MAPPING on character = word

end
go
-------------------TEST-----------------
print 'Testing:'
exec GENERATE_TYPING 'left-hand', 5
exec GENERATE_TYPING 'both-hand', 5
exec GENERATE_TYPING 'right-hand', 5
exec GENERATE_TYPING 'right-index,left-index', 5
exec GENERATE_TYPING 'dfgsdfg,dsfg,left-index,both-hand', 1
exec GENERATE_TYPING 'right-hand', 0
print '---------------------'
print 'Adding user:'
insert into TYPING_USER(name) values('testuser')
print '---------------------'
print 'Before adding value to proficiency table:'
exec GENERATE_TYPING_MODIFIER 1,0.7,2,2,7
print '---------------------'
print 'Testing Insert Operation:'
-- Takes userid, corretly typed, and wrongly typed string
--exec addProficiencyAndMistakes 1,'asdfesadfsag','fdgg'
exec addProficiencyAndMistakes 1,'ur4nv^7b6gt&5nb$y44vtn%t&&gu','74h6tt4h'
exec addProficiencyAndMistakes 1,'asdfesadfsag','asdfrgaaf'
exec addProficiencyAndMistakes 1,'asdfesadfsag','oluh'
print 'complete'
print '---------------------'
print 'These are the result after adding the values to proficiency and mistake table. The output will contain character from the incorrectly typed'
print 'The system will also account for when the number of mistake input is too high. It will getRandomCharacter when it getRandomCharacterFromMistake output a null value'
print 'Other improvment to this procedure may include changing the time interval from days to hour or even minutes, so the user can optimize for the best result'
print '---------------------'
exec GENERATE_TYPING_MODIFIER 1,0.7,1,2,7
exec GENERATE_TYPING_MODIFIER 1,0.7,2,2,7
exec GENERATE_TYPING_MODIFIER 1,0.7,3,2,7
exec GENERATE_TYPING_MODIFIER 1,0.7,4,2,7
print '---------------------'
exec GENERATE_TYPING_MODIFIER 1,0,0,0,0
go


------------------Extra Credit--------------
/*
Data partitioning can be done Mistake History, and Finger Proficiency History. Actually, this process will be very important if this database will be use in production.
Since everytime the user complete a typing testing it will record information relating to finger accuracy, and number of mistake of each character. 
The result of one typing test would generate multiple rows of data.

Depending on the number of user, it might be a good idea to partition the table by either month or year.
Since the user base for typing leaner is relatively small, partition by year might be a good idea.
To partition 
*/
--create filegroup
alter database PPEL_TEST_DATABASE
add filegroup y20fg;
go
alter database PPEL_TEST_DATABASE
add filegroup y21fg;
go

--partition fuction
create partition function DateRangePF (date)
as range right for values ('1/1/2021');
--partition scheme
create partition scheme DateRangePS
as partition DateRangePF
to (y20fg,y21fg);
go

/* Attach this scheme when create the table
*/

-- add new filegroup
alter database PPEL_TEST_DATABASE
add filegroup y22fg;

ALTER PARTITION SCHEME DateRangePS  
NEXT USED y22fg;
go
--With an empty filegroup, we can use this function
alter partition function DateRangePF()
split range ('1/1/2022');
go


--------------------------- Drop Database---------------
use master
go

drop database PPEL_TEST_DATABASE
go

