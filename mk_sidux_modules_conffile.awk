#!/usr/bin/gawk -f
BEGIN {
	src_regexp = "^(.+)-(src|source)"
}

/^Depends:/ {
	do {
		if (!/^Depends:/ && !/^[ \t]+/)
			break
		gsub(/,/,"")
		for (i = 1; i <= NF; i++)
			if ($i ~ src_regexp)
				printf "%s\n", $i
	} while(getline > 0)
}

/^Recommends:/ && arch == "i386" {
	do {
		if (!/^Recommends:/ && !/^[ \t]+/)
			break
		gsub(/,/,"")
		for (i = 1; i <= NF; i++)
			if ($i ~ src_regexp)
				printf "%s\n", $i
	} while(getline > 0)
}
