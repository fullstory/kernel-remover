BEGIN {
	FS = ","
}

{
	# Skip comments of blank lines
	if (! $1 || $1 ~ /^#/)
		next
	
	# Strip leading/trailing whitespace from fields
	for (n = 1; n <= NF; n++)
		gsub(/(^[ \t]+|[ \t]+$)/,"",$n)
	
	# Form package name to be injected into substvars
	package = $2 ? $1 " " $2 : $1

	# Process arch specific packages, or assume package is
	# wanted when no arch is listed
	if ($3) {
		for (n = 3; n <= NF; n++) {
			if ($n == deb_build_arch) {
				if (substvars)
					depends = depends ? depends ", " package : package
				else
					print $1
			}
		}
	}
	else {
		if (substvars)
			depends = depends ? depends ", " package : package
		else
			print $1
	}
}

END {
	# If "substvars" is defined (-v substvars=1) then print substvarss
	if (substvars && depends)
		print "module:Depends=" depends
}
