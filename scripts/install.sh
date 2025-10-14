#!/bash/bin

set -euo pipefail

# --- SystemD Checker ---
if [ ! -d "/etc/systemd/system" ]; then
  echo "Please install systemd for service management!"
  exit 1
fi

# --- File System Setup
URL="https://raw.githubusercontent.com/mk5912/velocity_service_unix/refs/head/main/scripts"

ROOT_DIR="/etc/velocity"

if [ ! -d $ROOT_DIR ]; then
  mkdir $ROOT_DIR
fi

wget -o /etc/velocity/update_velocity.sh $URL/update_velocity.sh

wget -o /etc/systemd/system/velocity.service $URL/velocity.service

systemctl daemon-reload

apt install curl whiptail jq -y


# --- Helper: get download urls for ViaVersion plugins ---
get_github_release() {
  PROJECT=$1
  SLUG=$2
  local URL=$(curl -s https://api.github.com/repos/$PROJECT/$SLUG/releases/latest|jq -r ".assets[].browser_download_url")
  echo "$URL"
}

# Velocity Proxy Plugin Installer Wizard with progress bar
# Requirements: whiptail, curl, jq (optional)

PLUGINS_DIR="$ROOT_DIR/plugins"
if [ ! -d $PLUGINS_DIR ]; then
  mkdir -p "$PLUGINS_DIR"
fi

# --- Velocity Plugin URLs ---
declare -A VELOCITY_PLUGINS=(
  ["LuckPerms"]="https://download.luckperms.net/latest/velocity"
  ["ViaVersion"]="https://hangarcdn.papermc.io/plugins/ViaVersion/ViaVersion/versions/*/VELOCITY/ViaVersion-*.jar"
  ["ViaVersion"]=$(get_github_release "ViaVersion" "ViaVersion")
  ["ViaBackwards"]=$(get_github_release "ViaVersion" "ViaBackwards")
  ["ViaRewind"]=$(get_github_release "ViaVersion" "ViaRewind")
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

# --- Step 3: Download with progress bar ---
{
  COUNT=0
  TOTAL=$(echo "$CHOICES" | wc -w)

  for plugin in ${CHOICES//\"/}; do
    ((COUNT++))
    echo "XXX"
    echo "$(( (COUNT - 1) * 100 / TOTAL ))"
    echo "Downloading $plugin ($COUNT/$TOTAL)..."
    echo "XXX"

    URL="${VELOCITY_PLUGINS[$plugin]}"

    # Expand wildcard if present in URL
    if [[ "$URL" == *"*"* ]]; then
      URL=$(curl -s -L "${URL/\*/}" | grep -Eo "https?://[^ \"']+${plugin}[^ \"']+jar" | head -n1 || true)
    fi

    curl -L -s -o "${PLUGINS_DIR}/${plugin}.jar" "$URL"

  done
  echo "XXX"
  echo "100"
  echo "✅ Installation complete! Plugins saved in '${PLUGINS_DIR}/'."
  echo "XXX"
} | whiptail --title "Installing Plugins" --gauge "Preparing downloads..." 8 70 0

clear
echo "✨ All done! Velocity plugins installed in '${PLUGINS_DIR}/'."


systemctl enable velocity

systemctl start velocity
