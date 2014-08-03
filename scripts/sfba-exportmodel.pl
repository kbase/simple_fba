#!/usr/bin/env perl
########################################################################
# Authors: Christopher Henry, Scott Devoid, Paul Frybarger
# Contact email: chenry@mcs.anl.gov
# Development location: Mathematics and Computer Science Division, Argonne National Lab
########################################################################
use strict;
use warnings;
use JSON::XS;
use Bio::KBase::workspace::ScriptHelpers qw(printObjectInfo get_ws_client workspace workspaceURL parseObjectMeta parseWorkspaceMeta printObjectMeta);
use Bio::KBase::fbaModelServices::ScriptHelpers qw(get_workspace_object fbaws get_fba_client runFBACommand universalFBAScriptCode );
#Defining globals describing behavior
my $primaryArgs = ["Model filename"];
my $translation = {};
#Defining usage and options
my $specs = [
    [ 'rxns|r', 'Print all reactions in model'],
    [ 'cpds|c', 'Print all compounds in model'],
    [ 'bio|b', 'Print all biomass compounds in model'],
];
my ($opt,$params) = universalFBAScriptCode($specs,"sfba-exportmodel",$primaryArgs,{});
if (!-e $opt->{"Model filename"}) {
	die "Cannot find model file ".$opt->{"Model filename"}."!";
}
open( my $fh, "<", $opt->{"Model filename"});
my $model;
{
    local $/;
    my $str = <$fh>;
    $model = decode_json $str;
}
close($fh);
if ($opt->{rxns}) {
	my $reactions = $model->{modelreactions};
	my $rxns = {};
	for (my $i=0; $i < @{$reactions}; $i++) {
		my $reaction = $reactions->[$i];
		if ($reaction->{reaction_ref} =~ /(rxn\d+)$/) {
			$rxns->{$1} = {};
		}
	}
	my $output = get_fba_client()->get_reactions({reactions => [keys(%{$rxns})]});
	for (my $i=0; $i < @{$output}; $i++) {
		$rxns->{$output->[$i]->{id}} = $output->[$i];
	}
	print "Reaction\tName\tEnzyme\tEquation\tDefinition\tDeltaG\tGPR\n";
	for (my $i=0; $i < @{$reactions}; $i++) {
		my $reaction = $reactions->[$i];
		if ($reaction->{reaction_ref} =~ /(rxn\d+)$/) {
			my $id = $1;
			my $gpr = "none";
			my $plist = [];
			for (my $j=0; $j < @{$reaction->{modelReactionProteins}}; $j++) {
				my $p = $reaction->{modelReactionProteins}->[$j];
				my $slist = [];
				for (my $k=0; $k < @{$p->{modelReactionProteinSubunits}}; $k++) {
					my $s = $p->{modelReactionProteinSubunits}->[$k];
					my $flist = [];
					for (my $m=0; $m < @{$s->{feature_refs}}; $m++) {
						if ($s->{feature_refs}->[$m] =~ /([^\/]+)$/) {
							push(@{$flist},$1);
						}
					}
					if (@{$flist} > 0) {
						push(@{$slist},"(".join(" or ",@{$flist}).")");
					}
				}
				if (@{$slist} > 0) {
					push(@{$plist},"(".join(" and ",@{$slist}).")");
				}
			}
			if (@{$plist} > 0) {
				$gpr = "(".join(" or ",@{$plist}).")";
			}
			my $rxn = {};
			if (defined($rxns->{$id})) {
				$rxn = $rxns->{$id};
			}
			$rxn->{id} = $id;
			$rxn->{gpr} = $gpr;
			print_file_line(
				["id","name","enzymes","equation","definition","deltaG","gpr"],
				{enzymes => 1},
				$rxn
			);
		}
	}
} elsif ($opt->{cpds}) {
	my $compounds = $model->{modelcompounds};
	my $cpds = {};
	for (my $i=0; $i < @{$compounds}; $i++) {
		my $compound = $compounds->[$i];
		if ($compound->{compound_ref} =~ /(cpd\d+)$/) {
			$cpds->{$1} = {};
		}
	}
	my $output = get_fba_client()->get_compounds({compounds => [keys(%{$cpds})]});
	for (my $i=0; $i < @{$output}; $i++) {
		$cpds->{$output->[$i]->{id}} = $output->[$i];
	}
	print "Compound\tName\tFormula\tCharge\tDeltaG\tCompartment\n";
	for (my $i=0; $i < @{$compounds}; $i++) {
		my $compound = $compounds->[$i];
		if ($compound->{compound_ref} =~ /(cpd\d+)$/) {
			my $id = $1;
			if ($compound->{modelcompartment_ref} =~ /([a-zA-Z]\d+)$/) {
				my $cmp = $1;
				my $cpd = {};
				if (defined($cpds->{$id})) {
					$cpd = $cpds->{$id};
				}
				$cpd->{id} = $id;
				$cpd->{cmp} = $cmp;
				print_file_line(
					["id","name","formula","charge","deltaG","cmp"],
					{},
					$cpd
				);
			}
		}
	}
} elsif ($opt->{bio}) {
	my $bios = $model->{biomasses};
	my $cpds = {};
	for (my $i=0; $i < @{$bios}; $i++) {
		my $bio = $bios->[$i];
		my $biocpds = $bio->{biomasscompounds};
		for (my $j=0; $j < @{$biocpds}; $j++) {
			if ($biocpds->[$j]->{modelcompound_ref} =~ /(cpd\d+)_/) {
				$cpds->{$1} = {};
			}
		}
	}
	my $output = get_fba_client()->get_compounds({compounds => [keys(%{$cpds})]});
	for (my $i=0; $i < @{$output}; $i++) {
		$cpds->{$output->[$i]->{id}} = $output->[$i];
	}
	print "Compound\tName\tFormula\tCharge\tDeltaG\tBiomass\tBiomass coefficient\n";
	for (my $i=0; $i < @{$bios}; $i++) {
		my $bio = $bios->[$i];
		my $biocpds = $bio->{biomasscompounds};
		for (my $j=0; $j < @{$biocpds}; $j++) {
			if ($biocpds->[$j]->{modelcompound_ref} =~ /(cpd\d+)_/) {
				my $id = $1;
				my $cpd = {};
				if (defined($cpds->{$id})) {
					$cpd = $cpds->{$id};
				}
				$cpd->{id} = $id;
				$cpd->{biomass} = $bio->{id};
				$cpd->{coefficient} = $biocpds->[$j]->{coefficient};
				print_file_line(
					["id","name","formula","charge","deltaG","biomass","coefficient"],
					{},
					$cpd
				);
			}
		}
	}
}

sub print_file_line {
	my $headings = shift;
	my $arrayheadings = shift;
	my $data = shift;
	for (my $i=0; $i < @{$headings}; $i++) {
		if ($i > 0) {
			print "\t";
		}
		if (defined($arrayheadings->{$headings->[$i]})) {
			if (defined($data->{$headings->[$i]}->[0])) {
				print $data->{$headings->[$i]}->[0];
			}
		} elsif (defined($data->{$headings->[$i]})) {
			print $data->{$headings->[$i]};
		}
	}
	print "\n";
}