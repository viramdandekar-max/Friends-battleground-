OFFLINE SQUAD DEMO - GODOT 4 SOURCE PROJECT

This is a small prototype, NOT the complete 600-650 MB game or an APK.

Implemented:
- 3D arena, buildings, 10 visual tower markers
- Player movement via keyboard and on-screen D-pad
- Fire button, basic auto-target hit mechanic
- 12 respawning enemy bots that move toward player
- 3 companion bots that follow or attack
- Touch command menu with 8 commands (FOLLOW, ATTACK and HOLD change behavior; others show command status)
- Health, eliminations, respawn

Not implemented yet: APK, LAN multiplayer, full recall, 60-player simulation, real weapons and loot,
70 RP levels, cosmetics/crates, HD textures, sophisticated AI, voice recognition, online play.

To run:
1. Install Godot Engine 4.2 or later on a computer.
2. Import project.godot, open main.tscn, press F6 or Run Project.
3. For Android APK, install Godot Android export templates, Android SDK and Java,
   configure export preset and build. This environment does not have these tools.

This is an original prototype; no BGMI assets or trademarks are used.

Cloud build: Upload the contents of this folder to a GitHub repository, then open
Actions > Build Android APK > Run workflow. Download OfflineSquadDemo-APK from
the completed run. This workflow has not been run or verified here.
