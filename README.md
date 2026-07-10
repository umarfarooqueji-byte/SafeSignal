<div align="center">
  <img src="https://raw.githubusercontent.com/umarfarooque/safesignal/main/assets/images/logo.png" alt="SafeSignal Logo" width="120" height="120" />

  # SafeSignal 🛡️
  
  **AI-Powered Scam Detection App for India**

  <p>
    <img src="https://img.shields.io/badge/Flutter-02569B?style=for-the-badge&logo=flutter&logoColor=white" alt="Flutter" />
    <img src="https://img.shields.io/badge/Dart-0175C2?style=for-the-badge&logo=dart&logoColor=white" alt="Dart" />
    <img src="https://img.shields.io/badge/Supabase-3ECF8E?style=for-the-badge&logo=supabase&logoColor=white" alt="Supabase" />
  </p>

  <br />

  <table>
    <tr>
      <td align="center">
        <img src="https://img.shields.io/badge/Powered_by-Mesh_API-FF7A00?style=for-the-badge&logo=bolt&logoColor=white" alt="Powered by Mesh API" />
      </td>
    </tr>
    <tr>
      <td align="center">
        <b><i>"Empowering citizens against cyber fraud with Deep Heuristics & Mesh API AI."</i></b>
      </td>
    </tr>
  </table>
</div>

---

## 🚀 Features

### 1. SMS & Call Shield (Tier 1 & 2)
Scans incoming messages and links using an offline heuristic rules engine and escalated cloud AI verification via **Mesh API** and Grok AI.

### 2. Deep URL Sandbox (Tier 3)
A comprehensive visual scanner for links. Powered by Mesh API, it checks Google Safe Browsing, VirusTotal engines, Domain Age (RDAP), and URLHaus DB to give a precise risk score and detailed security breakdown.

### 3. App Spyware Audit
Scans installed apps for dangerous permission combinations (e.g., Hidden Camera + Internet + Admin Access) that identify stalkerware and data exfiltration threats.

### 4. Device Security Audit
Performs hardware-level checks (Root detection, Emulator detection, Developer Options) to ensure the physical integrity of the device.

### 5. Dark Web Email Breach Scanner
Checks if your email and passwords have been compromised in known corporate data breaches (like Canva, Zomato, etc.) and provides an AI-generated personalized security verdict.

---

## 🔒 Security & Privacy (Zero-Knowledge Architecture)
- **No PII Sent:** All personal identifiable information is SHA-256 hashed locally before reaching our servers or third-party APIs.
- **Offline First:** Tier 1 rules engine processes SMS and links 100% offline.

---

## 🛠️ Installation & Setup

1. **Clone the repository:**
   ```bash
   git clone https://github.com/your-username/safesignal.git
   cd safesignal
   ```

2. **Install Dependencies:**
   ```bash
   flutter pub get
   ```

3. **Environment Setup (.env):**
   Create a `.env` file in the root of the project. Do **not** commit this file to version control.
   ```env
   MESH_API_KEY=your_mesh_api_key_here
   GROK_API_KEY=your_grok_key_here
   SUPABASE_URL=your_supabase_url
   SUPABASE_ANON_KEY=your_supabase_anon_key
   ```

4. **Run the App:**
   ```bash
   flutter run
   ```

---

<div align="center">
  <sub>Built with ❤️ for a safer digital India. Powered by <b>Mesh API</b>.</sub>
</div>
