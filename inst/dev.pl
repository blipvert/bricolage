#!/usr/bin/perl -w

=head1 NAME

dev.pl - installs bricolage to run out of a Subversion checkout

=head1 VERSION

$LastChangedRevision$

=head1 DATE

$LastChangedDate: $

=head1 DESCRIPTION

This script is called during "make dev" to modify a standard install to
point some files back at the Subversion checkout it's being installed from.

=head1 AUTHOR

Marshall Roch <marshall@exclupen.com>

=cut


use strict;
use FindBin;
use lib "$FindBin::Bin/lib";
use Cwd;
use Bric::Inst qw(:all);
use File::Spec::Functions qw(catdir);
use File::Path qw(rmtree);

# make sure we're root, otherwise uninformative errors result
unless ($> == 0) {
    print "This process must (usually) be run as root.\n";
    exit 1 unless ask_yesno("Continue as non-root user?", 1);
}

print "\n\n==> Setting Up Development Environment <==\n\n";

# read in user config settings
our $CONFIG;
do "./config.db" or die "Failed to read config.db : $!";

# Delete bin/, comp/ and lib/ so we can replace them with SVN versions
rmtree([$CONFIG->{BIN_DIR},
		$CONFIG->{MASON_COMP_ROOT},
		$CONFIG->{MODULE_DIR}]);

symlink(catdir(cwd, '/bin'), $CONFIG->{BIN_DIR});
symlink(catdir(cwd, '/comp'), $CONFIG->{MASON_COMP_ROOT});
symlink(catdir(cwd, '/lib'), $CONFIG->{MODULE_DIR});

print "\n\n==> Finished Setting Up Development Environment <==\n\n";
exit 0;