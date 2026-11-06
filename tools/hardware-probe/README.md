# Device sniffer

Double-click `device_sniffer.bat`. No input INI or build step. Option `/nopause`
(used by `tools\setup\MALLIN-ASENNUS.cmd`).
Keep `hardware-query.js` and `profiles.json` beside the BAT.
The script uses Windows `cscript` and WMI, not Node.js or PowerShell.
Windows Script Host must be enabled by the machine's policy.

Outputs: `results/report.txt` (short summary), `results/hardware.ini` (detected
facts), connected/disconnected device lists and `errors.txt`, and for the model
setup `results/selection.cmd` (profile, backend, workflow, GPU name as `set`
lines) and `results/downloads.txt` (`runtime URL` and `model URL` lines). Each
run replaces these latest-result files. No input hardware file is read.

Requested WMI/PCI property lists are defined once, in BAT variables.
All commands use PATH. Missing properties stay unknown, never default hardware.

`profiles.json` is a small profile catalog. The first profile whose limits match
is recommended: `ramGiB` is the minimum Windows-visible memory (not rounded
installed capacity or free RAM; 14 GiB covers a nominal 16 GiB machine), `gpu`
is the vendor of a working GPU (`NVIDIA`, `AMD`, `Intel`, from the PCI vendor
id), `any`, or `null` for a CPU-only profile, and `vramGiB` the minimum memory
of that GPU. An unknown amount never matches. The catalog also holds the
llama.cpp release and model download links, the workflow and the llama-server
arguments. After a change run `node ticket-demo/packaging/profile-servers.mjs`:
it writes one settings server per profile (and per device name for GPU profiles)
into `ticket-demo/packaging/settings.distribution.json`; the packaging test fails
while the two differ. WSH JScript has no JSON object, so the script reads the
catalog as a JSON object literal.

RAM speed is printed as the raw firmware/WMI value. WMI documents MHz but DDR
firmware may report transfer rate; the physical MHz clock is not inferred.
PCIe values describe the current and maximum link; idle state can reduce width
or speed. VRAM uses `HardwareInformation.qwMemorySize` matched through the GPU's
PnP driver key. The unreliable 32-bit WMI `AdapterRAM` value is retained only in
the raw INI, never used to select a GPU model. If the registry value is missing,
VRAM is unknown. UMA, exact VRAM type and CUDA/Vulkan capability are not verified
by this script; `MALLIN-ASENNUS.cmd` checks that llama-server lists the GPU.

Model speed and answer quality are not measured. This script changes no
settings, downloads nothing and needs no administrator rights.
