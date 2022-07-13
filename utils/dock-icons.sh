#/bin/bash

dockutil --remove Launchpad.app
dockutil --remove Siri.app
dockutil --remove Safari.app
dockutil --remove Mail.app
dockutil --remove Contacts.app
dockutil --remove Calendar.app
dockutil --remove Reminders.app
dockutil --remove Maps.app
dockutil --remove Photos.app
dockutil --remove FaceTime.app
dockutil --remove iTunes.app
dockutil --remove App Store
dockutil --remove Podcasts.app
dockutil --remove TV.app
dockutil --remove Music.app
dockutil --remove Feedback Assistant
dockutil --remove Launchpad.app
dockutil --remove Messages.app
dockutil --remove Keynote.app


python utils/dock-icon-remove.py -r "/Applications/Numbers.app"
python utils/dock-icon-remove.py -r "/Applications/Pages.app"
python utils/dock-icon-remove.py -r "/Applications/Notes.app"


dockutil --add /Applications/Spotify.app
dockutil --add /Applications/Ferdium.app
dockutil --add /Applications/Visual Studio
dockutil --add /Applications/Slack.app
dockutil --add /Applications/Google Chrome
dockutil --add /Applications/Hyper.app
dockutil --add /Applications/Notion.app
