#!/bin/bash

# Vesco: Run this to set up all the symlinks from this repo to REAPER

# NOTE to self: When adding commands with flags/switches, always
# include short mnemonic comments next to the line describing the
# relevant flags. This helps future edits and reduces guesswork.

array=( ColorThemes Cursors Data Effects FXChains KeyMaps LangPack MIDINoteNames MouseMaps OSC ProjectTemplates QueuedRenders Scripts TrackTemplates UserPlugins presets reaper_www_root )

# Use quoted path to handle the space in "Application Support"
REAPER="$HOME/Library/Application Support/REAPER"

# -p: create parent directories as needed; no error if exists
mkdir -p "$REAPER"

# Color detection: prefer truecolor when available, otherwise use 8-color fallback
# Check common env vars for truecolor support
if [[ "${COLORTERM:-}" =~ (truecolor|24bit) || "${TERM:-}" =~ (truecolor|24bit) ]]; then
	USE_TRUECOLOR=1
else
	USE_TRUECOLOR=0
fi

# Color definitions (truecolor then 8-color fallback)
# ERROR: Firebrick    #B22222 -> (178,34,34)
# INFO:  Deep Navy    #003366 -> (0,51,102)
# ACTION: Forest Green#2E8B57 -> (46,139,87)

ERR24="\033[38;2;178;34;34m"
INF24="\033[38;2;0;51;102m"
ACT24="\033[38;2;46;139;87m"

ERR8="\033[31m"  # red
INF8="\033[34m"  # blue
ACT8="\033[32m"  # green

# Reset
RST="\033[0m"

# log LEVEL MESSAGE
# LEVEL is one of: ERROR, INFO, ACTION
# Each prefix is right-padded to width of "ACTION" (6 chars) for alignment.
log() {
	level="$1"; shift
	label="$(printf '%-6s' "$level")"

	if [ "$USE_TRUECOLOR" -eq 1 ]; then
		case "$level" in
			ERROR) color="$ERR24";;
			INFO)  color="$INF24";;
			ACTION)color="$ACT24";;
			*) color="$RST";;
		esac
	else
		case "$level" in
			ERROR) color="$ERR8";;
			INFO)  color="$INF8";;
			ACTION)color="$ACT8";;
			*) color="$RST";;
		esac
	fi

	# Print to stderr for ERROR, stdout otherwise
	if [ "$level" = "ERROR" ]; then
		printf '%b[%s] %s%b\n' "$color" "$label" "$*" "$RST" >&2
	else
		printf '%b[%s] %s%b\n' "$color" "$label" "$*" "$RST"
	fi
}

for i in "${array[@]}"
do
	src="$PWD/$i"
	dest="$REAPER/$i"

	# [ -e FILE ]: true if FILE exists (any type). '!' negates the test.
	if [ ! -e "$src" ]; then
		log INFO "Source $src does not exist; skipping."
		continue
	fi

	# [ -L FILE ]: true if FILE exists and is a symbolic link
	if [ -L "$dest" ]; then
		# Destination is a symlink — remove and recreate it
		log ACTION "removing existing symlink $dest"
		rm "$dest"
		log ACTION "creating link $dest -> $src"
		ln -s "$src" "$dest"
	elif [ -e "$dest" ]; then
		# Destination exists and is NOT a symlink — check if empty and removable
		if [ -d "$dest" ]; then
			# Directory: consider empty if `ls -A` produces no output
			if [ -z "$(ls -A "$dest")" ]; then
				log ACTION "Target $dest is an empty directory — removing and replacing with symlink."
				rm -r "$dest"
				log ACTION "creating link $dest -> $src"
				ln -s "$src" "$dest"
			else
				# Non-empty directory — warn and skip
				log ERROR "Target dir $dest is not a link. Merge or resolve contents before continuing."
			fi
		elif [ -f "$dest" ]; then
			# Regular file: consider empty if size is zero
			if [ ! -s "$dest" ]; then
				log ACTION "Target $dest is an empty file — removing and replacing with symlink."
				rm "$dest"
				log ACTION "creating link $dest -> $src"
				ln -s "$src" "$dest"
			else
				# Non-empty file — warn and skip
				log ERROR "Target dir $dest is not a link. Merge or resolve contents before continuing."
			fi
		else
			# Other types (socket, device, etc.) — do not remove
			log ERROR "Target $dest exists and is not a link. Merge or resolve contents before continuing."
		fi
	else
		# Destination doesn't exist — create symlink
		log ACTION "creating link $dest -> $src"
		ln -s "$src" "$dest"
	fi
done

