#!/usr/bin/gawk -f

{
	src_regexp = "^(.+)-(src|source)"
	gsub(/,/,"")
	if (/^(Depends|Recommends):/) {
		for (i = 1; i <= NF; i++) {
			if ($i ~ src_regexp) {
				printf "%s\n", $i
			}
		}
	}
}
