#ifndef GameVersion
#define GameVersion "1.0.1"
#endif
[Setup]
AppId={{811D39AE-C8D6-4A8A-A231-87C98EF3F457}
AppName=SAPERROR
AppVersion={#GameVersion}
AppPublisher=SAPERROR
DefaultDirName={localappdata}\Programs\SAPERROR
DefaultGroupName=SAPERROR
PrivilegesRequired=lowest
ArchitecturesAllowed=x64compatible
ArchitecturesInstallIn64BitMode=x64compatible
DisableProgramGroupPage=yes
UsePreviousAppDir=yes
UninstallDisplayIcon={app}\SAPERROR.exe
SetupIconFile=setup_icon.ico
OutputDir=..\build\installer
OutputBaseFilename=SAPERROR_Backend
Compression=lzma2
SolidCompression=yes
WizardStyle=classic
CloseApplications=no
RestartApplications=no
[Languages]
Name: "english"; MessagesFile: "compiler:Default.isl"
Name: "ukrainian"; MessagesFile: "compiler:Languages\Ukrainian.isl"
[Tasks]
Name: "desktopicon"; Description: "{cm:CreateDesktopIcon}"; Flags: unchecked
[Files]
Source: "..\build\windows\*"; DestDir: "{app}"; Flags: ignoreversion recursesubdirs createallsubdirs
[Icons]
Name: "{autoprograms}\SAPERROR"; Filename: "{app}\SAPERROR.exe"; WorkingDir: "{app}"
Name: "{autoprograms}\Uninstall SAPERROR"; Filename: "{uninstallexe}"
Name: "{autodesktop}\SAPERROR"; Filename: "{app}\SAPERROR.exe"; WorkingDir: "{app}"; Tasks: desktopicon
[Code]
procedure CurInstallProgressChanged(CurProgress, MaxProgress: Integer);
var
  ProgressPath: String;
begin
  ProgressPath := ExpandConstant('{param:PROGRESSFILE|}');
  if (ProgressPath <> '') and (MaxProgress > 0) then
    SaveStringToFile(ProgressPath, IntToStr(Round(100.0 * CurProgress / MaxProgress)), False);
end;
