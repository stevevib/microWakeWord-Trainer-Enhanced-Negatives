# microWakeWord-Trainer-Enhanced-Negatives

This repository is a **fork** of the original [microWakeWord-Trainer-Nvidia-Docker](https://github.com) by **TaterTotterson**.

### 🌟 What’s New in this Fork
The primary goal of this version is to reduce **false positives** by introducing **Custom Negative Training**.

*   **Phonetic "Sounds-Like" Training:** You can now provide a list of phrases that sound similar to your wake word (e.g., "Jarrett" for "Jarvis"). The trainer will treat these as high-priority negative samples.
*   **Reduced False Triggers:** By specifically training the model on what *not* to trigger on, real-world accuracy is significantly improved in noisy environments or during TV/conversation playback.

# Wake Word Training Pipeline

## How it Works
The process uses a library of wake word "sound-alike" phrases which are converted into `.wav` files using the **Kokoro Text-to-Speech** engine. This pipeline utilizes the [remsky/Kokoro-FastAPI](https://github.com/remsky/Kokoro-FastAPI/tree/master) implementation for high-speed generation. 

The `generate_negative_training_phrases.ps1` PowerShell script manages the list of phonetic variants and creates a diverse dataset by iterating through multiple voices, speeds, and environmental filters.

### 1. Clean Samples
Initially, the script generates high-fidelity baseline versions of each phrase using a matrix of parameters:
* **Multiple Voices:** `af_sarah`, `af_nicole`, and `am_adam`.
* **Variable Speeds:** 0.9x, 1.0x, and 1.1x.

### 2. Augmented Samples
To harden the model against real-world false positives, the script uses **FFmpeg** to create augmented copies of the clean samples. These filters simulate how phrases sound when distorted by hardware, distance, or ambient environments:

* **Near-Field Profile:** Applies frequency isolation (120Hz–6000Hz) to mimic standard microphone capture.
* **Media Playback Simulation:** Uses heavy compression and narrow-band filtering (200Hz–3000Hz) to simulate voices coming from a TV or radio.
* **Digital Lo-Fi:** Downsamples audio to 8kHz with 8-bit log-mode bit-crushing to simulate low-bandwidth digital streams or budget hardware.
* **Distanced/Spatial Audio:** Uses aggressive muffling (2500Hz low-pass) and echo delay to simulate a trigger occurring in a separate room or at a distance.

---

## Manual Audio Hardening
We can optionally add short segments of recorded problematic audio to further harden negative training. 

### Typical Workflow:
1. **Identify the Trigger:** While watching or listening to streamed content, note instances where the device reacted incorrectly to a wake word.
2. **Locate the Timestamp:** Note the playback time code and skip back several seconds before the triggering audio.
3. **Record the Clip:** Using a recording device (smartphone, tablet, PC, etc.), capture a short audio clip consisting of 1–2 seconds *before* the event and 1–2 seconds *after* the event.
4. **Save & Deploy:** Audio should be saved as a **.wav** and included in the `C:\microww\noise` folder.

## System Requirements
The training pipeline and data augmentation scripts are optimized for **Windows 11** using **WSL2 (Ubuntu)**. While training can run on a variety of hardware, the specifications below are best guess estimates.  The biggest obstacle to getting the trainer to run reliably is available RAM.

### **The "Step 500" Memory Wall**
In testing on an **Intel Core Ultra 7 265** with **32GB RAM** (CPU-only mode), the trainer would consistently crash around training step 500 when using default WSL settings. These crashes provided no useful information in the standard logs.

If your trainer stops unexpectedly, you can verify if the process was terminated by the system's "Out of Memory" (OOM) killer by running this in PowerShell:

```powershell
# Returns true if killed due to OOM error
docker inspect microwakeword --format='{{.State.OOMKilled}}'
```

### **Hardware Specifications**

| Feature | Minimum Requirement | Recommended |
| :--- | :--- | :--- |
| **CPU Class** | Intel i5 (12th Gen+) | **Intel Core Ultra 7 / i7 (14th Gen+)** |
| **System RAM** | 16 GB | **32 GB** |
| **NVIDIA GPU** | Not Required | RTX 3060+ (For CUDA-accelerated training) |
| **Storage** | 50 GB Free SSD Space | 100 GB+ NVMe SSD |

### **WSL2 Configuration (Critical)**
To match the tested environment and prevent out-of-memory (OOM) errors during heavy dataset augmentation, it is recommended to allow WSL2 to utilize a significant portion of system memory.

**Tested Environment:**
* **Host OS:** Windows 11 Pro
* **CPU:** Intel Core Ultra 7 265 (using Integrated Graphics)
* **GPU Mode:** CPU Only (Intel iGPUs are not natively supported by CUDA-based frameworks)
* **RAM:** 32GB (with 24GB allocated to WSL2)

#### **How to Configure Memory Allocation:**
If you have 32GB of RAM, create or edit the `.wslconfig` file in your Windows user profile folder (`%USERPROFILE%\.wslconfig`) with the settings below.  On my system in CPU only mode, the trainer would crash with anything less than 24GB allocated.

```ini
[wsl2]
memory=24GB  # Limits VM memory in WSL2
guiApplications=false
```

> **NOTE:** You can monitor memory usage by running the watch_memory.ps1 script in a separate PowerShell window while the trainer is running:

```powershell
```

## Software Dependencies

To run the full generation and training pipeline, the following software must be installed and configured in your environment.

### **Windows Host Environment**
These tools are required for the initial data generation and orchestration via PowerShell.

* **[PowerShell 7+](https://github.com/PowerShell/PowerShell):** Required for `generate_negative_training_phrases.ps1`. Note that Windows PowerShell 5.1 may encounter compatibility issues with certain path handling.
* **[FFmpeg](https://ffmpeg.org/download.html):** Must be added to your Windows System PATH. This is used for all audio augmentation (distortion, compression, echo).
* **[Docker Desktop](https://www.docker.com/products/docker-desktop/):** Required to host the Kokoro TTS engine. Ensure "Use the WSL 2 based engine" is enabled in settings.

### **WSL2 (Ubuntu/Linux) Environment**
The actual model training and weight optimization occur within the WSL2 instance.

* **Python 3.10+:** The core language for the Micro Wake Word training scripts.
* **Pip & Virtualenv:** It is highly recommended to run the training within a dedicated Python virtual environment.
* **Build Essentials:** (Optional but recommended) `sudo apt install build-essential` to ensure C-based Python dependencies compile correctly.

Before installing the training package, prepare your Ubuntu environment with these core system tools:
```bash
# Update and install system-level foundations
sudo apt update && sudo apt install -y \
    python3.10 \
    python3-pip \
    python3-venv \
    build-essential \
    ffmpeg
```

### **TTS Engine Setup**
The pipeline relies on a local instance of the Kokoro TTS engine to avoid cloud latency and costs.
1.  **Repository:** [remsky/Kokoro-FastAPI](https://github.com/remsky/Kokoro-FastAPI)
2.  **Deployment:** Run via Docker container.
3.  **Endpoint:** Ensure the container is accessible at `http://localhost:8880` (or update the URI in the PowerShell script).

---

### **Quick Install Check**
You can verify your environment by running these commands in a terminal:

```powershell
# Check PowerShell version
$PSVersionTable.PSVersion

# Check FFmpeg
ffmpeg -version

# Check Docker
docker info
```

## Assumptions:
The included scripts assume the following directory structure

**How to use:** Coming soon

## Performance:

```text
   Training complete!
   Full log: /data/output/2026-03-26-14-59-34-hey_lexxy-50000-40000/logs/training.log
Name:     Hey Lexxy
Model:    /data/output/2026-03-26-14-59-34-hey_lexxy-50000-40000/hey_lexxy.tflite
Metadata: /data/output/2026-03-26-14-59-34-hey_lexxy-50000-40000/hey_lexxy.json

================================================================================
                                      Training completed.  Elapsed time: 0:45:17
================================================================================

================================================================================
                            Training Summary

CPU: Intel(R) Core(TM) Ultra 7 265 (4 cores)  Memory: 24035 mb
GPU: N/A

                        Generate 50000 samples, 100/batch  Elapsed time: 0:00:00
                                    Augment 50000 samples  Elapsed time: 0:00:00
                                     40000 training steps  Elapsed time: 0:45:17
                          ======================================================
                                                    Total  Elapsed time: 0:45:17
================================================================================
```

---

<div align="center">
  <h1>🎙️ microWakeWord Nvidia Trainer & Recorder</h1>
  <img width="1002" height="593" alt="Screenshot 2026-01-18 at 8 13 35 AM" src="https://github.com/user-attachments/assets/e1411d8a-8638-4df8-992b-09a46c6e5ddc" />
</div>

Train **microWakeWord** detection models using a simple **web-based recorder + trainer UI**, packaged in a Docker container.

No Jupyter notebooks required. No manual cell execution. Just record your voice (optional) and train.

---

<img width="100" height="44" alt="unraid_logo_black-339076895" src="https://github.com/user-attachments/assets/87351bed-3321-4a43-924f-fecf2e4e700f" />

**microWakeWord_Trainer-Nvidia** is available in the **Unraid Community Apps** store.
Install directly from the Unraid App Store with a one-click template.

---

<img width="100" height="56" alt="unraid_logo_black-339076895" src="https://github.com/user-attachments/assets/bf959585-ae13-4b4d-ae62-4202a850d35a" />


### Pull the Docker Image

```bash
docker pull ghcr.io/tatertotterson/microwakeword:latest
```

---

### Run the Container

```bash
docker run -d \
  --gpus all \
  -p 8888:8888 \
  -v $(pwd):/data \
  ghcr.io/tatertotterson/microwakeword:latest
```

**What these flags do:**
- `--gpus all` → Enables GPU acceleration  
- `-p 8888:8888` → Exposes the Recorder + Trainer WebUI  
- `-v $(pwd):/data` → Persists all models, datasets, and cache  

---

### Open the Recorder WebUI

Open your browser and go to:

👉 **http://localhost:8888**

You’ll see the **microWakeWord Recorder & Trainer UI**.

---

## 🎤 Recording Voice Samples (Optional)

Personal voice recordings are **optional**.

- You may **record your own voice** for better accuracy  
- Or simply **click “Train” without recording anything**

If no recordings are present, training will proceed using **synthetic TTS samples only**.

### Remote systems (important)
If you are running this on a **remote PC / server**, browser-based recording will not work unless:
- You use a **reverse proxy** (HTTPS + mic permissions), **or**
- You access the UI via **localhost** on the same machine

Training itself works fine remotely — only recording requires local microphone access.

---

### 🎙️ Recording Flow

1. Enter your wake word
2. Test pronunciation with **Test TTS**
3. Choose:
   - Number of speakers (e.g. family members)
   - Takes per speaker (default: 10)
4. Click **Begin recording**
5. Speak naturally — recording:
   - Starts when you talk
   - Stops automatically after silence
6. Repeat for each speaker

Files are saved automatically to:

```
personal_samples/
  speaker01_take01.wav
  speaker01_take02.wav
  speaker02_take01.wav
  ...
```

---

## 🧠 Training Behavior (Important Notes)

### ⏬ First training run
The **first time you click Train**, the system will download **large training datasets** (background noise, speech corpora, etc.).

- This can take **several minutes**
- This happens **only once**
- Data is cached inside `/data`

You **will NOT need to download these again** unless you delete `/data`.

---

### 🔁 Re-training is safe and incremental

- You can train **multiple wake words** back-to-back
- You do **NOT** need to clear any folders between runs
- Old models are preserved in timestamped output directories
- All required cleanup and reuse logic is handled automatically

---

## 📦 Output Files

When training completes, you’ll get:
- `<wake_word>.tflite` – quantized streaming model  
- `<wake_word>.json` – ESPHome-compatible metadata  

Both are saved under:

```text
/data/output/
```

Each run is placed in its own timestamped folder.

---

## 🎤 Optional: Personal Voice Samples (Advanced)

If you record personal samples:
- They are automatically augmented
- They are **up-weighted during training**
- This significantly improves real-world accuracy

No configuration required — detection is automatic.

---

## 🔄 Resetting Everything (Optional)

If you want a **completely clean slate**:

Delete the /data folder

Then restart the container.

⚠️ This will:
- Remove cached datasets
- Require re-downloading training data
- Delete trained models

---

## 🙌 Credits

Built on top of the excellent  
**https://github.com/kahrendt/microWakeWord**

Huge thanks to the original authors ❤️
