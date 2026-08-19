# RTV Scripts – Prison Doctor

A standalone **prison doctor** resource for FiveM, built for **RTV Scripts**.

Players can check in at a prison doctor, get automatically moved to a free bed, treated for a set duration, and then **automatically revived and stand up**. The script supports **multiple beds**, **ox_lib UI**, optional **ox_target** interaction, and an **EMS on-duty check** so players must use real EMS if medics are online.

---

## Features

- 🔒 **Standalone** – No ESX/QBCore dependency required for core functionality.
- 🛌 **Multiple beds** – Players are assigned to the first available bed; no overlap.
- 🎬 **Animations**
  - Clipboard / notepad animation when checking in.
  - Optional bed “lay down” animation (only if player is alive).
  - Get-up animation after treatment.
- 🎚 **Treatment timer**
  - Configurable duration.
  - After the timer, player is revived via **tk_ambulancejob** and automatically stands up.
- 🧠 **EMS on-duty check** (optional)
  - Prevents using the prison doctor if EMS are on duty.
  - Supports ESX, QBCore, or a custom export.
- 🎯 **Flexible interaction**
  - `ox_lib` TextUI + E key.
  - Or `ox_target` 3rd-eye interaction zone.

---

## Requirements

**Required:**

- [`ox_lib`](https://github.com/overextended/ox_lib)
- [`tk_ambulancejob`](your-ambulance-job-repo-here)  
  - Must expose a **server-side export**:
    ```lua
    exports.tk_ambulancejob:revive(playerId)
    ```

**Optional (but recommended):**

- [`ox_target`](https://github.com/overextended/ox_target) – if you want 3rd-eye check-in.
- `es_extended` (ESX) – if you want ESX-based EMS on-duty count.
- `qb-core` – if you want QBCore-based EMS on-duty count.

---

## Installation

1. **Download / clone** this resource into your server resources folder:
   ```text
   resources/
     [rtv]/
       rtv_prison_doctor/
         fxmanifest.lua
         config.lua
         client.lua
         server.lua
         README.md

ensure ox_lib
ensure ox_target        # required if you use ox_target mode
ensure tk_ambulancejob

ensure rtv_prison_doctor

## How it works (flow)

1. Player goes to the check-in point (TextUI or ox_target).
2. Presses E (TextUI) or selects Check in (ox_target).

3. Script plays a clipboard animation and sends a request to the server.

4. Server:
- Checks if EMS are on duty (optional).
- Finds a free bed (or denies if none).
- Assigns the bed to the player and tells the client where to go.

5. Client:
- Fades out (optional).
- Teleports the player onto the bed and sets heading.
- Softly attempts bed animation if the player is alive.
- Fades back in.

6. After Config.TreatmentTime:
- Server calls exports.tk_ambulancejob:revive(src).
- Frees the bed.
- Tells the client to finish treatment.

7. Client:
- Stops bed animation.
- Plays get-up animation.
- Unlocks controls.

Enjoy, and feel free to tweak texts, coords and animations to match your prison interior and RP style.