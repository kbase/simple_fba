#
# Create a model and gapfilled-model from a genome object.
#

use strict;
use Getopt::Long::Descriptive;


my($opt, $usage) = describe_options("%c %o genome-object initial-model gapfilled-model",
				    ["media=s" => 'Media name'],
				    ["help|h" => "Show this help message"],
				    [],
				    ["Given a genome object, create an initial and a gapfilled model and write them to the given files."]);

print($usage->text), exit if $opt->help;
print($usage->text), exit 1 if @ARGV != 3;

my $genome_in = shift;
my $initial_model = shift;
my $gapfilled_model = shift;
