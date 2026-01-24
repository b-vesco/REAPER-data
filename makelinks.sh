#!/bin/bash

# Vesco: Run this to set up all the symlinks from this repo to REAPER

array=( ColorThemes Cursors Data Effects FXChains KeyMaps LangPack MIDINoteNames MouseMaps OSC ProjectTemplates QueuedRenders Scripts TrackTemplates UserPlugins presets reaper_www_root )

REAPER=~/Library/Application\ Support/REAPER/

for i in "${array[@]}"
do
	# -s create symbolic link
	# -v verbose mode
	ln -sv "$PWD/$i" "$REAPER"
done

