# Runs once at first logon, from the installation medium, as the local admin
# created by autounattend.xml. Everything after this is driven over SSH.

$ErrorActionPreference = 'Continue'

# OpenSSH server. An Administrator account is authorised from the *administrators*
# key file, not ~/.ssh/authorized_keys, and that file has to drop inherited
# permissions or sshd silently refuses the key.
Add-WindowsCapability -Online -Name OpenSSH.Server~~~~0.0.1.0 | Out-Null
Set-Service sshd -StartupType Automatic
Start-Service sshd
New-Item -ItemType Directory -Force "$env:ProgramData\ssh" | Out-Null
$key = '@@SSH_KEY@@'
$akf = "$env:ProgramData\ssh\administrators_authorized_keys"
if (-not (Test-Path $akf)) {
  Set-Content -Path $akf -Value $key -Encoding ascii
} else {
  Add-Content -Path $akf -Value $key
}
icacls $akf /inheritance:r /grant "Administrators:F" /grant "SYSTEM:F" | Out-Null
New-NetFirewallRule -DisplayName "OpenSSH Inbound" -Direction Inbound -Action Allow -Protocol TCP -LocalPort 22 | Out-Null

# RDP, for a human. Not for measuring the GPU: a remote session can make a
# GPU-accelerated app disable acceleration.
Set-ItemProperty 'HKLM:\System\CurrentControlSet\Control\Terminal Server' -Name fDenyTSConnections -Value 0
Enable-NetFirewallRule -DisplayGroup "Remote Desktop"

# A test box does not need consumer nudges or telemetry prompts.
New-Item -Path 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\CloudContent' -Force | Out-Null
Set-ItemProperty 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\CloudContent' -Name DisableWindowsConsumerFeatures -Value 1 -Type DWord
New-Item -Path 'HKCU:\Software\Microsoft\Windows\CurrentVersion\UserProfileEngagement' -Force | Out-Null
Set-ItemProperty 'HKCU:\Software\Microsoft\Windows\CurrentVersion\UserProfileEngagement' -Name ScoobeSystemSettingEnabled -Value 0 -Type DWord

# VirtIO drivers, then the guest agent -- in the virtio-win tree the agent is not
# part of the guest-tools MSI, it is guest-agent\qemu-ga-x86_64.msi. The agent is
# what makes `virsh domifaddr --source agent` work and lets snapshots quiesce the
# filesystem. Both log, so a silent failure leaves a trail.
$cd = (Get-CimInstance Win32_CDROMDrive | Where-Object VolumeName -like '*WINVM*').DriveLetter
if ($cd) {
  Start-Process msiexec.exe -ArgumentList "/i ${cd}:\virtio-win-gt-x64.msi /qn /norestart /l*v C:\winvm-drivers.log" -Wait
  Start-Process msiexec.exe -ArgumentList "/i ${cd}:\guest-agent\qemu-ga-x86_64.msi /qn /norestart /l*v C:\winvm-agent.log" -Wait
  Start-Service qemu-ga -ErrorAction SilentlyContinue
}

# Written so the adapter inventory is one command away later.
Get-CimInstance Win32_VideoController |
  Select-Object Name, DriverVersion |
  Out-File C:\winvm-adapters.txt

# Debloating. `WINVM_DEBLOAT=0` at install time swaps this block for a comment.
@@DEBLOAT@@
