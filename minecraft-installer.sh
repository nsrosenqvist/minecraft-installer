#!/bin/bash

#--------------------------------------------------------------------------#
# A simple script to properly install minecraft on Ubuntu
# Copyright (C) 2014 Niklas Rosenqvist
#
# This library is free software; you can redistribute it and/or
# modify it under the terms of the GNU Lesser General Public
# License as published by the Free Software Foundation; either
# version 2.1 of the License, or (at your option) any later version.
#
# This library is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
# Lesser General Public License for more details.
#
# You should have received a copy of the GNU Lesser General Public
# License along with this library; if not, write to the Free Software
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301
# USA
#--------------------------------------------------------------------------#

mcdir="/opt/minecraft"
mclauncher="$mcdir/minecraft.desktop"
mcscript="$mcdir/minecraft"
jvmpath="$(readlink -f $(which java))"
libpath="$(cd "$(dirname "$jvmpath")/../lib/amd64/" && pwd)"

function write_launcher() {
	sudo sh -c "echo '$1' >> $mclauncher"
}

function write_script() {
	sudo sh -c "echo '$1' >> $mcscript"
}

function pad_string() {
	printf "%-${2}s" "$1"
}

function add_ppa() {
	if [ -d "/etc/apt/sources.list.d" ]; then
		if [ -z "$(grep ^ /etc/apt/sources.list /etc/apt/sources.list.d/* | grep "$1")" ]; then
			sudo apt-add-repository "ppa:$1"
		fi
	else
		sudo apt-add-repository "ppa:$1"
	fi
}


function command_exists() {
	type "$1" &> /dev/null;
	return $?
}

function install_java() {
	add_ppa webupd8team/java
	sudo apt-get update
	sudo apt-get install -y oracle-java8-installer
	return $?
}

function check_dependencies() {
	if ! command_exists "java"; then
		echo "Java isn't installed, installing Oracle Java..."
		install_java
		return 0
	fi

	if [ -z "$(find /usr/lib/jvm/ -maxdepth 1 -name *oracle)" ]; then
		read -p "You don't seem to have Oracle Java installed. The creators of Minecraft only officially support Oracle Java, do you want to install it? (Y/n) " yn
		case "$yn" in
			[Nn]*) return 0;;
			*) install_java;;
		esac
	fi
}

## Actions
function helptext() {
	echo -e "\nMinecraft-installer - Usage: ${0##*/} [actions]"
	echo "Actions:"
	echo -e "\t$(pad_string "<install>" 14) Install Minecraft"
	echo -e "\t$(pad_string "<uninstall>" 14) Uninstall Minecraft"
	return 0
}

function install() {
	check_dependencies

	## Download Minecraft and a logo
	prevpwd="$(pwd)"
	sudo mkdir -p "$mcdir"

	cd "$mcdir"
	sudo wget "https://s3.amazonaws.com/Minecraft.Download/launcher/Minecraft.jar" -O Minecraft.jar
	sudo wget "http://icons.iconarchive.com/icons/dakirby309/simply-styled/256/Minecraft-icon.png" -O minecraft.png
	cd "$prevpwd"

	## Create a launcher
	sudo touch "$mclauncher"
	write_launcher "[Desktop Entry]"
	write_launcher "Name=Minecraft"
	write_launcher "Comment=Play Minecraft"
	write_launcher "GenericName=Minecraft"
	write_launcher "Keywords=Games"
	write_launcher "Exec=bash \"$mcscript\""
	write_launcher "Terminal=false"
	write_launcher "X-MultipleArgs=false"
	write_launcher "Type=Application"
	write_launcher "Icon=$mcdir/minecraft.png"
	write_launcher "Categories=Game;"
	write_launcher "MimeType=;"
	write_launcher "StartupNotify=true"
	write_launcher "Actions=MinecraftFolder"
	write_launcher ""
	write_launcher "[Desktop Action MinecraftFolder]"
	write_launcher "Name=Open .minecraft folder"
	write_launcher "Exec=nautilus ~/.minecraft"
	write_launcher "OnlyShowIn=Unity;"

	## Create minecraft launch script with linux bug workaround
	sudo touch "$mcscript"
	write_script "#!/bin/bash"
	write_script "export LD_LIBRARY_PATH=\"$libpath/\""
	write_script "java -jar /opt/minecraft/Minecraft.jar"

	## Set permissions
	sudo chmod -R 755 "$mcdir"
	sudo chmod +x "$mcscript"
	sudo chmod +x "$mcdir/Minecraft.jar"

	## Symlink launcher and executable
	sudo ln -s "$mclauncher" /usr/share/applications/minecraft.desktop
	sudo ln -s "$mcscript" /usr/local/bin/minecraft

	echo "If no error messages have been given then Minecraft is now installed."
	return 0
}

function uninstall() {
	sudo rm /usr/local/bin/minecraft
	sudo rm /usr/share/applications/minecraft.desktop
	sudo rm -R "$mcdir"

	if [ -d "$HOME/.minecraft" ]; then
		read -p "Do you want to delete your profile and saves as well? ($HOME/.minecraft). (y/N) " yn
		case "$yn" in
			[Yy]*) sudo rm -R "$HOME/.minecraft";;
		esac
	fi

	return 0
}

## Main
case "$1" in
	[Ii]*) install;;
	[UuRr]*) uninstall;;
	*) helptext;;
esac

exit $?
