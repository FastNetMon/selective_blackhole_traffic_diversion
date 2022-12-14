#!/usr/bin/perl
 
use strict;
use warnings;
 
use JSON;
 
use Data::Dumper;

my $community_host_to_blackhole = '65000:777';
my $community_host_to_scrubbing = '65000:888';
 
# Write some debug to /tmp
 
open my $fl, ">>", "/tmp/fastnetmon_notify_script.log" or die "Could not open file for writing";
 
# This script executed from FastNetMon this way: ban 11.22.33.44
 
if (scalar @ARGV != 2) {
    print {$fl} "Please specify all arguments. Got only: @ARGV\n";
    die "Please specify all arguments\n";
}
 
my ($action, $ip_address) = @ARGV;
# action could be: ban, unban, partial_block
 
# Read data from stdin
my $input_attack_details = join '', <STDIN>;
 
# try to decode this data to json
my $attack_details = eval{  decode_json($input_attack_details); };
 
# report error
 
if ($@) {
    print {$fl} "JSON decode failed: $input_attack_details\n";
 
    die "JSON decode failed\n";
}
 
print {$fl} "Received notification about $ip_address with action $action\n";
 
print {$fl} Dumper($attack_details);

my $host_group = $attack_details->{attack_details}->{'host_group'};

my $command = '';

if ($host_group eq 'host_to_scrubbing') {
    my $host_network = $attack_details->{attack_details}->{host_network};

    if ($action eq 'ban') {
        $command = "gobgp global rib add -a ipv4 $host_network community $community_host_to_scrubbing";
    } elsif ($action eq 'unban') {
        $command = "gobgp global rib del -a ipv4 $host_network";
    }
} elsif ($host_group eq 'host_to_blackhole') {
    if ($action eq 'ban') {
        $command = "gobgp global rib add -a ipv4 $attack_details->{ip}/32 community $community_host_to_blackhole";
    } elsif ($action eq 'unban') {
        $command = "gobgp global rib del -a ipv4 $attack_details->{ip}/32";
    }
} else {
    print {$fl} "Unknown host group $host_group. Do not apply any actions\n";
}
 
if ($command ne '') {
    print {$fl} "Will execute command $command for group $host_group\n";
    my $res = system($command);

    if ($res != 0) {
        print {$fl} "Command failed with code $res\n";
    } else {
        print {$fl} "Command executed correctly\n";
    }

}

close $fl;
 
exit 0;
