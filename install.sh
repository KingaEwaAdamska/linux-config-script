#!/bin/bash

source ./ubuntu.sh
source ./fedora.sh

install_and_set_0xproto_nerdfont() {
  local font_name="0xProto Nerd Font Mono"
  local font_package="0xProto.zip"
  local font_url="https://github.com/ryanoasis/nerd-fonts/releases/latest/download/${font_package}"
  local font_dir="$HOME/.local/share/fonts/NerdFonts"

  echo "📦 Pobieranie czcionki $font_name..."
  mkdir -p "$font_dir"
  cd /tmp || exit

  curl -fLo "$font_package" "$font_url"
  if [[ $? -ne 0 ]]; then
      echo "❌ Błąd podczas pobierania czcionki."
      return 1
  fi

  unzip -o "$font_package" -d "$font_dir"

  fc-cache -fv "$font_dir"

  echo "Font $font_name installed in $font_dir"

  # Sprawdź, czy czcionka jest zainstalowana
  if fc-list | grep -qi "$font_name"; then

      # Automatyczna zmiana czcionki w GNOME Terminal
      if command -v gsettings &> /dev/null && gsettings get org.gnome.Terminal.ProfilesList list &> /dev/null; then
          echo "🎛 Ustawianie czcionki w GNOME Terminal..."

          # Pobierz domyślny profil terminala
          local profile_id
          profile_id=$(gsettings get org.gnome.Terminal.ProfilesList default | tr -d \')

          # Ustaw czcionkę (rozmiar możesz zmienić np. na 12 lub 14)
          local font_string="${font_name} 12"

          gsettings set "org.gnome.Terminal.Legacy.Profile:/org/gnome/terminal/legacy/profiles:/:$profile_id/" use-system-font false
          gsettings set "org.gnome.Terminal.Legacy.Profile:/org/gnome/terminal/legacy/profiles:/:$profile_id/" font "$font_string"

          echo "✅ Czcionka została ustawiona w GNOME Terminal: $font_string"
      else
          echo "⚠ Nie wykryto GNOME Terminal lub brak dostępu do ustawień. Ustaw czcionkę ręcznie."
      fi
  else
      echo "❌ Czcionka nie została poprawnie zainstalowana."
  fi
}

zsh_config() {
	echo "======= Zsh install ======"
		sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
		chsh -s $(which zsh)
		curl -sS https://starship.rs/install.sh | sh
		echo 'eval "$(starship init zsh)"' >> ~/.zshrc
		starship preset catppuccin-powerline -o ~/.config/starship.toml
}

nvim_install() {
	if [ ! -d /opt/nvim ]; then
		echo "======= Nvim installation ======="
		LATEST_TAG=$(curl -s https://api.github.com/repos/neovim/neovim/releases/latest | grep tag_name | cut -d '"' -f 4)
		FILE="nvim-linux-x86_64.tar.gz"
		curl -LO "https://github.com/neovim/neovim/releases/download/${LATEST_TAG}/${FILE}"
		tar xzvf "$FILE"
		sudo mv nvim-linux-x86_64 /opt/nvim
		sudo ln -sf /opt/nvim/bin/nvim /usr/local/bin/nvim
		nvim --version
	else
		echo "======= Nvim already exist ======="
	fi
}

nvim_config() {
	mv ~/.local/share/nvim ~/.local/share/nvim.bak
	mv ~/.local/state/nvim ~/.local/state/nvim.bak
	mv ~/.cache/nvim ~/.cache/nvim.bak	
	git clone --depth 1 https://github.com/AstroNvim/template ~/.config/nvim
}

brave_install() {
	if ! command 	-v brave-browser &> /dev/null; then
		curl -fsS https://dl.brave.com/install.sh | sh
	fi
}

ssh_generation() {
	local key_name=${1:-id_rsa}      
  local key_comment=${2:-"$USER@$(hostname)"}  
  local ssh_dir="$HOME/.ssh"

  # Tworzenie katalogu .ssh jeśli nie istnieje
  if [ ! -d "$ssh_dir" ]; then
    mkdir -p "$ssh_dir"
    chmod 700 "$ssh_dir"
    echo "Utworzono katalog $ssh_dir"
  fi

  # Sprawdzenie, czy są już jakieś klucze SSH
  if ls "$ssh_dir"/id_* 1> /dev/null 2>&1; then
    echo "W katalogu $ssh_dir znajdują się już klucze SSH. Nie wygenerowano nowego klucza."
    return 1
  fi

  local key_path="$ssh_dir/$key_name"

  # Generowanie klucza
  ssh-keygen -t rsa -b 4096 -C "$key_comment" -f "$key_path"
   
  # Ustawienie praw do klucza prywatnego
  chmod 600 "$key_path"

  echo "Klucz SSH został wygenerowany: $key_path"
}

############################# Main #################################
echo "======= Distro check... ======="
if [ -f /etc/os-release ]; then
	if grep -qi "ubuntu" /etc/os-release; then
		ubuntu_config
	fi
	if grep -qi "fedora" /etc/os-release; then
		fedora_config
	fi
else
	echo "Doesnt found distro file"
	exit 1
fi
echo "======= Distro independent part ======="
install_and_set_0xproto_nerdfont
zsh_config
nvim_install
nvim_config
brave_install
ssh_generation
