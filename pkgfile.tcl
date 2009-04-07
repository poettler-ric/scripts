# checks, whether a argument is a empty string
proc areAllElementsFilled {someList} {
	return [expr {[lsearch $someList {}] == -1}]
}

# constructs an list with a given amount of empty elements
proc emptyList {elements} {
	set tmpList {}
	for {set index 0} {$index < $elements} {incr index} {
		lappend tmpList {}
	}
	return $tmpList
}

# queries a Pkgfile for given elements
proc parsePkgfile {filename args} {
	# this are bash comments, so they are prefixed with #
	set pattern_description {^\s*#\s*description\s*:\s*(.+)}
	set pattern_url {^\s*#\s*url\s*:\s*(.+)}
	set pattern_packager {^\s*#\s*packager\s*:\s*(.+)}
	set pattern_maintainer {^\s*#\s*maintainer\s*:\s*(.+)}
	# those are bash variables, so there is no space before and after the =
	set pattern_name {^\s*name=(\w+)}
	set pattern_version {^\s*version=([.\w]+)}
	set pattern_release {^\s*release=([.\w]+])}
	set pattern_source {xxx} ;# TODO: the source is more complicated (bash
				  # array, maybe over more than one line)

	# if no args are given -> gather all values
	if {[llength $args] == 0} {
		set args [list name version release description url packager maintainer source]
	}

	# construct the pattern to extract all wanted elements
	set pattern {}
	foreach toGet $args {
		append pattern "|" [set pattern_$toGet]
	}
	set pattern [string trim $pattern "|"]

	# open the file
	if {[catch {open $filename r} file]} {
		puts stderr "Couln't open $filename for reading \n$file"
		exit 1
	}

	# query the file for the values
	set parsedValues [emptyList [llength $args]]
	foreach line [split [read $file] "\n"] {
		if {[eval [list regexp -nocase $pattern $line x] $args]} {
			set index 0
			# copy the nonempty value from the subpatterns to the
			# parsed values
			foreach subPattern $args {
				if {[string length [set $subPattern]] > 0} {
					lset parsedValues $index [set $subPattern]
					break
				}
				incr index
			}
		}
		# if we got all values -> stop looping
		if [areAllElementsFilled $parsedValues] {
			break
		}
	}
	close $file
	return $parsedValues
}

set filename fakeroot-Pkgfile
puts [parsePkgfile $filename name version maintainer]
