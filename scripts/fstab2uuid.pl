#!/usr/bin/perl
$self = "Fstab2uuid";
#$ARGV[0] = "/etc/fstab.test";
$^I=".sidux-orig";
while(<>) { 
	if (m|^(/dev/[hs]d[a-z][1-9][0-9]?)\s|) { 
		chomp($uuid = `/lib/udev/vol_id -u $1`);
		if ($uuid and ! $?) {
			if ($h{$uuid}) {
				print STDERR "${self} error: duplicate UUID '$uuid' found!\n";
			}
			else {
				$h{$uuid}++;
				s/$1/UUID=$uuid/;
			}
		}
	} 
	print;
}

