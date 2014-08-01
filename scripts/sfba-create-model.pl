#
# Create a model and gapfilled-model from a genome object.
#

use strict;
use Data::Dumper;
use Getopt::Long::Descriptive;
use Bio::KBase::SimpleFBA::Environment;
use GenomeTypeObject;

my($opt, $usage) = describe_options("%c %o genome-object initial-model gapfilled-model",
				    ["media=s" => 'Media name'],
				    ["verbose|v" => "Show verbose output from lower-level commands"],
				    ["help|h" => "Show this help message"],
				    [],
				    ["Given a genome object, create an initial and a gapfilled model and write them to the given files."]);

print($usage->text), exit if $opt->help;
print($usage->text), exit 1 if @ARGV != 3;

my $genome_in = shift;
my $initial_model = shift;
my $gapfilled_model = shift;

-f $genome_in or die "Genome file '$genome_in' does not exist\n";

my $genome = GenomeTypeObject->create_from_file($genome_in);

print STDERR "Loading genome $genome->{scientific_name} with id $genome->{id}\n";

my $env = Bio::KBase::SimpleFBA::Environment->new(verbose => ($opt->verbose ? 1 : 0));
$env->set_random_workspace();

my($ok, $out, $err) = $env->run("fba-loadgenome", $genome_in, "--fromfile", "-w", $env->ws);

if (!$ok)
{
    die "Error loading genome:\n$err\n";
}

my $load_keys = $env->parse_output($out);
my $loaded = $load_keys->{"ObjectName"};
print "Loaded genome $loaded\n";
print "$out\n" if $opt->verbose;

my($ok, $out, $err) = $env->run("fba-buildfbamodel",
				$genome->{id},
				"--genomews", $env->ws,
				"--workspace", $env->ws);

if (!$ok)
{
    die "Error building model:\n$err\n";
}

my $build_keys = $env->parse_output($out);
my $model_id = $build_keys->{ObjectName};
print "Model created: $model_id\n";

print "$out\n" if $opt->verbose;

my @media = ();
@media = ("--media", $opt->media,
	  "--mediws", Bio::KBase::SimpleFBA::Constants::media_workspace) if $opt->media;

my($ok, $out, $err) = $env->run("fba-gapfill",
				$model_id,
				"--intsol",
				@media,
				"--sourcemdlws", $env->ws,
				"--workspace", $env->ws);
if (!$ok)
{
    die "Error building model:\n$err\n";
}

my $gapfill_keys = $env->parse_output($out);
my $gapfill_id = $build_keys->{ObjectName};
print "Gapfilled model created: $gapfill_id\n";

print "$out\n" if $opt->verbose;



