#!/bin/bash

fedora_config(){
	fedora_basic_stuff
	fedora_flatpak_install
}

fedora_basic_stuff(){
	sudo dnf install https://mirrors.rpmfusion.org/free/fedora/rpmfusion-free-release-$(rpm -E %fedora).noarch.rpm https://mirrors.rpmfusion.org/nonfree/fedora/rpmfusion-nonfree-release-$(rpm -E %fedora).noarch.rpm -y
	sudo dnf install -y wl-clipboard steam curl git zsh flatpak ripgrep
}

fedora_flatpak_install(){
		flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo
		flatpak install flathub com.heroicgameslauncher.hgl
		flatpak install flathub org.signal.Signal
		flatpak install flathub io.github.spacingbat3.webcord
}
