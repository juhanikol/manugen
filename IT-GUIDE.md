# MANUgen IT guide

For IT support and technical staff who decide how MANUgen is installed.

## Summary

- Windows 10 or 11, 64-bit.
- One installer: MANUgen-setup.exe.
- Runs locally. No cloud service, no account, no telemetry.
- No Windows services, no PATH changes, no firewall rules, no file associations.
- The executables are not code-signed yet.

## Installation

| Option | Details |
| --- | --- |
| For one user | Default. No administrator rights needed. |
| For all users | Start the installer with Run as administrator. Otherwise Smart App Control may block the unsigned application. |
| Folder | C:\MANUgen by default. Can be changed. |
| Silent install | Inno Setup switches: /VERYSILENT /CURRENTUSER or /ALLUSERS, /DIR="path". Not yet tested. |

The installer registers only the uninstaller. It adds Start menu shortcuts and a desktop shortcut.

If the Microsoft Visual C++ runtime (x64) is missing, the installer offers the download link. Installing it needs administrator rights.

## Language model setup

The language model is not in the installer. The user runs Mallin asennus after installation.

1. Hardware detection reads memory and graphics cards (WMI).
2. It recommends a model profile from profiles.json.
3. After the user agrees, it downloads the llama.cpp server and the model.
4. It updates settings.json. The previous file is kept as settings.json.bak.

The setup is interactive. For central deployment, copy the runtime\llama and models folders yourself and run tools\setup\settings_change.cmd SERVER WORKFLOW.

Downloads come from:

- github.com (llama.cpp releases)
- huggingface.co (model files, 1–5 GB)
- aka.ms (Visual C++ runtime, only if missing)

## Network

All parts listen on 127.0.0.1 only. Nothing is reachable from other computers.

| Port | Part |
| --- | --- |
| 3000 | Application and user interface |
| 8080 | Language model server |
| 8083 | Embedding server (knowledge base) |
| 8090 | Knowledge base service |

The ports must be free. Two users running MANUgen on the same computer at the same time is not supported.

Network use is possible with settings: listen address and auth mode "none". There is no login then. Use it only in a restricted network, and add a firewall rule.

## Data

| Data | Location |
| --- | --- |
| Settings | settings.json, workflows.json |
| Approved tickets | tickets folder |
| Logs | logs folder |
| Knowledge base | rag\initial_index\index.sqlite. Empty in the installer. The customer builds it from own documents (rag\OHJE-FI.md). |
| Downloaded model and server | models, runtime\llama |
| Chat history and UI settings | The browser's own storage (per browser profile) |
| Excel register | Only when export is configured |

Paths are relative to the installation folder. Documents attached in chat are kept in memory only.

## Update and uninstall

- An update replaces the application files.
- It keeps settings.json, workflows.json, the knowledge base, tickets, logs, models and the model server.
- Uninstall removes the installed files. Settings, data, models and logs stay. Delete the folder to remove them.

## Requirements

| Profile | Memory | Graphics |
| --- | --- | --- |
| Gemma 4 E4B, NVIDIA | 7 GiB | NVIDIA, 3.5 GiB video memory |
| Gemma 4 E4B, Vulkan | 28 GiB | Any, 2.5 GiB video memory |
| Gemma 4 E2B, Vulkan | 14 GiB | Any, 1.5 GiB video memory |
| Gemma 4 E4B, processor only | 28 GiB | None |
| Gemma 4 E2B, processor only | 14 GiB | None |
| Gemma 3 1B, Vulkan | 7 GiB | Any, 1.5 GiB video memory |
| Gemma 3 1B, processor only | 7 GiB | None |

Memory means memory available to Windows. Exact values and test status are in tools\hardware-probe\profiles.json.

Also needed: Microsoft Edge or Google Chrome, and an up-to-date graphics driver for the graphics profiles.

## Security notes

- The executables are not code-signed. Smart App Control can block them. Microsoft Defender may delay the first start of a new version.
- The model setup downloads executables from the llama.cpp GitHub releases.
- No HTTP headers, passwords or keys are written to files.

## Verification

Each release lists MANUgen-setup.exe with its SHA-256 checksum and MANIFEST.json. The manifest lists every installed file with version and checksum.
