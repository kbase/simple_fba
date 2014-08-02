package Bio::KBase::SimpleFBA::Environment;

use Digest::MD5 'md5_hex';
use Bio::KBase::SimpleFBA::Constants;
use Data::Dumper;
use strict;
use IPC::Run;

use base 'Class::Accessor';
__PACKAGE__->mk_accessors(qw(ws opts));

sub new
{
    my($class, %opts ) = @_;

    my $self = {
	token => Bio::KBase::SimpleFBA::Constants::auth_token,
	opts => { %opts },
    };

    bless $self, $class;
    return $self;
}

sub set_random_workspace
{
    my($self) = @_;
    my $n = rand(10000);
    my $key = md5_hex($n . $$ . time);

    
    if ($ENV{KB_AUTH_USER_ID})
    {
	$key = "sfba_$ENV{KB_AUTH_USER_ID}_$key";
    }
    else
    {
	$key = "sfba_$key";
    }
    
    $self->{ws} = $key;

    my($ok, $out, $err) = $self->run("ws-createws", $key);

    $ok or die "Error creating workspace: $err\n";

    if ($out =~ /Workspace\s*created.*id:\s*(\d+)/)
    {
	# print STDERR "created ws id $1\n";
    }
}

sub run
{
    my($self, @cmd) = @_;

    my @cmds;
    my($out, $err);

    #
    # Important: must set path in parent since it is the parent that
    # finds the script to run.
    #
    local $ENV{PATH} = "/disks/kb/deployment/bin:/disks/kb/runtime/bin:$ENV{PATH}";

    push(@cmds, \@cmd);
    push(@cmds, init => sub {
	$ENV{KB_RUNNING_IN_IRIS} = 1;
	$ENV{KB_AUTH_TOKEN} = $self->{token};
	$ENV{PERL5LIB} = "/disks/kb/deployment/lib:/disks/kb/deployment/lib/perl5";
	# print "** PATH='$ENV{PATH}'\n";
    });
    push(@cmds, '>', \$out);
    push(@cmds, '2>', \$err);

    print "Run: @cmd\n" if $self->opts->{verbose};
    my $ok = IPC::Run::run(@cmds);
    return($ok, $out, $err);
}

#
# Parse out the colon-sep key value output from FBA commands.
#

sub parse_output
{
    my($self, $str) = @_;

    my $keys = {};
    for my $l (split(/\n/, $str))
    {
	if ($l =~ /^([^:]+):(.*)$/)
	{
	    my $k = $1;
	    my $v = $2;
	    $k =~ s/\s+//g;
	    $v =~ s/^\s+//;
	    $v =~ s/\s+$//;
	    $keys->{$k} = $v;
	}
    }
    return $keys;
}


1;

