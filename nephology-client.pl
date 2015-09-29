#!/usr/bin/perl

use strict;
use LWP;
use Getopt::Long;
use JSON;
use Try::Tiny;
use Data::Dumper;
use File::Temp;

my $debug;
my $version = 3;
my $neph_server = undef;
my $mac_addr = undef;
my $work_to_do = 1;
my $nephology_commands = undef;

# Get command line options
GetOptions(
    'server|s=s' => \$neph_server,
    'mac|m=s' => \$mac_addr,
    'debug' => \$debug,
    );

if (!defined($neph_server)) {
    print "Server required\n";
    exit 1;
}

print "Nephology Client version $version Startup\n\n";

my $browser = LWP::UserAgent->new;
$browser->agent('NephologyCient/' . $version . ' (libwww-perl-' . $LWP::VERSION . ')');

while ($work_to_do == 1) {
    $nephology_commands = {};
    print "Getting worklist from $neph_server for $mac_addr\n";
    # Grab the worklist from the Nepology Server
    my $response = $browser->get(
	"http://" . $neph_server . "/install/" . $mac_addr,
	'X-Nephology-Client-Version' => $version,
	);

    print "RESPONSE CODE: ".$response->code."\n" if $debug;
    print "CONTENT\n ".$response->decoded_content."\n" if $debug;

    if(! $response->is_success) {
        if ($response->code  >= '500') {&wait(60,"Response was ".$response->code.". Nephology-server is broken") && next };
        &wait(15,"Node not found, going to create a stub.\n");
        print("done.\n");
        print("Sending...");
        my $response_install = $browser->post(
                        "http://" . $neph_server . "/install/" . $mac_addr,
                        'X-Nephology-Client-Version' => $version,
                        Content => '{}');
        if ($response_install->is_success) {
            &wait(15,"Done!\nNode created, will try installation again in 15sec\n");
               next;
        } else {
            &wait(30,"Nope.\nNo successful response, waiting for 5min before trying again\n");
            next;
        } # if ohai reponse
    } # if not success

    print("Got a response, processing...\n");
    try {
        $nephology_commands = JSON->new->utf8->decode($response->decoded_content);
    } catch {
        &wait(30,"Resonse wasn't valid JSON, waiting for 5min before trying again\n");
        next;
    };

    print(Dumper($nephology_commands)) if $debug;

    if ( $nephology_commands->{'version_required'} > $version ) {
        print("This client is out of date for the Nephology server\n");
        print("Rebooting to fetch a fresh client.\n");
        unlink("incomplete");
        system("reboot -f");
        exit 0;
    }

    # if we have nothing to do , wait around for something to do
    unless (scalar(@{$nephology_commands->{'runlist'}})) {
        &wait(30,"Runlist is empty");
        next;
    }

    # when we have rules, run them + make sure all of the pass. if not we will
    # continue the process unltil we finish
    my $success_rule = 0;
    foreach my $reqhash (@{$nephology_commands->{'runlist'}}) {
        my $tmp = File::Temp->new();
        my $tmp_fn = $tmp->filename;
        print("Got rule [$reqhash->{'id'}] (".substr($reqhash->{'description'},0,50)."), grabbing to $tmp_fn.\n");
        my $data = $browser->get(
                        "http://" . $neph_server . "/install/" . $mac_addr . "/" . $reqhash->{'id'},
                        'X-Nephology-Client-Version' => $version,
                        );
        if (! $data->is_success) { failure("Could not get data for $reqhash->{'rule_id'} $tmp_fn"); }
        print $tmp $data->decoded_content;
        system("chmod 755 $tmp_fn ; sudo $tmp_fn");
        my $retcode = $?;
        if ($retcode > 0) {failure("Bad exec for rule [$reqhash->{'rule_id'}]: " . $?);}
        $success_rule++;
    }
    print("Passed $success_rule out of ".scalar(@{$nephology_commands->{'runlist'}})." rules\n");
    if ($success_rule >= scalar(@{$nephology_commands->{'runlist'}})) {
        print("All Done!\n");
        $work_to_do = 0;
    } else {
        &wait(20,"End of run.i Waiting 20 seconds before continuing.\n");
    }
}

exit 0;

sub wait {
    my $time = shift || "30"; # default to 30 seconds of wait
    my $reason = shift || "Just waiting around for fun";
    print("Waiting $time seconds. $reason\n");
    sleep $time;
}

sub failure {
    my $message = shift;
    if ( -e "/dev/ipmi0" ) {
        system("sudo ipmitool chassis identify force");
    }
    print("CLIENT FAILURE: " . $message . "\n");
    while (1) { sleep(10) };
}
