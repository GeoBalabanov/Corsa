# 🎧 Corsa – Minimal Car Audio Experience

**Corsa** is a SwiftUI-based car audio app designed to make music control effortless and distraction-free while driving.  
The app connects to **Spotify**, **Apple Music**, or **YouTube Music**, and gives the driver a simple interface: large buttons, clean design, and optional voice control — so you can *“just listen,”* and Corsa handles the rest.

> Built with **SwiftUI** · Optional **Firebase** · iOS **Speech** framework  
> **Screens:** Georgi (Landing / Registration / Playlist) · Zhan (Player / Voice / Final Polish)

---

## 🚗 Concept

Corsa was born from a simple thought: *Why do car audio apps feel so cluttered and unsafe?*  
Drivers don’t need endless menus — they just need their music, instantly.

With that in mind, we designed Corsa to strip everything down to the essentials.  
No scrolling, no swiping — just one-touch (or no-touch) access to your playlists.  
The visual language is dark, calm, and elegant, inspired by luxury car interiors and night drives.

---

## 💡 Core Idea

Corsa connects to your existing music service and offers a minimal interface made for driving.  
Once you’re connected, you can simply say “play,” “pause,” or “next,” or use big tactile buttons.  

When the app detects motion or Bluetooth connection to your car, it can automatically switch to a **Drive Mode** — limiting visual distractions and relying more on sound and voice feedback.

---

## 🧠 Research & Inspiration

We started by looking into what makes a **good, safe UI** for driving apps —  
most current interfaces overload users with small icons and too many options.  

Through our research and competitor analysis, we focused on three main design principles:

1. **Minimal interaction** — fewer taps, more automation  
2. **Auditory feedback** — the car should *speak back*, not just show visuals  
3. **Clarity** — high contrast, large typography, calm animations

We also looked at **Apple CarPlay**, **Spotify Auto**, and **Android Auto** for inspiration, using them as benchmarks for safety and usability.

---

## 🎨 Design Direction

All visuals were created in **Figma**, from low-fidelity wireframes to full high-fidelity prototypes.  
The color palette reflects Corsa’s personality: **deep purples, dark gradients, and soft neon tones** — giving the feeling of a night drive.

We worked together on design — I focused on the **landing, registration, and playlist pages**, while Zhan built the **player and voice control** screens.  
Figma made collaboration easy, allowing us to comment, edit, and test designs together before coding in SwiftUI.

---

## 🔧 Development

Corsa is built fully in **SwiftUI**, following Apple’s Human Interface Guidelines for accessibility and motion safety.

**My part:**  
- LandingView  
- RegistrationView  

**Zhan’s part:**  
- PlaylistChoiceView 
- Voice control & car-ready mode  

We worked on separate **GitLab branches** to avoid conflicts, then merged everything into `main` after review.  
Version control helped us stay organized and keep the project stable at every stage.

---

## 📋 Features

✅ Choose your music provider (Spotify / Apple Music / YouTube Music)  
✅ Paste or connect your music profile  
✅ Browse and select playlists from your account  
✅ Simple, high-contrast UI for safe driving  
✅ Voice command integration *(planned)*  
✅ Auto Drive Mode *(planned)*  

---

## 🧩 Workflow

We followed a **Scrum-inspired workflow**, breaking the project into short, focused phases:  

1. **Research** – surveys, competitor analysis, and UI safety review  
2. **Ideation** – defining core features and app flow  
3. **Design** – Figma wireframes and high-fidelity prototype  
4. **Development** – building in Xcode with SwiftUI  
5. **Testing** – teacher feedback and peer testing  

Each phase ended with feedback sessions, helping us refine the app step by step.

---

## 🧭 Research Question

**Main Question:**  
> *How can we design a minimal, voice-first car audio interface that allows safe and seamless control while driving?*

**Sub-questions:**  
- What makes a good, safe UI for in-car use?  
- What is the most minimal interface that still provides full control?  
- How can sound and motion replace visual or touch interaction?

---

## 👥 Team

**Georgi Balabanov** – UI/UX Design, SwiftUI Development (Landing / Registration / Playlist)  
**Zhan Hristov** – Development, Voice Features, Player Interface  

---

## 🧰 Tools

- Xcode + SwiftUI  
- Figma  
- GitLab  
- Trello (project organization)  
- Notion (documentation & planning)

---

## 🧠 Technical Overview

Corsa is built entirely in **SwiftUI**, using a simple and modular architecture that makes each screen independent but connected through a shared navigation flow.  
The app focuses on **safety, simplicity, and performance**, keeping the UI reactive and lightweight for real-time use while driving.


### 🪄 How It Works

1. **LandingView** – the app opens with a minimal intro screen and a gradient background.  
   Users tap “To register” to move into the next step.  

2. **RegistrationView** – users choose their preferred platform (**Spotify / Apple Music / YouTube Music**)  
   and paste their profile or playlist link. In future versions, this connects via the APIs.

3. **PlaylistChoiceView** – after login, the app shows available playlists (currently sample data).  
   This screen will later load dynamic playlists from the selected music provider.

4. **ReadyView & PlayerView** – once the user selects a playlist, the app transitions to the player.  
   The player has only three large buttons: **Previous**, **Play/Pause**, and **Next**, plus optional voice control.

### 🗣 Voice Integration

Voice features are built using Apple’s **Speech framework**.  
The app listens for simple commands such as *“Play,” “Pause,” “Next,”* and *“Stop.”*  
In future versions, a “Hey Corsa” wake word will be added using **VoiceKit** or background speech recognition.

### 🔊 APIs & Data Flow

- **Spotify Web API** → fetches user playlists and track data via OAuth (planned).  
- **Apple MusicKit** → fetches library data and integrates with user tokens (planned).  
- **YouTube Data API** → retrieves playlists and video metadata (planned).  
- **Firebase** → handles optional authentication and user preferences storage.

All views communicate through lightweight models that store user data in memory during the session.  
This keeps the app fast and avoids unnecessary network requests while driving.

---





© 2025 Georgi Balabanov & Zhan Hristov – University Project

