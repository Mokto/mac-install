#/bin/bash

python utils/dock-icon-remove.py -r "/Applications/Launchpad.app"
python utils/dock-icon-remove.py -r "/Applications/Siri.app"
python utils/dock-icon-remove.py -r "/Applications/Safari.app"
python utils/dock-icon-remove.py -r "/Applications/Mail.app"
python utils/dock-icon-remove.py -r "/Applications/Contacts.app"
python utils/dock-icon-remove.py -r "/Applications/Calendar.app"
python utils/dock-icon-remove.py -r "/Applications/Reminders.app"
python utils/dock-icon-remove.py -r "/Applications/Maps.app"
python utils/dock-icon-remove.py -r "/Applications/Photos.app"
python utils/dock-icon-remove.py -r "/Applications/FaceTime.app"
python utils/dock-icon-remove.py -r "/Applications/iTunes.app"
python utils/dock-icon-remove.py -r "/Applications/App Store.app"
python utils/dock-icon-remove.py -r "/Applications/Podcasts.app"
python utils/dock-icon-remove.py -r "/Applications/TV.app"
python utils/dock-icon-remove.py -r "/Applications/Music.app"
python utils/dock-icon-remove.py -r "/Applications/Feedback Assistant.app"
python utils/dock-icon-remove.py -r "/Applications/Launchpad.app"
python utils/dock-icon-remove.py -r "/Applications/Messages.app"
python utils/dock-icon-remove.py -r "/Applications/Keynote.app"
python utils/dock-icon-remove.py -r "/Applications/Numbers.app"
python utils/dock-icon-remove.py -r "/Applications/Pages.app"
python utils/dock-icon-remove.py -r "/Applications/Notes.app"


defaults write com.apple.dock persistent-apps -array-add "<dict><key>tile-data</key><dict><key>file-data</key><dict><key>_CFURLString</key><string>/Applications/Spotify.app</string><key>_CFURLStringType</key><integer>0</integer></dict></dict></dict>"; killall Dock
defaults write com.apple.dock persistent-apps -array-add "<dict><key>tile-data</key><dict><key>file-data</key><dict><key>_CFURLString</key><string>/Applications/Ferdi.app</string><key>_CFURLStringType</key><integer>0</integer></dict></dict></dict>"; killall Dock
defaults write com.apple.dock persistent-apps -array-add "<dict><key>tile-data</key><dict><key>file-data</key><dict><key>_CFURLString</key><string>/Applications/Visual Studio Code.app</string><key>_CFURLStringType</key><integer>0</integer></dict></dict></dict>"; killall Dock
defaults write com.apple.dock persistent-apps -array-add "<dict><key>tile-data</key><dict><key>file-data</key><dict><key>_CFURLString</key><string>/Applications/Slack.app</string><key>_CFURLStringType</key><integer>0</integer></dict></dict></dict>"; killall Dock
defaults write com.apple.dock persistent-apps -array-add "<dict><key>tile-data</key><dict><key>file-data</key><dict><key>_CFURLString</key><string>/Applications/Google Chrome.app</string><key>_CFURLStringType</key><integer>0</integer></dict></dict></dict>"; killall Dock
defaults write com.apple.dock persistent-apps -array-add "<dict><key>tile-data</key><dict><key>file-data</key><dict><key>_CFURLString</key><string>/Applications/iTerm.app</string><key>_CFURLStringType</key><integer>0</integer></dict></dict></dict>"; killall Dock
defaults write com.apple.dock persistent-apps -array-add "<dict><key>tile-data</key><dict><key>file-data</key><dict><key>_CFURLString</key><string>/Applications/Notion.app</string><key>_CFURLStringType</key><integer>0</integer></dict></dict></dict>"; killall Dock
