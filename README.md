# Front Line

A lightweight offline 2D tactical strategy prototype built with Godot 4 for Android.

## Current features
- Main menu with continue and new campaign actions
- 15 connected territories with friendly, enemy, and neutral control
- Tap a friendly territory, then a connected territory to attack or transfer troops
- Enemy counterattacks and advances into neutral territories
- Turn-based supplies: owned territories generate resources and friendly troops recover
- Terrain combat modifiers: forests, rivers, and hills provide defensive advantages
- Capturing the Supply Depot increases income by 2 supplies per turn
- Reinforce a selected friendly territory by spending 3 supplies
- Automatic local save for turn, supplies, territory ownership, and troop counts
- Restartable campaign
- Offline gameplay; no server or internet permission required
- GitHub Actions workflow for exporting a debug Android APK artifact

## Controls
1. Tap **CONTINUE CAMPAIGN** to resume, or **NEW CAMPAIGN** to reset.
2. Tap a blue territory to select it.
3. Tap a connected red/grey territory to attack, or a connected blue territory to transfer troops.
4. Press **REINFORCE** with a blue territory selected to add two troop groups for 3 supplies.
5. Press **END TURN** to gain supplies, recover troops, and let the enemy act.
6. Capture the enemy headquarters to complete the mission.
7. Open **MENU** to pause and return to the main menu.

## Android build
Open the repository's **Actions** tab and select the latest **Build Android APK** workflow run. If the workflow succeeds, download FrontLine-Android-Debug.apk from the run's **Artifacts** section.

This is still a prototype, not a store-ready release. The Android export is being validated in CI; a successful import check alone does not mean the APK build has succeeded. The debug APK is not signed for Play Store release.
