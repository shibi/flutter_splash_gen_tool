; Inno Setup script for Splash GenX. Built by .github/workflows/windows-installer.yml.
; Pass /DAppVersion=x.y.z and /DSourceDir=<Release folder> to ISCC.

#ifndef AppVersion
  #define AppVersion "1.0.0"
#endif
#ifndef SourceDir
  #define SourceDir "..\build\windows\x64\runner\Release"
#endif

[Setup]
AppId={{6A4E0C5B-2F3D-4B8E-9C1A-5D7F0E2B8A41}
AppName=Splash GenX
AppVersion={#AppVersion}
AppPublisher=Shibin
DefaultDirName={autopf}\Splash GenX
DefaultGroupName=Splash GenX
DisableProgramGroupPage=yes
PrivilegesRequiredOverridesAllowed=dialog
OutputDir=Output
OutputBaseFilename=SplashGenX-Setup-{#AppVersion}
Compression=lzma2
SolidCompression=yes
ArchitecturesAllowed=x64compatible
ArchitecturesInstallIn64BitMode=x64compatible
UninstallDisplayIcon={app}\splash_genx.exe
WizardStyle=modern

[Tasks]
Name: "desktopicon"; Description: "{cm:CreateDesktopIcon}"; GroupDescription: "{cm:AdditionalIcons}"

[Files]
Source: "{#SourceDir}\*"; DestDir: "{app}"; Flags: ignoreversion recursesubdirs createallsubdirs

[Icons]
Name: "{group}\Splash GenX"; Filename: "{app}\splash_genx.exe"
Name: "{autodesktop}\Splash GenX"; Filename: "{app}\splash_genx.exe"; Tasks: desktopicon

[Run]
Filename: "{app}\splash_genx.exe"; Description: "{cm:LaunchProgram,Splash GenX}"; Flags: nowait postinstall skipifsilent
