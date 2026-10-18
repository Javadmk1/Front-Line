# Front Line

A lightweight, offline 2D strategy game prototype made with Godot 4 for Android.

## Current gameplay
- 15 connected territories with friendly, enemy, and neutral control
- Tap a friendly territory, then a connected territory to attack or transfer troops
- Enemy counterattacks and advances into neutral territories
- End-turn supplies: owned territories generate resources and friendly troops recover
- Reinforce the selected friendly territory by spending 3 supplies
- Automatic local save of campaign turn, resources, territory ownership, and troop counts
- Restart button to begin a new campaign
- Offline play; no gameplay server or internet permission required

## Controls
1. Tap a blue territory to select it.
2. Tap a connected red/grey territory to attack or a connected blue territory to transfer troops.
3. Use **REINFORCE** while a blue territory is selected to add two troop groups.
4. Use **END TURN** to earn supplies and let the enemy act.
5. Capture the enemy headquarters to complete the mission.

## Build and status
GitHub Actions exports a debug Android APK and uploads it as a workflow artifact when the build succeeds. Open **Actions** and choose the latest **Build Android APK** run.

This remains a playable prototype under development, not a release-ready or store-signed APK. Test the latest build on an Android device before treating it as stable.
