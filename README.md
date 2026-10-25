# Dota 2 Zoom Hack

For macOS Hero Demo and local practice, see [Training Zoom](macos/README.md). It uses Dota's built-in camera command through dedicated config files; the Windows memory patcher below is unchanged.

* **Overlay Window**: Transparent, click-through overlay rendered with DirectX 11 + ImGui.
* **Zoom Slider**: Interactive slider that changes the in-game camera zoom distance.
* **Pattern Scanning**: Finds camera zoom instruction inside `client.dll`.
* **Hotkeys**:

  * `INSERT` → Toggle overlay visibility.
  * `END` → Exit and restore original memory.

---

## 🛠️ Requirements

* Windows 10/11 (x64).
* Visual Studio 2022 (with Desktop development for C++).
* Windows 10/11 SDK.
* DirectX 11 SDK headers (already included in modern Windows SDK).
* [Dear ImGui](https://github.com/ocornut/imgui) with **Win32 + DX11 backends**.

---

## 📸 Preview

https://github.com/user-attachments/assets/15c4fe95-2ee0-4fb6-8585-d9ff64c7ac41

---
