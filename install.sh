#!/bin/bash
basic_installation(){
	echo "======= Ubuntu configuration ======="
	echo "======= Installing some basic stuff ======="
	sudo apt update && sudo apt upgrade
	sudo apt-add-repository -y universe
	packages=(curl ca-certificates git software-properties-common zsh)
	for pkg in "${packages[@]}"; do
        	if ! dpkg -s "$pkg" &>/dev/null; then
        		echo "Installing $pkg..."
        		sudo apt install -y "$pkg"
        	else
       			echo "$pkg is already installed."
        	fi
	done
}

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
          echo "🎛️ Ustawianie czcionki w GNOME Terminal..."

          # Pobierz domyślny profil terminala
          local profile_id
          profile_id=$(gsettings get org.gnome.Terminal.ProfilesList default | tr -d \')

          # Ustaw czcionkę (rozmiar możesz zmienić np. na 12 lub 14)
          local font_string="${font_name} 12"

          gsettings set "org.gnome.Terminal.Legacy.Profile:/org/gnome/terminal/legacy/profiles:/:$profile_id/" use-system-font false
          gsettings set "org.gnome.Terminal.Legacy.Profile:/org/gnome/terminal/legacy/profiles:/:$profile_id/" font "$font_string"

          echo "✅ Czcionka została ustawiona w GNOME Terminal: $font_string"
      else
          echo "⚠️ Nie wykryto GNOME Terminal lub brak dostępu do ustawień. Ustaw czcionkę ręcznie."
      fi
  else
      echo "❌ Czcionka nie została poprawnie zainstalowana."
  fi
}



ros2_ubuntu_installation(){
	if [ ! -d "/opt/ros" ]; then
		echo "======= Installing ROS2 humble ======="
		export ROS_APT_SOURCE_VERSION=$(curl -s https://api.github.com/repos/ros-infrastructure/ros-apt-source/releases/latest | grep -F "tag_name" | awk -F\" '{print $4}')
		curl -L -o /tmp/ros2-apt-source.deb "https://github.com/ros-infrastructure/ros-apt-source/releases/download/${ROS_APT_SOURCE_VERSION}/ros2-apt-source_${ROS_APT_SOURCE_VERSION}.$(. /etc/os-release && echo $VERSION_CODENAME)_all.deb" # If using Ubuntu derivates use $UBUNTU_CODENAME
		sudo dpkg -i /tmp/ros2-apt-source.deb
		sudo apt update & sudo apt upgrade
		sudo apt -y install ros-humble-desktop python3-colcon-common-extensions
		# instalacja naszych, scorpiowych zależności
		sudo apt -y install  geographiclib-tools libgeographic-dev  geographiclib-tools libgeographic-dev ros-humble-hardware-interface ros-humble-moveit ros-humble-moveit-servo libmagic-enum-dev ros-humble-pcl-ros  protobuf-compiler libprotobuf-dev
		source /opt/ros/humble/setup.bash
	fi
}

docker_ubuntu_installation(){
	echo "======= Installing docker ======="
	sudo install -m 0755 -d /etc/apt/keyrings
	sudo curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc
	sudo chmod a+r /etc/apt/keyrings/docker.asc
	echo \
  	"deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu \
	$(. /etc/os-release && echo "${UBUNTU_CODENAME:-$VERSION_CODENAME}") stable" | \
	sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
	sudo apt-get update
	sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
	sudo useradd -g $USER docker
}

zsh_config() {
	echo "======= Zsh install ======"
	if [ ! -d "$HOME/.oh-my-zsh" ]; then
		sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
		chsh -s $(which zsh)
		curl -sS https://starship.rs/install.sh | sh
		echo 'eval "$(starship init zsh)"' >> ~/.zshrc
		starship preset gruvbox-rainbow -o ~/.config/starship.toml
	fi
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
		echo "======= Finded Ubuntu ======="
		basic_installation
		install_and_set_0xproto_nerdfont
		ros2_ubuntu_installation
		docker_ubuntu_installation

	else
		echo "To nie ubuntu"
	fi
else
	echo "Doesnt found distro file"
	exit 1
fi
echo "======= Distro independent part ======="
zsh_config
nvim_install
nvim_config
brave_install
ssh_generation
