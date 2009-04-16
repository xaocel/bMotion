#
#
# vim: fdm=indent fdn=1
#
 
###############################################################################
# This is a bMotion plugin
# Copyright (C) James Michael Seward 2000-2008
#
# This program is covered by the GPL, please refer the to LICENCE file in the
# distribution; further information can be found in the headers of the scripts
# in the modules directory.
###############################################################################


# built-in processing, %VAR
# syntax: %VAR{abstract}
#         %VAR{abstract:options}
# options: a comma-separated list of options
#          strip: remove a/an/the/some from the beginning of the abstract
#          owner: make possessive
#          plural: make plural
#          verb: verbise
# Not all combinations of options are a good idea

proc bMotion_plugin_output_VAR { channel line } {
	bMotion_putloglev 4 * "bMotion_plugin_output_VAR $channel $line"

	set line [string map { "%noun" "%VAR{sillyThings}" } $line]

	# transform %VAR{abstract}{strip} to new form
	regsub {%VAR\{([^\}]+)\}\{strip\}} $line "%VAR{\\1:strip}" line

	set lastloop ""

	while {[regexp -nocase {(%VAR\{([^\}:]+)(:[^\}]+)?\}(\{strip\})?)} $line matches whole_thing abstract options clean]} {
		global $abstract
		#see if we have a new-style abstract available
		set newText [bMotion_abstract_get $abstract]
		set replacement ""
		if {$newText == ""} {
			bMotion_putloglev d * "abstract '$abstract' doesn't exist in new abstracts system!"
			#insert old style
			if [catch {
				set var [subst $$abstract]
				set replacement [pickRandom $var]
			}] { 
				bMotion_putloglev d * "Unable to handle %VAR{$abstract}"
				set line ""
				break
			}
		} else {
			set replacement $newText
		}

		# check options
		set options [string range $options 1 end]
		if {$options != ""} {
			set options_list [split $options ","]
		} else {
			set options_list [list]
		}

		if {$clean == "{strip}"} {
			lappend options_list "clean"
		}

		if {[lsearch $options_list "strip"] > -1} {
			set replacement [bMotion_strip_article $replacement]
		} else {
			if {$abstract == "sillyThings"} {
				if {[rand 100] > 80} {
					set prefixes [list]
					set replacement [bMotion_strip_article $replacement]
					if [regexp -nocase "s$" $replacement] {
						set prefixes [list "des " "les "]
					} elseif [regexp -nocase "^\[aeiouy\]" $replacement] {
						set prefixes [list "d'" "l'"]
					} else {
						set prefixes [list "de la " "du " "la " "le " "un " "une "]
					}
					set prefix [pickRandom $prefixes]
					set replacement "$prefix$replacement"
				} else {
					if {![rand 100]} {
						regsub "((an?|the|some|his|her|their) )?" $replacement "\\1%VAR{noun_prefix} " replacement
						set replacement [string trim $replacement]
					}
				}
			}
		}

		if {[lsearch $options_list "verb"] > -1} {
			set replacement [bMotionMakeVerb $replacement]
		}

		if {[lsearch $options_list "plural"] > -1} {
			set replacement [bMotionMakePlural $replacement]
		}

		if {[lsearch $options_list "owner"] > -1} {
			set replacement [bMotionMakePossessive $replacement]
		}

		if {[lsearch $options_list "underscore"] > -1} {
			set replacement [string map { " " "_" } $replacement]
		}

		# actually do the replacement
		regsub $whole_thing $line $replacement line

		# check if what we swapped in gave us a %noun
		if [string match "*%noun*" $line] {
			set line [bMotionInsertString $line "%noun" "%VAR{sillyThings}"]
		}

		if {$lastloop == $line} {
			putlog "bMotion: ALERT! looping too much in %VAR code with $line (no change since last parse)"
			set line "/has a tremendous error while trying to sort something out :("
			break
		}
		set lastloop $line
	}

	return $line
}

bMotion_plugin_add_output "VAR" bMotion_plugin_output_VAR 1 "en" 3