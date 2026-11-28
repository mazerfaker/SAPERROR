param([string]$Version = '0.9.0-rc.8', [switch]$Smoke)
$ErrorActionPreference = 'Stop'
Set-Location (Split-Path $PSScriptRoot -Parent)
$art = 'installer/setup_art.png'
$icon = 'installer/setup_icon.ico'
if (!(Test-Path $icon)) { throw 'Missing approved installer/setup_icon.ico' }
if ((Get-FileHash $icon -Algorithm SHA256).Hash.ToLowerInvariant() -ne 'bad834b2b509d0e453a85da0edb4d67f6040540a85cefa63e8423246ea9fb1e6') { throw 'Installer icon differs from the approved ICO' }
if (!(Test-Path $art)) { throw 'Missing approved installer/setup_art.png' }
if ((Get-FileHash $art -Algorithm SHA256).Hash.ToLowerInvariant() -ne 'eff5e285bc85bb9b14a885af57db1c13c9b6257687f3a7598e735c6695f3a31f') { throw 'Installer art differs from the supplied PNG' }
foreach ($file in @('SAPERROR.exe','SAPERROR.pck','LICENSES.md')) {
  if (!(Test-Path "build/windows/$file")) { throw "Missing verified game payload: $file" }
}
New-Item -ItemType Directory -Force build/installer,build/dist,build/logs | Out-Null
$iscc = Join-Path (Get-Item 'Env:ProgramFiles(x86)').Value 'Inno Setup 6\ISCC.exe'
if (!(Test-Path $iscc)) {
  choco install innosetup --yes --no-progress
  if ($LASTEXITCODE -ne 0) { throw 'Inno Setup installation failed' }
}
if (!(Test-Path $iscc)) { throw 'Inno Setup compiler missing' }
& $iscc "/DGameVersion=$Version" 'installer/payload.iss'
if ($LASTEXITCODE -ne 0) { throw 'Payload installer compile failed' }
$csc = Join-Path $env:WINDIR 'Microsoft.NET\Framework64\v4.0.30319\csc.exe'
if (!(Test-Path $csc)) { throw '.NET Framework C# compiler missing' }
foreach ($theme in @('Retro98')) {
  $out = "build/installer/SAPERROR_Setup.exe"
  $args = @('/nologo','/target:winexe','/platform:x64','/optimize+','/codepage:65001','/reference:System.Windows.Forms.dll','/reference:System.Drawing.dll',"/out:$out",('/win32icon:'+(Resolve-Path 'installer/setup_icon.ico').Path),('/resource:'+(Resolve-Path 'build/installer/SAPERROR_Backend.exe').Path+',setup.payload'),('/resource:'+(Resolve-Path 'installer/setup_art.png').Path+',setup.art'),(Resolve-Path 'installer/SetupWindow.cs').Path)
  & $csc @args
  if ($LASTEXITCODE -ne 0 -or !(Test-Path $out)) { throw "Failed to compile $theme Setup" }
  Add-Type -AssemblyName System.Drawing
  $actual = [System.Drawing.Icon]::ExtractAssociatedIcon((Resolve-Path $out).Path)
  if ($null -eq $actual) { throw "Missing embedded setup icon: $theme" }
  $actual.Dispose()
  if ($Smoke) {
    $png = Join-Path $PWD "build/logs/installer_$theme.png"
    $p = Start-Process -FilePath (Resolve-Path $out).Path -ArgumentList @('--snapshot',('"' + $png + '"')) -PassThru
    if (!$p.WaitForExit(30000)) { $p.Kill(); throw "Setup screenshot timeout: $theme" }
    if ($p.ExitCode -ne 0 -or !(Test-Path $png)) { throw "Setup visual smoke failed: $theme" }
    $consentFile = Join-Path $env:RUNNER_TEMP ('saperror-consent-' + [Guid]::NewGuid() + '.txt')
    $p = Start-Process -FilePath (Resolve-Path $out).Path -ArgumentList @('--consent-test',('"' + $consentFile + '"')) -PassThru
    if (!$p.WaitForExit(30000)) { $p.Kill(); throw 'Consent test timed out' }
    if ($p.ExitCode -ne 0 -or !(Test-Path $consentFile) -or (Get-Content $consentFile -Raw) -ne 'v4:deny') { throw 'Consent persistence QA failed' }
    Remove-Item $consentFile -Force
    if (!$env:GODOT_EXE) { throw 'GODOT_EXE required for consent handoff QA' }
    $handoffRoot = Join-Path $env:RUNNER_TEMP ('saperror-handoff-' + [Guid]::NewGuid())
    try {
      foreach ($choice in @('allow','deny')) {
        $p = Start-Process -FilePath (Resolve-Path $out).Path -ArgumentList @('--consent-handoff-test',('"' + $handoffRoot + '"'),$choice) -PassThru
        if (!$p.WaitForExit(30000)) { $p.Kill(); throw 'Installer handoff timed out' }
        if ($p.ExitCode -ne 0) { throw 'Installer handoff write failed' }
        $env:SAPERROR_QA_CONSENT_PATH = Join-Path $handoffRoot 'Godot/app_userdata/SAPERROR/analytics_consent.txt'
        $env:SAPERROR_QA_CONSENT_EXPECT = $choice
        & $env:GODOT_EXE --headless --path . --script res://tests/installer_consent_test.gd 2>&1 | Tee-Object -Append build/logs/installer-consent-handoff.txt
        if ($LASTEXITCODE -ne 0) { throw "Godot rejected installer consent: $choice" }
      }
    } finally {
      Remove-Item Env:SAPERROR_QA_CONSENT_PATH,Env:SAPERROR_QA_CONSENT_EXPECT -ErrorAction SilentlyContinue
      Remove-Item $handoffRoot -Recurse -Force -ErrorAction SilentlyContinue
    }
  }
  $zipName = 'SAPERROR_v{0}_Setup.zip' -f $Version
  Compress-Archive -Path $out -DestinationPath (Join-Path 'build/dist' $zipName) -Force
  Get-FileHash $out | Out-File -Append build/logs/installer-hashes.txt
}
if ($Smoke) {
  $test = Join-Path $env:RUNNER_TEMP ('saperror-install-' + [Guid]::NewGuid())
  $p = Start-Process -FilePath (Resolve-Path build/installer/SAPERROR_Backend.exe).Path -ArgumentList @('/VERYSILENT','/SUPPRESSMSGBOXES','/NORESTART','/SP-',('/DIR="'+$test+'"'),'/TASKS=""') -PassThru
  if (!$p.WaitForExit(180000)) { $p.Kill(); throw 'Install smoke timeout' }
  if ($p.ExitCode -ne 0) { throw "Install smoke failed: $($p.ExitCode)" }
  foreach ($file in @('SAPERROR.exe','SAPERROR.pck','LICENSES.md')) {
    if ((Get-FileHash "build/windows/$file").Hash -ne (Get-FileHash (Join-Path $test $file)).Hash) { throw "Installed payload mismatch: $file" }
  }
  $uninstall = Join-Path $test 'unins000.exe'
  if (!(Test-Path $uninstall)) { throw 'Uninstaller missing' }
  $p = Start-Process -FilePath $uninstall -ArgumentList @('/VERYSILENT','/SUPPRESSMSGBOXES','/NORESTART') -PassThru
  if (!$p.WaitForExit(120000)) { $p.Kill(); throw 'Uninstall smoke timeout' }
  if ($p.ExitCode -ne 0) { throw 'Uninstall smoke failed' }
  for ($i=0; $i -lt 30 -and (Test-Path (Join-Path $test 'SAPERROR.exe')); $i++) { Start-Sleep -Seconds 1 }
  if (Test-Path (Join-Path $test 'SAPERROR.exe')) { throw 'Uninstall left the game executable' }
  'INSTALLER_QA Retro98 captured; default opt-out and consent persistence checked; payload install/hash/uninstall verified' | Out-File build/logs/installer-status.txt
}
