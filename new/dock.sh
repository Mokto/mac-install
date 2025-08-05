#!/bin/bash

# Define desired Dock layout
DOCK_APPS=(
  "/Applications/Zed.app"
  "/System/Applications/System Settings.app"
  "/Applications/Slack.app"
  "/Applications/Arc.app"
  "/Applications/1Password.app"
  "/Applications/ChatGPT.app"
  "/Applications/Kreya.app"
  "/Applications/Warp.app"
)

DOCK_FOLDERS=(
  "$HOME/Downloads"
)

# Remove unwanted default apps if they exist
UNWANTED_APPS=(
  "Mail"
  "Messages"
  "Safari"
  "Launchpad"
  "Maps"
  "Photos"
  "FaceTime"
  "Calendar"
  "Contacts"
  "Reminders"
  "Freeform"
  "TV"
  "Music"
  "Google Chrome"
  "Terminal"
)


CHANGED=0


for app in "${UNWANTED_APPS[@]}"; do
  if dockutil --list | grep -q "$app"; then
    echo "Removing $app from Dock..."
    dockutil --remove "$app" --no-restart
    CHANGED=1
  fi
done

# Add desired apps if not already in Dock
for app in "${DOCK_APPS[@]}"; do
  if [ -e "$app" ] && ! dockutil --list | grep -Fq "$app"; then
    echo "Adding $app to Dock..."
    dockutil --add "$app" --no-restart
    CHANGED=1
  fi
done

# Add Downloads folder (if not already present)
for folder in "${DOCK_FOLDERS[@]}"; do
  if ! dockutil --list | grep -Fq "$folder"; then
    echo "Adding $folder to Dock..."
    dockutil --add "$folder" --view fan --display folder --sort dateadded --no-restart
    CHANGED=1
  fi
done

# Restart Dock if changes occurred
if [ "$CHANGED" -eq 1 ]; then
  echo "Applying Dock changes..."
  killall Dock
else
  echo "Dock already up to date. No changes made."
fi
