-- HW4 --
--using string_split, ignore empty space
--insert all words to table 
--Table need to have id column, and word value MUST be in asc order
--iterate, and update @count base on curr, prev word
--if curr = prev, get previous @count and plus 1 else update count to 1
create or alter function FindWordCount (@str nvarchar(max))
returns @wordCount table(
	id int identity(1,1),
	word nvarchar(max),
	count int
)
as begin
	--hold prev, curr word
	declare @curr nvarchar(max) = ''
	declare @prev nvarchar(max) = ''
	--temporary hold count value
	declare @temp int
	--split string and insert to table
	insert into @wordCount(word) select value from STRING_SPLIT(@str,' ') where value!=' ' order by value
	--total rows
	declare @lenght int = (select count(*) from @wordCount)
	declare @counter int = 1
	while @counter <= @lenght 
	begin
		set @curr = (select word from @wordCount where id= @counter)
		set @temp = (select count from @wordCount where id = @counter-1)
		if (@curr = @prev)
			update @wordCount set count = ISNULL(@temp,1) +1 where id = @counter
		else
			update @wordCount set count = 1 where id = @counter
		set @prev = @curr
		set @counter = @counter + 1
	end
	return
end
go

--test cases
declare @str_test1 nvarchar(max) = 'The star will never be the planet or the moon'
declare @str_test2 nvarchar(max) = 'the       the dog'
declare @str_test3 nvarchar(max) = ''

select * from dbo.FindWordCount(@str_test1)
select * from dbo.FindWordCount(@str_test2)
select * from dbo.FindWordCount(@str_test3)

drop function dbo.FindWordCount
go