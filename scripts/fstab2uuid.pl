#!/usr/bin/perl
$ARGV[0] = "/etc/fstab";
$^I=".sidux-orig";
while(<>) { if (m|^(/dev/[hs]d[a-z][1-9][0-9]?)\s|) { chomp($uuid = `/lib/udev/vol_id -u $1`); 	$uuid and s/$1/UUID=$uuid/ } print }

