#!/bin/bash

LOG_FILE="$HOME/setup-dev.log"
exec > >(tee -a "$LOG_FILE") 2>&1

TOTAL_STEPS=10
CURRENT_STEP=1

log() {
  echo -e "\n[$(date +'%Y-%m-%d %H:%M:%S')] $1"
}

step() {
  local description="$1"
  shift
  log "[$CURRENT_STEP/$TOTAL_STEPS] $description..."
  if "$@"; then
    log "✔️ $description concluído com sucesso."
  else
    log "⚠️ Erro durante: $description. Pulando para a próxima etapa."
  fi
  CURRENT_STEP=$((CURRENT_STEP + 1))
}

update_system() {
  sudo apt update && sudo apt upgrade -y
}

install_dependencies() {
  sudo apt install -y curl unzip zip git ca-certificates gnupg lsb-release \
    software-properties-common apt-transport-https wget gdebi-core libfuse2
}

install_sdkman_and_tools() {
  curl -s "https://get.sdkman.io" | bash
  source "$HOME/.sdkman/bin/sdkman-init.sh"
  sdk install java $(sdk list java | grep -E "\|\s+[0-9]{4}\..*LTS\s+\|" | head -n1 | awk '{ print $NF }')
  sdk install maven
  sdk install gradle
}

install_docker() {
  sudo install -m 0755 -d /etc/apt/keyrings
  curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
  echo \
    "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] \
    https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | \
    sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
  sudo apt update
  sudo apt install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
  sudo usermod -aG docker "$USER"
}

install_flatpaks() {
  sudo apt install -y flatpak gnome-software-plugin-flatpak
  sudo flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo

  flatpak install -y flathub com.github.johnfactotum.Foliate
  flatpak install -y flathub org.gimp.GIMP
  flatpak install -y flathub com.heroicgameslauncher.hgl
  flatpak install -y flathub com.spotify.Client
  flatpak install -y flathub dev.bruno.Brunow
}

install_debs() {
  wget -O /tmp/google-chrome.deb https://dl.google.com/linux/direct/google-chrome-stable_current_amd64.deb
  sudo dpkg -i /tmp/google-chrome.deb || sudo apt install -f -y

  wget -O /tmp/vscode.deb "https://code.visualstudio.com/sha/download?build=stable&os=linux-deb-x64"
  sudo gdebi -n /tmp/vscode.deb
}

install_jetbrains_toolbox() {
  TOOLBOX_URL=$(curl -s https://data.services.jetbrains.com/products/releases?code=TBA&latest=true&type=release \
    | grep -oP 'https.*jetbrains-toolbox-.*\.tar\.gz' | head -n1)

  mkdir -p "$HOME/Apps"
  cd "$HOME/Apps"
  wget -O toolbox.tar.gz "$TOOLBOX_URL"
  tar -xzf toolbox.tar.gz
  rm toolbox.tar.gz
  TOOLBOX_DIR=$(find . -maxdepth 1 -type d -name "jetbrains-toolbox-*")
  "$TOOLBOX_DIR/jetbrains-toolbox" &
}

install_node() {
  curl -fsSL https://deb.nodesource.com/setup_lts.x | sudo -E bash -
  sudo apt install -y nodejs
}

install_gaming_stack() {
  sudo apt install -y nvidia-driver-535 nvidia-prime
  sudo apt install -y mesa-vulkan-drivers vulkan-utils libvulkan1 libvulkan1:i386
  sudo apt install -y gamemode libgamemode0 libgamemodeauto0 mangohud
  sudo apt install -y steam joystick jstest-gtk libgl1:i386 libglu1-mesa:i386 libsdl2-2.0-0:i386
}

install_lutris_and_optimize_gaming() {
  sudo add-apt-repository -y ppa:lutris-team/lutris
  sudo apt update
  sudo apt install -y lutris

  log "➡️ Após abrir a Steam: ative Steam Play para usar Proton."
  log "➡️ Use 'gamemoderun' e 'mangohud' para otimizar jogos."
}

final_message() {
  log "✅ Instalação finalizada com sucesso!"
  log "📄 Log completo salvo em: $LOG_FILE"
  log "🔁 Reinicie ou faça logout/login para ativar Docker e drivers NVIDIA."
}

# Execução com controle de falha e progresso
step "Atualizando o sistema" update_system
step "Instalando dependências" install_dependencies
step "Instalando SDKMAN, Java, Maven e Gradle" install_sdkman_and_tools
step "Instalando Docker e Compose" install_docker
step "Instalando Flatpak e apps (Spotify, Bruno, etc)" install_flatpaks
step "Instalando Chrome e VS Code via DEB" install_debs
step "Instalando JetBrains Toolbox" install_jetbrains_toolbox
step "Instalando Node.js LTS" install_node
step "Instalando drivers NVIDIA e stack de jogos" install_gaming_stack
step "Instalando Lutris e otimizando jogos" install_lutris_and_optimize_gaming

final_message

