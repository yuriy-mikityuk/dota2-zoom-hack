# Training Zoom for macOS

A small native app for choosing camera distance in Hero Demo and local practice. It saves Dota config files and copies console commands. The camera changes when you execute the command in Dota, or press the optional in-game key. Moving the slider alone does not change the running game.

The app uses `dota_camera_distance`, a cheat-protected command provided by Dota. Hero Demo enables cheats itself. A local practice lobby must have cheats enabled by its host. The app does not enable cheats, patch game files or memory, open a network port, or require Accessibility permissions. It does not bypass restrictions on normal servers.

## Use

1. Open **Dota Training Zoom.app**. It detects Steam libraries, including games on external drives. If needed, select `dota 2 beta` or its `game` folder.
2. Choose a distance from 1134 to 2000 and press **Установить / сохранить зум**.
3. Start Hero Demo, or create a local practice lobby with cheats enabled. Open Dota's developer console and run `exec mac_training_zoom`.
4. To change the value later, save it in the app and run the same command again. The reset button selects 1200; save and apply it to reset the game camera.

The direct-command copy button also works without installing files. Enable the developer console in Dota's advanced settings if it is not already enabled, and use the console key assigned in your keyboard settings.

## Optional keys

After saving files, `exec mac_training_zoom_keys` assigns F6 (default distance, 1200), F7 (far distance, 2000), and F8 (apply the distance saved in the app). On some Mac keyboards you need Fn with these keys. This replaces any existing actions on F6/F7/F8, and Dota may save those bindings. The app never executes this setup command automatically. Restore previous actions through Dota's key settings if needed.

Only two files are written, under `game/dota/cfg/`:

- `mac_training_zoom.cfg`: saved distance and a query that prints the resulting value.
- `mac_training_zoom_keys.cfg`: optional key assignments.

Existing files without this app's marker are not overwritten. `autoexec.cfg`, user settings, Steam launch options, and game binaries are not edited. To remove the app's configuration, remove its two files and restore any keys you chose to assign. Restart Dota to clear session changes.

## Build

Requires macOS 13 or later, Xcode or Command Line Tools with Swift, and the native macOS Dota 2 installation. No external packages are needed.

```sh
bash macos/test.sh
bash macos/build.sh
```

The build creates an ad-hoc signed universal app for Apple Silicon and Intel and packages it as `macos/build/Dota Training Zoom.zip`. Extract the archive to use the app. It is not notarized. Signing happens in a temporary folder so cloud-folder metadata cannot interfere; the script prints that app's location too. The test script uses temporary fixture directories and does not change the installed game.

## Scope

This is a macOS companion for the training use case, with a different implementation from the original Windows overlay. Camera changes still follow the game's console restrictions. Some tutorial or custom maps may override their camera settings.
