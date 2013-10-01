#!/usr/bin/perl -w

use strict;
use Net::LDAP;
use Net::LDAP::Util qw(ldap_error_text);
use DBI;
use Config::IniFiles;
use File::Basename;

my $cfg = Config::IniFiles->new( -file => dirname(__FILE__).'/copy_ldap2db.ini' );

my $DSN         = $cfg->val( 'DB', 'DSN' );
my $DB_USERNAME = $cfg->val( 'DB', 'USERNAME' );
my $DB_PASSWORD = $cfg->val( 'DB', 'PASSWORD' );

my $LDAP_HOSTNAME = $cfg->val( 'LDAP', 'HOSTNAME' );
my $LDAP_BIND_DN  = $cfg->val( 'LDAP', 'BIND_DN' );
my $LDAP_PASSWORD = $cfg->val( 'LDAP', 'PASSWORD' );
my $LDAP_BASE     = $cfg->val( 'LDAP', 'BASE' );

my $ldap = Net::LDAP->new($LDAP_HOSTNAME) or die "$@";
my $result = $ldap->bind( $LDAP_BIND_DN, password => $LDAP_PASSWORD );
if ( $result->code ) {
    die "An error occurred binding to the LDAP server\n"
      . ldap_error_text( $result->code ) . "\n";
}
my $mesg = $ldap->search(
    base   => $LDAP_BASE,
    filter => "(objectClass=inetOrgPerson)",
    attrs  => [ 'cn', 'departmentNumber' ]
);

my $sql =
"SELECT COALESCE(department, '') AS department FROM ldap_logins WHERE username = ?";
my $dbh =
  DBI->connect( $DSN, $DB_USERNAME, $DB_PASSWORD, { 'RaiseError' => 1 } );
my $sth = $dbh->prepare($sql);

foreach my $entry ( $mesg->entries ) {
    my $cn         = $entry->get_value('cn');
    my $department = '';
    if ( $entry->exists('departmentNumber') ) {
        $department = $entry->get_value('departmentNumber');
    }
    $sth->execute($cn);
    my $ok = 0;
    while ( my $ref = $sth->fetchrow_hashref() ) {
        $ok = 1;
        if ( $ref->{'department'} ne $department ) {
            $ok = 2;
        }
    }
    if ( $ok == 0 ) {
        # New
        $dbh->do(
            'INSERT INTO ldap_logins (username, department) VALUES (?, ?)',
            undef, $cn, $department );
    }
    elsif ( $ok == 2 ) {
        # Update
        $dbh->do( 'UPDATE ldap_logins SET department = ? WHERE username = ?',
            undef, $department, $cn );
    }
}

