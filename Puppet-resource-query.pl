#!/usr/bin/perl
use strict;
use warnings;

my $DEBUG = 0;
my %puppetcfg;
my %resource; # hash of resources, key=namevar, value=type
my %resourcebytype; # HoH by resource type
my $q_type; # queried resource type
my $q_res; # queried resource name
my $searchmode = undef;

if ($ARGV[1]) { 
  # two args -  first is type, second is resource
  $q_type = lc($ARGV[0]);
  $q_res = $ARGV[1];
}
else {
  # have we got just a resource name?
  $q_res = $ARGV[0];
}

if ($q_type) { 
  if ($q_type eq '--search') {
  # search mode, case insenstitive substring search
   $searchmode = 1;
   $DEBUG && print "Searchmode set for $q_res\n";
   unless ($q_res =~ m/\w?/) { die "missing resource name to search for\n\n"; }
  } 
}
unless ($q_res) { die "Usage: $0 [resource type] resource_to_query\n\n"; }

# sensible defaults
$ENV{'PATH'} = '/opt/puppetlabs/puppet/bin:/usr/local/bin:/usr/bin:/bin:/usr/sbin';

# locate the cache directory

open CONFIG, "puppet config print|" or die "Error retrieving puppet config\n\n";
while (<CONFIG>) {
  chomp;
  if ($_ =~ m/^([\w]+) = (.*)$/) {
        $puppetcfg{$1} = $2;
      }
}
close CONFIG;
if ($puppetcfg{'statefile'}) {
    $DEBUG && print "using $puppetcfg{'statefile'}\n";
  }
  else {
    die "Failed to resolve puppet statefile location\n";
  }

#Load the state file
open STATE, "<$puppetcfg{'statefile'}" or die "Failed to read $puppetcfg{'statefile'}\n\n";
while (<STATE>) {
    chomp;
    if ($_ =~ m/^([A-Z].\w+)\[(.*)\]:$/) {
      my $restype = lc($1);
      my $resname = $2;
      $resourcebytype{$restype}{$resname}++;
      $resource{$resname} = $restype;
      if ($searchmode) {
          if ($resname =~ m/$q_res/i) {
              print "Found $restype $resname\n";
          }
      }
    }
  }
close STATE;

$searchmode && exit(0);

# only check supplied type if one was passed in
if ($q_type) {
  if ($resourcebytype{$q_type}{$q_res}) {
      print "${q_type} ${q_res} managed by puppet\n";
      exit(0);
    }
  else { print "${q_type} ${q_res} not managed by puppet\n"; exit(1); }
}

# no type supplied, search all
else {
  if ($resource{$q_res}) {
      print "$resource{$q_res} ${q_res} managed by puppet\n"; 
      exit(0);
    }
  else { print "${q_res} not managed by puppet\n"; exit(1); }
}



