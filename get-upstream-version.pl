#!/usr/bin/perl -w

# Copyright (C) 2006-2014 Bart Martens <bartm@knars.be>
#
# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License version 2 as
# published by the Free Software Foundation.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.

use warnings;
use strict;

if( ! defined $ARGV[0] )
{
	print STDERR "architecture not specified, try for example i686 or x86_64\n";
	exit 1;
}

sub read_page
{
	my $arch = shift;
	my $url = shift;
	my $page = '';

	{
		local $/ = undef;
		my $user_agent = "Mozilla/5.0 (X11; U; Linux $arch; en-us) AppleWebKit/531.2+ (KHTML, like Gecko)"
			." Version/5.0 Safari/531.2+ Debian/squeeze (2.30.6-1) Epiphany/2.30.6";

		open INPUT, "wget --no-check-certificate --tries=1 --user-agent=\"$user_agent\" -nv -qO - $url |" or die;
		$page = <INPUT>;
		close INPUT;
	}

	return $page;
}

my $page;
my $url = "http://www.adobe.com/";
$page = read_page( $ARGV[0], $url );
die "failed to read $url" if( $page eq "" );
if( $page !~ m,<a href="([^"]+)"(?: class="dom-bottom-bar--box--link")?>(?:Adobe )?Flash Player</a>,s )
{
	if( -d "/var/cache/flashplugin-nonfree" )
	{
		open OUTPUT, "> /var/cache/flashplugin-nonfree/adobewebpage.html";
		print OUTPUT $page;
		close OUTPUT;
	}
	die "link to Adobe Flash Player not found on $url";
}

my $link_to_flash = $1;

if( $link_to_flash =~ m%^http(?:s)?://get\d*\.adobe\.com/flashplayer/(?:\?promoid=[A-Z]+)?$% )
{
	$url = $link_to_flash;
}
else
{
	$link_to_flash =~ s,^/,,;
	die "link to flash contains invalid characters: $link_to_flash" if( $link_to_flash !~ m%^[a-zA-Z0-9_/=?]+$% );
	$url = "http://www.adobe.com/$link_to_flash";
}

$page = read_page( $ARGV[0], $url );
die "failed to read $url" if( $page eq "" );
$page =~ m,<h4>Adobe Flash Player version (\d+\.\d+\.\d+\.\d+)<br />Your system: [^<>]*<span id="clientfilesize"></span></h4>,
	or $page =~ m%<strong>Version (\d+\.\d+\.\d+\.\d+)</strong>%
	or die "failed to extract Flash Player version from $url";

print "$1\n";
