INTRODUCTION
============

copy_ldap2db is intended to synchronise portions of an LDAP directory to a local PostgreSQL dababase.

I use it to synchronise the field departmentNumber in a table named ldap_logins. This way, it's easier to make reports on the number of tickets processed grouped by departmentNumber.

SETUP
=====

In SQL, create the table like this:

    CREATE TABLE ldap_logins (
        username character varying(100),
        department character varying(100)
    );

and grant the appropriate rights to INSERT / UPDATE to a new user.

Install the required Perl modules.

Copy copy_ldap2db.ini.sample to copy_ldap2db.ini and modify the configuration.
