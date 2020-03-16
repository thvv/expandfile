# expandfile test table.
drop table if exists testexpandfile;
create table testexpandfile(
 col1 varchar(255),
 col2 varchar(255),
 col3 varchar(255)
);

insert into testexpandfile values
('1','2','3'),
('aaa1','bbb2','ccc3');
