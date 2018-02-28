create user repl@'%' identified by 'repl';
create user repl@'localhost' identified by 'repl';
grant replication slave on *.* to repl@'%' identified by 'repl';
grant replication slave on *.* to repl@'localhost' identified by 'repl';

create user skysql@'%' identified by 'skysql';
create user skysql@'localhost' identified by 'skysql';
GRANT ALL PRIVILEGES ON *.* TO skysql@'%' WITH GRANT OPTION;
GRANT ALL PRIVILEGES ON *.* TO skysql@'localhost' WITH GRANT OPTION;

create user maxuser@'%' identified by 'maxpwd';
create user maxuser@'localhost' identified by 'maxpwd';
GRANT ALL PRIVILEGES ON *.* TO maxuser@'%' WITH GRANT OPTION;
GRANT ALL PRIVILEGES ON *.* TO maxuser@'localhost' WITH GRANT OPTION;

create user maxskysql@'%' identified by 'skysql';
create user maxskysql@'localhost' identified by 'skysql';
GRANT ALL PRIVILEGES ON *.* TO maxskysql@'%' WITH GRANT OPTION;
GRANT ALL PRIVILEGES ON *.* TO maxskysql@'localhost' WITH GRANT OPTION;

FLUSH PRIVILEGES;
