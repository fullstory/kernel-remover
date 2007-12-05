#!/usr/bin/gawk -f
BEGIN {
	FS = ","
}

{
	arch    = match($3, deb_build_arch) ? deb_build_arch : "all"
	package = $2 ? $1 " " $2 : $1

	if (! $3 || match($3, deb_build_arch)) {
		depends[arch] = depends[arch] ? depends[arch] ", " package : package
		modules[i++] = $1
	}
}

END {
	if (substvar) {
		module_depends = depends[deb_build_arch] ? depends["all"] ", " depends[deb_build_arch] : depends["all"]
		print "module:Depends=" module_depends
	}
	else {
		for (i in modules)
			print modules[i]
	}
}
