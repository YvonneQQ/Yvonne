#!/bin/bash　　
HOSTNAME="127.0.0.1"
PORT="3306"
USERNAME="root"
PASSWORD="root"
DBNAME="db1"
TABLENAME="table1"

create_db_sql="create database IF NOT EXISTS ${DBNAME}"
mysql -h${HOSTNAME}  -P${PORT}  -u${USERNAME} -p${PASSWORD} -e "${create_db_sql}"

create_table_sql="use ${DBNAME}; create table IF NOT EXISTS ${TABLENAME} ( birthday varchar(20), last_name varchar(20), first_name varchar(20), id INT UNSIGNED AUTO_INCREMENT, PRIMARY KEY ( id ));"
mysql -h${HOSTNAME}  -P${PORT}  -u${USERNAME} -p${PASSWORD} ${DBNAME} -e "${create_table_sql}"

insert_sql="use ${DBNAME}; insert into ${TABLENAME}(birthday,last_name,first_name) values('2022/03/01','James','CJ')"
mysql -h${HOSTNAME}  -P${PORT}  -u${USERNAME} -p${PASSWORD} ${DBNAME} -e  "${insert_sql}"

select_sql="use ${DBNAME}; select * from ${TABLENAME}"
mysql -h${HOSTNAME}  -P${PORT}  -u${USERNAME} -p${PASSWORD} ${DBNAME} -e "${select_sql}" >> foo.txt
