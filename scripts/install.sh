#!/usr/bin/env bash

set -euo pipefail

config="/etc/velocity/velocity.toml"

# --- Get architecture ---
get_arch() {
  arch=$(uname -m)
  if [ [ "$arch" = "aarch64" ] || [ "$arch" = "arm64" ] ]; then
    arch=arm64
  elif [ "$arch" = "x86_64" ]; then
    arch=amd64
  fi
  echo $arch
}

ROOT_DIR="/etc/velocity"

if [ ! -f "/etc/systemd/system/velocity.service" ]; then

  # --- SystemD Checker ---
  if [ ! -d "/etc/systemd/system" ]; then
    echo "Please install systemd for service management!"
    exit 1
  fi

  # --- Installing dependencies required for the rest of the script ---
  echo "Installing dependancies!"

  apt install curl whiptail jq -y
  (apt install openjdk-21 -y)||(apt install extrepo -y&&extrepo enable zulu-openjdk&&apt update&&apt install zulu21-jdk)||echo "Java Install Failed With Error: $?"&&exit 15

  # --- File System Setup ---
  echo "Setting up file system!"

  URL="https://raw.githubusercontent.com/mk5912/velocity_service_unix/refs/heads/DEV/scripts"


  if [ ! -d $ROOT_DIR ]; then
    mkdir $ROOT_DIR
  fi

  echo "Getting Velocity updater!"
  curl "$URL/update_velocity.sh">"$ROOT_DIR/update_velocity.sh"

  chmod +x "/etc/velocity/update_velocity.sh"

  echo "Getting Velocity service file!"
  curl "$URL/velocity.service">"/etc/systemd/system/velocity.service"

  echo "Reloading services!"
  systemctl daemon-reload

fi

# --- Install dasel if not already installed ---
if [ ! -f "/usr/local/bin/dasel" ]; then
  curl -sSL "https://github.com/TomWright/dasel/releases/latest/download/dasel_linux_$(get_arch)" -o "/usr/local/bin/dasel"
  chmod a+x "/usr/local/bin/dasel"
fi


# --- Helper: get download urls for ViaVersion plugins ---
get_github_release() {
  PROJECT=$1
  SLUG=$2
  local URL=$(curl -s -H "User-Agent: Velocity_Service_Installer" "https://api.github.com/repos/$PROJECT/$SLUG/releases/latest"|jq -r ".assets[].browser_download_url")
  echo "$URL"
}

# --- TOML config editor ---
toml_edit() {

  set +u

  local file=$1 action=$2 selector=$3 type=$4 value=$5

  case "$action" in
    "set")
      if [ "$type" = "array" ]; then
        dasel put -t yaml -f "$file" -w toml -s "$selector" -v "[$value]"
      else
        dasel put -t "$type" -f "$file" -w toml -s "$selector" -v "$value"
      fi
      ;;
    "clear")
      if [ "$type" = "array" ]; then
        dasel put -t yaml -f "$file" -w toml -s "$selector" -v "[]"
      else
        dasel put -t "$type" -f "$file" -w toml -s "$selector" -v ""
      fi
      ;;
    "delete")
      dasel delete -f "$file" -w toml -s "$selector"
      ;;
  esac

  set -u

}

# Velocity Proxy Plugin Installer Wizard with progress bar
# Requirements: whiptail, curl, jq (optional)

PLUGINS_DIR="$ROOT_DIR/plugins"

if [ ! -d $PLUGINS_DIR ]; then
  mkdir -p "$PLUGINS_DIR"
fi

# --- Velocity Plugin URLs ---
declare -A VELOCITY_PLUGINS=(
  ["ViaVersion"]=$(get_github_release "ViaVersion" "ViaVersion")
  ["ViaBackwards"]=$(get_github_release "ViaVersion" "ViaBackwards")
  ["ViaRewind"]=$(get_github_release "ViaVersion" "ViaRewind")
  ["LuckPerms"]="https://download.luckperms.net/latest/velocity"
  ["MiniMOTD"]="https://api.papermc.io/v2/projects/minimotd/versions/latest/builds/latest/downloads/MiniMOTD-Velocity.jar"
  ["CommandAliases"]=$(get_github_release "VelocityPowered" "CommandAliases")
  ["GeyserMC"]="https://download.geysermc.org/v2/projects/geyser/versions/latest/builds/latest/downloads/velocity"
  ["Floodgate"]="https://download.geysermc.org/v2/projects/floodgate/versions/latest/builds/latest/downloads/velocity"
)

# --- Helper: show checklist ---
show_checklist() {
  whiptail --title "Velocity Plugin Installer" --checklist \
    "Select plugins to install (use spacebar to toggle):" 18 70 8 \
    "ViaVersion" "Allow newer client versions to connect" ON \
    "ViaBackwards" "Allow older client versions to connect" ON \
    "ViaRewind" "Optional addon for older versions" OFF \
    "MiniMOTD" "Fancy join/leave messages" OFF \
    "LuckPerms" "Advanced permissions plugin" OFF \
    "CommandAliases" "Simplify or remap commands" OFF \
    "GeyserMC" "Enables Bedrock support for Java" ON \
    "Floodgate" "GeyserMC plugin - link Bedrock & Java accounts" ON \
    3>&1 1>&2 2>&3
}

# --- Step 1: Choose plugins ---
CHOICES=$(show_checklist)
[[ -z "${CHOICES}" ]] && { echo "No plugins selected. Exiting."; exit 0; }

# --- Step 2: Confirm ---
if ! whiptail --title "Confirm Installation" \
  --yesno "Install the following Velocity plugins?\n\n${CHOICES}" 15 60; then
  echo "❌ Installation cancelled."
  exit 0
fi

read -r -a PLUGINS <<< "${CHOICES//\"/}"

# --- Step 3: Download with progress bar ---
{
  COUNT=0
  TOTAL=$(echo "$CHOICES" | wc -w)

  set +e

  for plugin in ${PLUGINS[@]}; do
    ((COUNT++))
    echo "XXX"
    echo "$(( (COUNT - 1) * 100 / TOTAL ))"
    echo "Downloading $plugin ($COUNT/$TOTAL)..."
    echo "XXX"

    URL="${VELOCITY_PLUGINS[$plugin]}"

    curl -L -s -o "${PLUGINS_DIR}/${plugin}.jar" "$URL"

  done

  set -e

  echo "XXX"
  echo "100"
  echo "✅ Installation complete! Plugins saved in '${PLUGINS_DIR}/'."
  echo "XXX"
} | whiptail --title "Installing Plugins" --gauge "Preparing downloads..." 8 70 0

if [ ! "$(systemctl show -p ActiveState --value velocity)" = "active" ]; then
  echo "Starting the Velocity service!"

  systemctl enable velocity

  systemctl start velocity
else
  echo "Restarting the Velocity service!"

  systemctl restart velocity
fi

servers=()

while whiptail --title "Velocity Setup" --yesno "Add A New Local Server Host?" 10 30; do
  name=$(whiptail --inputbox "Server Name (i.e. Survival)" 8 39 --title "New Server" 3>&1 1>&2 2>&3)
  ip=$(whiptail --inputbox "Server Local IP Address And Port (xxx.yyy.zzz.qqq:ppppp)" 8 39 --title "New Server" 3>&1 1>&2 2>&3)
  fqdn=$(whiptail --inputbox "Server FQDN (i.e. mc.example.com):" 8 39 --title "New Server" 3>&1 1>&2 2>&3)
  toml_edit "$config" set "servers.$name" string "$ip"
  toml_edit "$config" set "forced-hosts.'${fqdn/./\\./}'" array "$name"
  servers+=("$name" "$fqdn" "OFF")
done

echo "✅ Setup complete! For manual updates to the server configuration, please edit $config!"

if [ "${#servers[@]}" -gt "0" ]; then
  if whiptail --title "Set Default Host?" --yesno "Do you want to set a new default host?" 10 30; then
    toml_edit "$config" set "servers.try" array "${whiptail --title "Set Default Host?" --radiolist "Choose a default host:" 18 70 "$(( ${#servers[@]} / 3 ))" "${servers[@]}" 3>&1 1>&2 2>&3}"
  systemctl restart velocity
fi
