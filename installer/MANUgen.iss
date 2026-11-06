; MANUgen installer (Inno Setup 6). It packs the complete distribution folder made by
;   npm --prefix ticket-demo run package -- --complete --runtime embedding=DIR --model ...multilingual-e5-small-q8_0.gguf
; Build:  ISCC distribution\installer\MANUgen.iss   ->  build-ticket-demo\installer\MANUgen-setup.exe
; Another source folder:  ISCC /DSrc="D:\path\to\package" distribution\installer\MANUgen.iss
;
; Registers only the uninstaller (and Start menu shortcuts). No services, PATH, firewall or file associations.
; Never change AppId: it links upgrades and the uninstaller to earlier installations.

#ifndef Src
  #define Src AddBackslash(SourcePath) + "..\..\build-ticket-demo\dist\Ticket Demo Complete"
#endif
#if !FileExists(Src + "\ticket-demo.exe") || !FileExists(Src + "\models\multilingual-e5-small-q8_0.gguf")
  #error The complete distribution (ticket-demo.exe and the E5 embedding model) is missing in Src. Build it first (PAKETOINTI.md).
#endif
; the version of ticket-demo.exe (set from ticket-demo/package.json by the package build)
#define AppVer GetVersionNumbersString(Src + "\ticket-demo.exe")

[Setup]
AppId={{E5DE7BEF-CD0F-48F1-9E12-B32854C23688}
AppName=MANUgen
AppVersion={#AppVer}
AppVerName=MANUgen {#AppVer}
AppPublisher=Juhani Kolehmainen
AppCopyright=Copyright (c) Juhani Kolehmainen 2026
VersionInfoVersion={#AppVer}
; own folder in the root of the system drive, for per-user and all-users installations alike
DefaultDirName={sd}\MANUgen
DefaultGroupName=MANUgen
DisableProgramGroupPage=yes
; per-user by default (no administrator rights); the user may choose an all-users installation instead
PrivilegesRequired=lowest
PrivilegesRequiredOverridesAllowed=dialog
UsedUserAreasWarning=no
ArchitecturesAllowed=x64compatible
ArchitecturesInstallIn64BitMode=x64compatible
MinVersion=10.0
LicenseFile={#Src}\LICENSE.txt
OutputDir={#SourcePath}..\..\build-ticket-demo\installer
; no version in the file name: the download link stays the same for every release
OutputBaseFilename=MANUgen-setup
Compression=lzma2/max
SolidCompression=yes
WizardStyle=modern
UninstallDisplayName=MANUgen
UninstallDisplayIcon={app}\ticket-demo.exe

[Languages]
Name: "fi"; MessagesFile: "compiler:Languages\Finnish.isl"
Name: "en"; MessagesFile: "compiler:Default.isl"

[Messages]
; Smart App Control (Windows 11) blocked the unsigned ticket-demo.exe after "all users" was chosen in this dialog
; from a non-elevated Setup; starting Setup with "Run as administrator" worked (tested 2026-11-05). Remove after code signing.
fi.PrivilegesRequiredOverrideText2=%1 voidaan asentaa vain sinun käyttöösi tai kaikille käyttäjille.%n%nKaikille käyttäjille: sulje tämä asennus ja käynnistä MANUgen-setup.exe hiiren oikealla painikkeella valinnalla "Suorita järjestelmänvalvojana". Muuten Windowsin Älykäs sovellusten hallinta voi estää sovelluksen käynnistyksen.
en.PrivilegesRequiredOverrideText2=%1 can be installed for you only, or for all users.%n%nFor all users: close this setup and start MANUgen-setup.exe with right-click "Run as administrator". Otherwise Windows Smart App Control may block the application.

[Tasks]
Name: "desktopicon"; Description: "{cm:CreateDesktopIcon}"; GroupDescription: "{cm:AdditionalIcons}"

[Files]
; application files: replaced on every installation
Source: "{#Src}\*"; DestDir: "{app}"; Excludes: "\settings.json,\workflows.json,\rag\rag.config.json,\rag\initial_index\index.sqlite,\.ticket-demo-package"; Flags: recursesubdirs createallsubdirs ignoreversion
; user-editable settings and the knowledge database: written on the first installation only, kept on upgrade and uninstall
Source: "{#Src}\settings.json"; DestDir: "{app}"; Flags: onlyifdoesntexist uninsneveruninstall
; workflows.json may hold the user's own workflows (Workflow builder, Sovelluksen tyonkulut): kept like settings.json.
; The delivered file is always installed as workflows.default.json; the builder page offers to update from it.
Source: "{#Src}\workflows.json"; DestDir: "{app}"; Flags: onlyifdoesntexist uninsneveruninstall
Source: "{#Src}\workflows.json"; DestDir: "{app}"; DestName: "workflows.default.json"; Flags: ignoreversion
Source: "{#Src}\rag\rag.config.json"; DestDir: "{app}\rag"; Flags: onlyifdoesntexist uninsneveruninstall
Source: "{#Src}\rag\initial_index\index.sqlite"; DestDir: "{app}\rag\initial_index"; Flags: onlyifdoesntexist uninsneveruninstall

[Icons]
; MANUgen.cmd opens the application window and starts ticket-demo.cmd (minimized console) when it is not running
Name: "{group}\MANUgen"; Filename: "{app}\MANUgen.cmd"; WorkingDir: "{app}"; IconFilename: "{app}\ticket-demo.exe"
Name: "{group}\Työnkulun rakentaja"; Filename: "{app}\workflow-builder\index.html"
Name: "{group}\Mallin asennus"; Filename: "{app}\tools\setup\MALLIN-ASENNUS.cmd"; WorkingDir: "{app}"
Name: "{group}\Laitetunnistus"; Filename: "{app}\tools\hardware-probe\device_sniffer.bat"; WorkingDir: "{app}\tools\hardware-probe"
Name: "{group}\Lue minut"; Filename: "{app}\LUEMINUT.txt"
Name: "{group}\{cm:UninstallProgram,MANUgen}"; Filename: "{uninstallexe}"
Name: "{autodesktop}\MANUgen"; Filename: "{app}\MANUgen.cmd"; WorkingDir: "{app}"; IconFilename: "{app}\ticket-demo.exe"; Tasks: desktopicon

[Run]
; runs as the user who started Setup, also after an all-users installation (downloads go to {app})
Filename: "{app}\tools\setup\MALLIN-ASENNUS.cmd"; WorkingDir: "{app}"; Description: "Käynnistä mallin asennus (lataa kielimallin ja mallipalvelimen)"; Flags: postinstall shellexec skipifsilent nowait runasoriginaluser
Filename: "{app}\LUEMINUT.txt"; Description: "Avaa ohje (LUEMINUT.txt)"; Flags: postinstall shellexec skipifsilent nowait unchecked

[Code]
// Microsoft Visual C++ 2015-2022 runtime (x64): needed by llama-server (also the included embedding server).
// Not bundled: installing it needs administrator rights. The user is offered the download link.
const
  VCRedistUrl = 'https://aka.ms/vc14/vc_redist.x64.exe';

function VCRedistInstalled: Boolean;
var
  Installed: Cardinal;
begin
  Result := RegQueryDWordValue(HKLM64, 'SOFTWARE\Microsoft\VisualStudio\14.0\VC\Runtimes\x64', 'Installed', Installed) and (Installed = 1);
end;

procedure CurStepChanged(CurStep: TSetupStep);
var
  ErrorCode: Integer;
begin
  if (CurStep = ssPostInstall) and not WizardSilent and not VCRedistInstalled then
    if MsgBox('Tästä koneesta puuttuu Microsoft Visual C++ -ajonaikainen kirjasto (x64). ' +
      'Tietopohjan embedding-palvelin ja kielimallin palvelin (llama-server) tarvitsevat sen.' + #13#10#13#10 +
      'Avataanko lataus nyt? Suorita ladattu VC_redist.x64.exe. Se pyytää järjestelmänvalvojan oikeudet.' + #13#10#13#10 +
      'Latauslinkki: ' + VCRedistUrl, mbConfirmation, MB_YESNO) = IDYES then
      ShellExec('open', VCRedistUrl, '', '', SW_SHOWNORMAL, ewNoWait, ErrorCode);
end;
