# TODO List

- In `Get-AnswersToInputQuestions` we use the OS langauge and then fall back to the first entry. Allow user to define language to be asked questions in.
- We need an escape character for `[[VARIABLES]]`.
- When creating a new NAT rule in `New-Lably`, we need to add the `$NATIP` to the Scaffold.
- When creating a new VM, if there is as NAT IP in use, remind the user what that IP is for use in their VM.
- Validate the Incoming Index number in `New-LablyBaseVHD`.
- All user to set VHDx Size in `New-LablyBaseVHD`.
- Support for non-Windows OS.
- When using a non English OS, the `Administrator` account might be spelled some other way, account for this in `New-LablyVM`.
