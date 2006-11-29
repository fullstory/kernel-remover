#!/usr/bin/gawk -f

{
	tar = "^/usr/src/(.*)\\.(gz|bz2)$"
	list = gensub($0,"/var/lib/dpkg/info/&.list","g")
	while ((getline < list) > 0) {
		if ($0 ~ tar) {
			printf "unp %s >/dev/null", $0 | "/bin/sh"
			close("/bin/sh")
		}
	}
			
}
