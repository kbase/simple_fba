#
# Run a model
#

use strict;
use Data::Dumper;
use Getopt::Long::Descriptive;
use Bio::KBase::SimpleFBA::Environment;
use GenomeTypeObject;

my($opt, $usage) = describe_options("%c %o model model-output",
				    ["media=s" => 'Media name'],
				    ["verbose|v" => "Show verbose output from lower-level commands"],
				    ["help|h" => "Show this help message"],
				    [],
				    ["Given a model, run the FBA."]);

print($usage->text), exit if $opt->help;
print($usage->text), exit 1 if @ARGV != 2;

my $model_in = shift;
my $results_out = shift;

-f $model_in or die "Model file '$model_in' does not exist\n";

open(OUT, ">", $results_out) or die "Cannot write output file $results_out: $!";

my $env = Bio::KBase::SimpleFBA::Environment->new(verbose => ($opt->verbose ? 1 : 0));
$env->set_random_workspace();

my($ok, $out, $err) = $env->run("ws-load",
				"KBaseFBA.FBAModel", "model", $model_in,
				"-w", $env->ws);

$ok or die "Error loading model into workspace:\n$err\n";
print "$out\n" if $opt->verbose;
my $load_keys = $env->parse_output($out);

my $model_id = $load_keys->{ObjectName};

my @media = ();
@media = ("--media", $opt->media,
	  "--mediaws", Bio::KBase::SimpleFBA::Constants::media_workspace) if $opt->media;

($ok, $out, $err) = $env->run("fba-runfba",
			      $model_id,
			      "--modelws", $env->ws,
			      @media,
			      "-w", $env->ws);

$ok or die "Error running FBA:\n$err\n";
print "$out\n" if $opt->verbose;
my $fba_keys = $env->parse_output($out);

my $fba_id = $fba_keys->{ObjectName};

($ok, $out, $err) = $env->run("ws-get", $fba_id, "-w", $env->ws, "-p");
$ok or die "Error running ws-get: \n$err\n";

print OUT $out;
close(OUT);

