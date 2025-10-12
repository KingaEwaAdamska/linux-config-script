#!/bin/bash
ubuntu_config(){
	basic_ubuntu_installation
	ros2_ubuntu_installation
	docker_ubuntu_installation
}

basic_ubuntu_installation(){
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

