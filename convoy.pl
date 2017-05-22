#!/usr/bin/perl
$VERSION=0.1;

use FindBin qw($Bin);
use lib ("$Bin/../lib", "$Bin/../lib/ext");

use Convoy;
use Convoy::Context;
use Data::Dumper; $Data::Dumper::Indent = 1; # for debugging only
use Getopt::Long;

use strict;
use warnings;

# === Globals ===============================================================
my $options = {};

# === Main Body of Code =====================================================
# --- load up all the options ---
$options = configure();

# --- pick an option, any option ---
SWITCH: {
	# --- generate the manual pages ---
	$options->{makeman} && do { makeman(); exit 0; };

	# --- dump Convoy::Context's config ---
	$options->{dumpconfig} && do { dumpconfig(); exit 0; };

	# --- invoke Convoy plugin module
	$options->{context} && do { invoke(); }
};

exit 0;

# === Configuration =========================================================
sub configure {
	usage() unless @ARGV; # force help message if no arguments

	# --- parse the command line options ---
	$options = {};
	my @envs    = ();
	Getopt::Long::Configure('bundling');
	GetOptions($options,
		'help|?+', 'man+',          # help and man page
		'quiet|q+', 'verbose|v+',   # do things quietly/loudly

		'overlay|O=s',              # overlay file
		'env|e=s%',                 # set environment variables
		'dumpconfig|D+',            # dump Convoy::Context's config

		'makeman|m+',               # generate manual pages
		'test+',                    # test mode (for --makeman)
	);

	# --- show usage or man page ---
	$options->{help} && do { usage() };
	$options->{man} && do {
		exec 'perldoc '. (defined $ENV{OS} && $ENV{OS} =~ /^win/i ? '-T ' : '') . $0;
	};

	# --- set environment variables from --env ---
	while (my ($key, $value) = each(%{$options->{env}})) {
		$ENV{$key} = $value;
	}

	# --- set defaults ---
	$options->{quiet}   ||= 0;
	$options->{verbose} ||= 0;
	$options->{context} = shift @ARGV;

	return $options;
}

# === Make Manual Pages =====================================================
use Term::ANSIColor qw(:constants);
sub makeman {
	print "Running in test mode\n" if $options->{test} && ! $options->{quiet};

	# --- create directories ---
	mkdir "$Bin/../man";
	mkdir "$Bin/../man/cat1";
	mkdir "$Bin/../man/cat3";
	mkdir "$Bin/../man/man1";
	mkdir "$Bin/../man/man3";
	mkdir "$Bin/../man/html1";
	mkdir "$Bin/../man/html3";

	mkdir "$Bin/../man/ext";
	mkdir "$Bin/../man/ext/cat3";
	mkdir "$Bin/../man/ext/man3";
	mkdir "$Bin/../man/ext/html3";

	# --- generate manpages for programs ---
	print "Generating manpages for programs\n" unless $options->{quiet};
	chdir "$Bin/../bin";
	foreach my $file (split /\s+/, qx{grep -l '^=head1' *}) {
		printf("   %-60s", $file) unless $options->{quiet};

		# --- gen Unix manpage ---
		my $dest = "$Bin/../man/man1/$file.1.gz";
		if (! -e $dest || (stat $file)[9] > (stat $dest)[9]) {
			print GREEN . BOLD ."MAN  ". RESET unless $options->{quiet};
			system "pod2man $file | gzip > $dest" unless $options->{test};
		} else { print DARK ."man  ". RESET unless $options->{quiet}; }

		# --- gen HTML manpage ---
		$dest = "$Bin/../man/html1/$file.html";
		if (! -e $dest || (stat $file)[9] > (stat $dest)[9]) {
			print GREEN . BOLD ."HTML  ". RESET unless $options->{quiet};
			system "pod2html --htmlroot='.' $file > $dest" unless $options->{test};
		} else { print DARK ."html  ". RESET unless $options->{quiet}; }

		# --- gen text manpage ---
		$dest = "$Bin/../man/cat1/$file.1";
		if (! -e $dest || (stat $file)[9] > (stat $dest)[9]) {
			print GREEN . BOLD ."TEXT  ". RESET unless $options->{quiet};
			system "pod2text $file > $dest" unless $options->{test};
		} else { print DARK ."text  ". RESET unless $options->{quiet}; }

		print "\n";
	}

	# --- generate manpages for libraries ---
	foreach my $ext ('', 'ext/') {
		print "Generating manpages for libraries in 'lib/$ext\n" unless $options->{quiet};
		chdir "$Bin/../lib/$ext";
		foreach my $file (split /\s+/, qx{grep -l '^=head1' `find * -type f -name "*.pm" | grep -v ^ext`}) {
			my $pkg = $file; $pkg =~ s/\.pm$//; $pkg =~ s/\//::/g;
			printf("   %-60s", $pkg) unless $options->{quiet};

			# --- gen Unix manpage ---
			my $dest = "$Bin/../man/${ext}man3/$pkg.3.gz";
			if (! -e $dest || (stat $file)[9] > (stat $dest)[9]) {
				print GREEN . BOLD ."MAN  ". RESET unless $options->{quiet};
				system "pod2man $file | gzip > $dest" unless $options->{test};
			} else { print DARK ."man  ". RESET unless $options->{quiet}; }

			# --- gen HTML manpage ---
			$dest = "$Bin/../man/${ext}html3/$pkg.html";
			if (! -e $dest || (stat $file)[9] > (stat $dest)[9]) {
				print GREEN . BOLD ."HTML  ". RESET unless $options->{quiet};
				system "pod2html $file > $dest" unless $options->{test};
			} else { print DARK ."html  ". RESET unless $options->{quiet}; }

			# --- gen text manpage ---
			$dest = "$Bin/../man/${ext}cat3/$pkg.3";
			if (! -e $dest || (stat $file)[9] > (stat $dest)[9]) {
				print GREEN . BOLD ."TEXT  ". RESET unless $options->{quiet};
				system "pod2text $file > $dest" unless $options->{test};
			} else { print DARK ."text  ". RESET unless $options->{quiet}; }

			print "\n";
		}
	}

	# --- cleanup ---
	system "rm -f $Bin/../bin/pod2htm[di].tmp";
}

# === Dump Convoy Config ====================================================
sub dumpconfig { print _loadContext()->config->sourceReport }

# === port from invoke.pl ==============================================
sub invoke {
	# --- create convoy object ---
	my $convoy = new Convoy(
		Path    => $options->{context},
		Overlay => $options->{overlay},
	);

	# --- test for whitspace at the end of config settings ---
	my $config = $convoy->config->raw;
	my $warnings = '';
	foreach my $key (sort keys %$config) {
		$warnings .= "   $key : '$config->{$key}'\n"
			if $config->{$key} =~ /\s$/;
	}
	print STDERR "Warning: whitespace was detected at the end of some configuration settings\n\tPlease ensure this is intentional\n\n$warnings\n"
		if $warnings;

	# --- install ---
	$convoy->Install();
}

sub _loadContext {
	# --- create a context ---
	my $context = new Convoy::Context(
		Path    => $options->{context},
		Overlay => $options->{overlay},
	);

	# --- return the context ---
	return $context;
}

# === Usage and Error Message ===============================================
sub usage {
	my $error = shift;
	my $progname = ($0 =~ /([^\/]*)$/)[0] || $0;

	print STDERR qq[\nerror: $error\n] if $error;
	print STDERR qq{
usage: $progname [options] [CONTEXT]

   -?, --help     display this message;
       --man      display the manual page for $progname
   -q, --quiet    do stuff quietly
   -v, --verbose  do stuff loudly

   -m, --makeman  generate manual pages
       --test     only pretend

   -e, --env KEY=VALUE  set environment variables,
                           multiple --env parameters allowed
   -O, --overlay NAME   use NAME'd context overlay
   -D, --dumpconfig     display all values loaded from CONTEXT and exit

};
	exit 1;
}

=head1 NAME

convoy - Expedia's E3 deployment tool

=head1 SYNOPSIS

 convoy {-?|--man}
 convoy [-q|-v] [--env KEY=VALUE [...]] [--overlay OVERLAY] CONTEXT
 convoy --dumpconfig CONTEXT
 convoy [-q|-v] [--test] --makeman

=head1 DESCRIPTION

B<convoy> is the deployment tool for Expedia's next generation of code (E3).
This manual page is not just a description of how to use this tool, but rather a primer on convoy in General.

=head1 EXAMPLES

Deploying ConfigService to Functional Test Environment 5 (fnt05), Convoy v0.4 method:

   convoy //deployment/net/karmalab/fnt05/bus/platform/configService

Deploying ConfigService to Functional Test Environment 21 (fnt21), Convoy v0.5 method:

   convoy //deployment/net/karmalab/fnt/bus/platform/configService --overlay fnt/fnt21

Viewing Convoy's YAML data for Functional Test Environment 21 (fnt21):

   convoy //deployment/net/karmalab/fnt/bus/platform/configService --overlay fnt/fnt21 --dumpconfig

=head1 CONFIGURATION

Convoy uses a tree of YAML and Properties files for configuration.
The following is a sample snapshot of one of the trees in perforce:

  //deployment/net/karmalab/ (in perforce:1970)
  |-- domain.yml
  |-- deployment.settings.values
  |-- ENVNAME/
  |   |-- environment.yml
  |   |-- bus/
  |   |   |-- es/
  |   |   |   |-- adService/
  |   |   |   |   `-- deploymentunit.yml
  |   |   |   |   `-- deployment.settings.values
  |   |   |   `-- mapService/
  |   |   |       `-- deploymentunit.yml
  |   |   |   |   `-- deployment.settings.values
  |   |   `-- platform/
  |   |       |-- configService/
  |   |       |   `-- deploymentunit.yml
  |   |       `-- echoService/
  |   |           `-- deploymentunit.yml
  |   |-- e3/
  |   |   `-- es/
  |   |       `-- succ/
  |   |           `-- service/
  |   |               `-- deploymentunit.yml
  |   |-- platform/
  |   |   |-- configui/
  |   |   |   `-- deploymentunit.yml
  |   |   `-- deployment/
  |   |       `-- cda/
  |   |           `-- deploymentunit.yml
  |   `-- www/
  |       |-- connector/
  |       |   |-- deploymentunit.yml
  |       |   `-- deployment.settings.values
  |       `-- expediabase/
  |           |-- deploymentunit.yml
  |           `-- deployment.settings.values
  `-- overlay/
      `-- sbx/
          |-- sbx08.yml
          `-- sbx08.dsv

The current tree is available at stored in Perforce at I<perforce:1970 //deployment/>.
A live copy of this repository is also available at L<smb://blfilrtt01.karmalab.net/Deployment>

=head2 The YAML Files

Convoy uses a series of YAML files in a B<Context Path> for configuration.
A B<Context Path> is simply a file path to either a B<Deployment Unit> or B<Deployment Set>.

There are a number of standard keys used within the YAML files (see L</YAML Keys> later in this section),
but some keys are very specific to the plugin that the Deployment Unit uses.
For details on the plugin-specific keys, see the manual page for the plugin.

Note that some of the names of these files may not make sense as of Convoy v0.5, but we made a decision to not change the names of the files to ensure backward compatibility.

=over 3

=item B<Domains> (F<domain.yml>)

A B<Domain> is the top level of the B<Context Tree>.
Convoy uses this file as a stop point for parsing and to determine the root of the B<Context Tree>.

In Convoy v0.4 this file was used to set the defaults for an entire domain, such as F<net/karmalab>.
As of Convoy v0.5, many of the values in this file have been moved to F<environment.yml>

Here is an example of the type of information in the F<domain.yml>:

   # --- basics ---
   autoStart       : 1
   sap.filename    : ${convoy.root}/service.account.passwords

   # --- paths ---
   feedstore       : //blfilrtt01.karmalab.net/depreps
   buildType       : releasecandidate

   convoyPath      : ${feedstore}/${buildType}/convoy/convoy-0.4.5/bin
   perlBin         : ${feedstore}/thirdparty/perl/MSWin32/5.8.8/bin/perl.exe

   # --- BladeLogic ---
   jobPath         : /Build Team Jobs/E3
   packageName     : Convoy
   packagePath     : /Build_Deployment/E3/PreDefined
   userFile        : ${convoy.root}/bl_buildprop.dat

   # --- Sonic ---
   sonicServer     : msg.stable.karmalab.net
   sonicUser       : Administrator
   sonicDomain     : karmalab
   sonicCluster    : /Clusters/App1
   serviceUser     : karmalab/buildprop

=item B<Environments> (F<environment.yml>)

The next level down is B<Environment>s.
In Convoy v0.4, this meant that a new directory tree would be created for each B<Environment> (ex. sbx01 thru 08, fnt01 thru 12, etc.).
Convoy v0.5 changes tha paradigm such that there will only be one directory for each stage in the promotion model.
For example, the following directories would be defined:

   dev/         - for developers
   continuous/  - for envs using cont. integ. builds
   directed/    - for envs using directed builds
   release/     - for envs using released builds
   live/        - for the live site

Other directories may be created to accomodate the variations in the development and build promotion cycle.

Each directiory will have a F<environment.yml> to further define values for Convoy and to override values in F<domain.yml>.
Ironicly, all environment-specific configuration will not be in F<environment.yml>, but will instead be in overlays (described later).

   # --- basics ---
   env             : dev-generic
   appsDrive       : d
   javaVersion     : thirdparty/jdk/MSWin32/1.5.0_10

   # --- overrides from domain.yml ---
   autoStart       : 0
   buildType       : directedbuilds

=item B<Deployment Sets> (F<deploymentset.yml>)

A B<Deployment Set> is a group of B<Deployment Unit>s that can be deployed in a group.
You invoke the installation of a B<Deployment Set> simply shortening the B<Context Path> to include a parent directory of the desired B<Deployment Unit>s.
You may also optionally create a F<deploymentset.yml> file to provide default values for all child B<Deployment Unit>s.

Note that you may have multiple B<Deployment Set>s or B<Deployment Unit>s withing a set, but a B<Deployment Unit> cannot contain child B<Deployment Unit>s.

=item B<Deployment Units> (F<deloymentunit.yml>)

A B<Deployment Unit> is the smallest unit of deployment.
The F<deploymentunit.yml> file contains settings for the individual product or module.
And settings in this file will override the values in files up the tree.

   # --- names, modules and versions ---
   deploymentUnitName : MapService
   implementedBy      : ServiceContainer::EsService
   product            : com.expedia.e3.es.map.mapservice
   productVersion     : 1.0.1.0
   sonicQueueName     : urn:expedia:e3:es:map:interface:v1

   # --- misc options ---
   jvmOption          : -Dcom.sun.management.jmxremote.port=5553 ...

   # --- container stuff ---
   containerVersion   : 1.0.0.2
   containerDrop      : ${buildType}/com.expedia.e3.platform.messaging.servicecontainer

=item B<Overlays>

B<Overlay>s are a new feature for Convoy v0.5.
They allow you to override any values in the B<Context Tree>.
All environment-specific configuration sould go here.

   # --- overrides ---
   env             : dev01
   appsDrive       : z
   autoStart       : 1

=back

=head2 YAML Keys and Values

The following is a list of YAML keys that are used by Convoy.

=over 16

=item B<appsDrive>

The drive letter where the product is to be deployed.

=item B<autoStart>

C<0> or C<1>, depending if you want the associated service to restart after deployment.

=item B<buildType>

The type of build, usually associated with the level of the promotion model.
ex. directedbuilds, release, etc.

=item B<convoy.root>

A read-only value set by Convoy indicating the Deployment Context Root.

=item B<convoyPath>

The path to Convoy's bin directory.
Usually set to '${feedstore}/${buildType}/convoy/convoy-0.?.?/bin' (replace '?' with correct version).

=item B<deploymentUnitName>

A unique name that must be set for each deployment unit.
By convention, this sould be the abbreviated RFC13 name.

=item B<env>

The environment name.
ex. sbx08, fnt01, gwillikersxpdev, etc.

=item B<feedstore>

The UNC name pointing to the build feedstore.
ex. //blfilrtt01.karmalab.net/depreps

=item B<implementedBy>

The name of the plugin used for a deployment unit.
ex: WebApp::Tomcat::Configui

=item B<perforceVersion>

Short path to Perforce distribution.
ex. thirdparty/perforce/MSWin32/2005.2

=item B<perlBin>

Path to the Perl binary.
ex. ${feedstore}/thirdparty/perl/MSWin32/5.8.8/bin/perl.exe

=item B<product>

RFC13 name of the deployed product.
ex. com.expedia.e3.cx.expedia.base

=item B<productVersion>

Version of the product to be deployed.
ex. 1.0.0.1

=item B<sapFilename>

Location of the secure values for service accounts.
ex. ${convoy.root}/service.account.passwords

=back

=head2 YAML Values and Interpolation

Any value cane be interplated from one YAML value to another using the standard C<${}> braces.

For example:

   javaPath : C:/Java
   javaBin  : ${javaPath}/bin/java.exe

C<javaBin> will be evaluated to C<C:/Java/bin/java.exe>.
If the interpolated variable does not exist, it that section of the value will remain unchanged.

On paths: All paths in convoy are processed through a UNC path processor.
You may freely interchange forward and backward slashes, but it is preferred to use forward slashes.

=head1 GLOSSARY

=over 3

=item B<Context Path>

=item B<Context Tree>

=back

=head1 OPTIONS

=over 3

=item B<-?>, B<--help>; B<--man>

Display a short usage message, or the full manual page (sic).

=item B<-q>, B<--quiet>; B<-v>[B<vv>], B<--verbose>

Do things quietly or loudly.
There are four incremental levels of verbosity:

  -v     detailed progress
  -vv    additional program diagnostics
  -vvv   show system commands as executed

Note that B<--quiet> is automatically enabled when B<--outfile> is specified unless B<--verbose> is explicitly specified on the command line.

=item B<-d>, B<--dumpconfig>

Generates a report showing all configuration values loaded and generated from the YAML files in the CONTEXT tree.
Using this option causes no deployment action to be taken.

=item B<-O>, B<--overlay> OVERLAY

=item B<-e>, B<--env> KEY=VALUE

=item B<-m>, B<--makeman>

Generate all manual pages for Convoy.
Manual pages will be generated in HTML, text and latex format and placed in <location of this file>F</../man/>.

=item B<--test>

Run in test mode (don't actually do anything).
Only works with B<--makeman>.

=back

=head1 TODO

=over 3

=item B<Complete Manpage>

This is a placeholder as I work on the manpages.

   - Deployment Settings Values

=back

=head1 KNOWN ISSUES AND BUGS

=head1 REPORTING BUGS

Report bugs by logging a ticket in RAID.

=head1 AUTHOR

Written by Ingmar Ellenberger and Mike Liang.

=head1 COPYRIGHT

Copyright (c) 2007, Expedia Inc.

Some parts copyright (c) 2001-2007, Ingmar Ellenberger
and distributed under The Artistic License.
For the text the license, see L<http://puma.sourceforge.net/license.psp>
or read the F<LICENSE> in the root of the Puma distribution.

=head1 DEPENDENCIES

=head1 SEE ALSO

=cut
