# TODO List

## Fixes
- When using a non English OS, the `Administrator` account might be spelled some other way, account for this in `New-LablyVM`.

## Enhancements
- In `Get-AnswersToInputQuestions` we use the OS langauge and then fall back to the first entry. Allow user to define language to be asked questions in.
- We need an escape character for `[[VARIABLES]]`.
- Support for non-Windows OS.
- Test for Hyper-V support and installation before any lab creation.
- Accept answers to template questions as hash table.
- Accept answers to template questions as answer file (json?).
- Rebuild labs based on answers defined and cached template(s).
- Servicing of BaseVHDs (when not being used by VMs).
- Ability to provide ISOs or Binaries to templates for post-build installs (SQL, SCCM, etc.)
- Create Credits markdown file.
- Lably friendly output with Get-LablyISODetails, New-LablyBaseVHD, Register-LablyBaseVHD, Remove-Lably, Remove-LablyVM, Start-Lably, and Stop-Lably.
- Note somewhere to never modify an in-use Base VHD
- Command to get information on the current Lably (or at a -Path)
- Define lab-wide admin password in Scaffold so not to prompt users on new VMs (optional)
- Single function for "Waiting for VM to be operational" instead of calling the same code twice, and both should allow user to keep waiting after timeout.
- Customize timeout for VM timeout (global preferences?) for slower hosts.
- We need a Get-LablyVM that we can pipe to Remove-LablyVM
- Stop Lably VMs in Parallel (some defined count)?
- Customize generic hostname prefix in Lably scaffold
- Need a better solution than waiting 15 seconds on new VM builds before configuring network
- Ability to build a new VM in a Lably by cloning the answers to an existing VM in a Scaffold.
- Apply template to VMs already built
- Support for Win7/Srv2012
- Fix: New-LablyVM fails in existing scaffold if user is not admin with wrong error message.
- Function that validates a scaffold by checking the VM display names, NAT info, and switch against Hyper-V
- Cmdlet to validate base registry
- Cmdlet to read/display base registry
- Cmdlet to find virtual switches that aren't assigned to VMs (part of lab validation?)
- Setup Get-LablyISODetail to accept a Get-ChildItem or Get-Item as pipeline input.

## Documentation
- Document secure strings, keys, etc.
