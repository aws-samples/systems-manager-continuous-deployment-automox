resource "aws_ssm_document" "install_automox_multi_os" {
  name            = "InstallAutomoxMultiOS"
  document_format = "YAML"
  document_type   = "Command"

  content = <<DOC
---
schemaVersion: "2.2"
description: "Installs Automox on Windows and Linux"
parameters:
  InstallAutomox:
    type: "String"
    description: "Automox"
    default: "######## Install Automox Agent ########"
  AutomoxURL:
    type: "String"
    description: "Automox URL"
    default: "https://console.automox.com/Automox_Installer-latest.msi"
  AutomoxKey:
    type: "String"
    description: "Automox Key"
    default: "{{resolve:secretsmanager:automoxAPI:SecretString:automoxKey}}"
  AMPath:
    type: "String"
    description: "AM Path"
    default: "C:\\Temp"
  AMOutFile:
    type: "String"
    description: "AM Outfile"
    default: "C:\\Temp\\Automox_Installer-latest.msi"
mainSteps:
- action: "aws:runShellScript"
  name: "InstallAutomoxLinux"
  precondition:
    StringEquals:
      - platformType
      - Linux
  inputs:
    runCommand:
      - "if [[ $(ps aux | grep amagent | grep -vc grep)  > 0 ]] ; then echo 'Automox Agent already installed. Exiting.' && exit 1; fi"
      - "echo 'Installing Automox'"
      - "curl -sS https://console.automox.com/downloadInstaller?accesskey={{AutomoxKey}} | sudo bash"
      - "if [[ $(ps aux | grep amagent | grep -vc grep)  > 0 ]] ; then echo 'Automox Agent successfully installed.'; fi"
      - "aws ec2 create-tags --resources `cat /var/lib/cloud/data/instance-id` --tags Key=Automox,Value=True"
- action: "aws:runPowerShellScript"
  name: "InstallAutomoxWindows"
  precondition:
    StringEquals:
      - platformType
      - Windows
  inputs:
    runCommand:
    - "if (Get-Service -Name 'amagent' -ErrorAction SilentlyContinue) { Write-Host 'Automox already installed. Exiting.'; exit 2 } "
    - "Write-Host {{InstallAutomox}}"
    - "if (!(Test-Path -Path {{AMPath}} -ErrorAction SilentlyContinue)) { New-Item -ItemType Directory -Path {{AMPath}} -Force }"
    - "Invoke-WebRequest -Uri {{AutomoxURL}} -OutFile {{AMOutFile}}" 
    - "Start-Process 'msiexec.exe' -ArgumentList '/i {{AMOutFile}} /qn /norestart ACCESSKEY={{AutomoxKey}}'"
    - "if (Get-Service -Name 'amagent' -ErrorAction SilentlyContinue) { Write-Host 'Automox Agent successfully installed.'}"
    - "$instanceId = Get-EC2InstanceMetadata -Path '/instance-id'"
    - "$tag = New-Object Amazon.EC2.Model.Tag"
    - "$tag.Key = 'Automox'"
    - "$tag.Value = 'True'"
    - "New-EC2Tag -Resource $instanceId -Tag $tag"
DOC
}