# MANUgen IT guide

For IT support and technical staff who prepare a MANUgen pilot installation. This guide lists what the application needs and what it does. It is not a security audit.

## Summary

- Windows 10 or 11, 64-bit.
- One installer: MANUgen-setup.exe.
- Runs locally. No cloud service, no account, no telemetry.
- No Windows services, no PATH changes, no firewall rules, no file associations.
- The executables are not code-signed yet.
- Pilot version. No production support. Contact: juhani.kolehmainen@edu.savonia.fi.

## Before the pilot: checklist

| Item | What to prepare |
| --- | --- |
| Disk space | 6 GB free for the current functions (application, model server, one language model). Other models or special installations can need more. |
| Visual C++ runtime (x64) | Install it in advance: https://aka.ms/vc14/vc_redist.x64.exe. It needs administrator rights; the user cannot install it alone. |
| Downloads | The model setup downloads 1–5 GB from GitHub and Hugging Face. Allow the addresses below, or download the files yourself (see Language model setup). |
| Proxy | The model setup uses Windows curl.exe. It does not use the Windows proxy settings; it reads only the environment variables HTTPS_PROXY / HTTP_PROXY. |
| Scripts | Launchers are .cmd files. Hardware detection runs a JScript file with Windows Script Host (cscript) and WMI queries. Policies that block .cmd files or Windows Script Host stop these steps. |
| Unsigned files | SmartScreen shows "Windows protected your PC" for the downloaded installer. AppLocker, WDAC or the Defender ASR rule for low-prevalence executables can block the programs below. Allow them if needed. |
| Browser | Microsoft Edge or Google Chrome. MANUgen opens in an app window (--app). Another browser opens a normal tab. |
| Graphics driver | Up to date, for the graphics profiles. Vulkan support for AMD and Intel, NVIDIA driver for CUDA. |
| One user at a time | Ports 3000, 8080, 8083 and 8090 must be free. Two users running MANUgen on one computer at the same time is not supported. |

## Installation

| Option | Details |
| --- | --- |
| For one user | Default. No administrator rights needed. |
| For all users | Start the installer with Run as administrator. Otherwise Smart App Control may block the unsigned application. |
| Folder | C:\MANUgen by default. Can be changed. |
| Folder permissions | The folder inherits the permissions of C:\. By default all local users can change files in it. The model setup also writes into this folder. |
| Silent install | Inno Setup switches: /VERYSILENT /SUPPRESSMSGBOXES /NORESTART, /CURRENTUSER or /ALLUSERS, /DIR="path". The Visual C++ check is skipped in silent mode. Not yet tested. |

The installer registers only the uninstaller. It adds Start menu shortcuts and a desktop shortcut.

## Programs that run

All programs run with the rights of the user who starts MANUgen. They start from the taskbar window "MANUgen" and stop when that window is closed. The browser window can be closed without stopping them.

| Program | Purpose | When it runs |
| --- | --- | --- |
| ticket-demo.exe | Application and user interface (port 3000) | While MANUgen runs |
| runtime\llama\llama-server.exe | Language model server (port 8080). Downloaded by the model setup. | While MANUgen runs |
| runtime\embedding\llama-server.exe | Embedding server for the knowledge base (port 8083) | While MANUgen runs |
| rag\rag-service.exe | Knowledge base service (port 8090) | While MANUgen runs |
| markitdown\markitdown-cli.exe | Converts Office files attached in chat to text | For a moment, on each upload |
| ticket-export.exe | Writes an approved ticket to an Excel register | Only when Excel export is set up |
| cscript.exe, curl.exe, tar.exe | Windows tools used by hardware detection and model setup | Only during model setup |

## Language model setup

The language model is not in the installer. The user runs Mallin asennus after installation.

1. Hardware detection reads memory and graphics cards (WMI).
2. It recommends a model profile from profiles.json.
3. After the user agrees, it downloads the llama.cpp server and the model.
4. It updates settings.json. The previous file is kept as settings.json.bak.

The setup is interactive. For central deployment or a computer without internet access, copy the runtime\llama and models folders yourself and run tools\setup\settings_change.cmd SERVER WORKFLOW. The download links are in LUEMINUT.txt and tools\hardware-probe\profiles.json.

Downloads come from:

| Address | Content |
| --- | --- |
| github.com, release-assets.githubusercontent.com | llama.cpp model server (zip) |
| huggingface.co and its download servers (*.hf.co) | Model files, 1–5 GB |
| aka.ms, download.visualstudio.microsoft.com | Visual C++ runtime, only if missing |

Downloaded zip files stay in the downloads folder. They can be deleted after the setup.

## Network

All parts listen on 127.0.0.1 only. Nothing is reachable from other computers. The application makes no connections to the internet while it runs.

| Port | Part |
| --- | --- |
| 3000 | Application and user interface |
| 8080 | Language model server |
| 8083 | Embedding server (knowledge base) |
| 8090 | Knowledge base service |

Network use is possible with settings: listen address and auth mode "none". There is no login then, and all users share one identity. Windows Firewall then asks to allow ticket-demo.exe; allowing it needs administrator rights. Use it only in a restricted network. An installation on a server in a closed network is available as a separate assisted service.

## Load

The language model uses the processor or graphics card fully while it writes an answer. The model stays in memory (RAM or video memory) as long as MANUgen runs. Loading the model at start takes about a minute.

## Data

| Data | Location | Contains user text |
| --- | --- | --- |
| Settings | settings.json, workflows.json | No |
| Approved tickets | tickets folder (one JSON file per ticket) | Yes |
| Excel register | Only when export is set up; the file named in settings.json | Yes |
| Logs | logs folder | Possibly. The model server log is verbose; treat it as user data. |
| Knowledge base | rag\initial_index\index.sqlite. Empty in the installer. The customer builds it from own documents (rag\OHJE-FI.md). | Your own documents |
| Downloaded model and server | models, runtime\llama, downloads | No |
| Chat history and UI settings | The browser's own storage (per browser profile) | Yes |
| Documents attached in chat | Memory only. Removed after 4 hours unused or at restart. | Yes |

Paths are relative to the installation folder. Files are stored as plain files; they are not encrypted. Back them up and delete them according to your own practice.

## Update and uninstall

- An update replaces the application files.
- It keeps settings.json, workflows.json, the knowledge base, tickets, logs, models and the model server.
- Uninstall removes the installed files. Settings, data, models and logs stay. Delete the folder to remove them.

## Requirements

| Profile | Memory | Graphics | Tested |
| --- | --- | --- | --- |
| Gemma 4 E4B, NVIDIA | 7 GiB | NVIDIA, 3.5 GiB video memory | Yes, with an earlier llama.cpp build |
| Gemma 4 E4B, Vulkan | 28 GiB | Any, 2.5 GiB video memory | Yes, with an earlier llama.cpp build |
| Gemma 4 E2B, Vulkan | 14 GiB | Any, 1.5 GiB video memory | Yes, with an earlier llama.cpp build |
| Gemma 4 E4B, processor only | 28 GiB | None | No |
| Gemma 4 E2B, processor only | 14 GiB | None | No |
| Gemma 3 1B, Vulkan | 7 GiB | Any, 1.5 GiB video memory | Yes, with an earlier llama.cpp build |
| Gemma 3 1B, processor only | 7 GiB | None | No |

Memory means memory available to Windows. Exact values and test status are in tools\hardware-probe\profiles.json.

## Security notes

- The executables are not code-signed. SmartScreen, Smart App Control or application control policies can block them. Microsoft Defender may delay the first start of a new version.
- The model setup downloads executables from the llama.cpp GitHub releases. They are not signed either.
- No HTTP headers, passwords or keys are written to files.
- The language model can be wrong. A person checks and approves every ticket.

## Verification

Each release lists MANUgen-setup.exe with its SHA-256 checksum and MANIFEST.json. The manifest lists every installed file with version and checksum.

## Problems

Send tools\hardware-probe\results\report.txt and the newest file in the logs folder to juhani.kolehmainen@edu.savonia.fi.
