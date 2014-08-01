#
# List available media.
#

use strict;
use Data::Dumper;
use Getopt::Long::Descriptive;
use Bio::KBase::SimpleFBA::Environment;
use Bio::KBase::SimpleFBA::Constants;
use GenomeTypeObject;

my($opt, $usage) = describe_options("%c %o",
				    ["match|m=s" => "Show media matching this string"],
				    ["help|h" => "Show this help message"],
				    ["verbose|v" => "Show verbose output from lower-level commands"],
				    [],
				    ["List the available media for use with modeling tools."]);

print($usage->text), exit if $opt->help;
print($usage->text), exit 1 if @ARGV != 0;

my $env = Bio::KBase::SimpleFBA::Environment->new(verbose => ($opt->verbose ? 1 : 0));

my($ok, $out, $err) = $env->run("ws-listobj",
				"-t", "KBaseBiochem.Media",
				"-w", Bio::KBase::SimpleFBA::Constants::media_workspace);

if (!$ok)
{
    die "Error listing media:\n$err\n";
}

my $re;
if ($opt->match)
{
    my $v = $opt->match;
    $re = qr/$v/;
}
for my $l (split(/\n/, $out))
{
    if ($l =~ /^\s+(\d+)\s+(\S+)/)
    {
	my $str = $2;
	if ($re)
	{
	    if ($2 =~ $re)
	    {
		print "$str\n";
	    }
	}
	else
	{
	    print "$str\n";
	}
    }
}
	   

