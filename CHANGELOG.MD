# Change Log

## Beta v0.2 -> vNext

### Fixes

- Public modules will now validate admin permissions (when required) and that necessary Hyper-V modules are installed
- Fixed issue where passing the `-Switch` parameter to New-LablyVM would still try and create a new Switch instead of using existing
- Fixed issue where, when using an existing switch, it could get removed if no other VMs are using it when Lably is deleted
- Fixed issue with cached templates not being removed properly in `Remove-Lably`
- If New NAT Address cannot be created when setting up Lably, proper warning is now thrown
- Fixed Start/Stop Lably functions (somewhere along the way they stopped converting from JSON)
- Minor Fixes to Spelling, Grammar, and Spacing

### Other Changes & Enhancements

- Added template documentation
- New Function `Test-Lably` to check (and optionally fix) your Lably Scaffold
- New Function `Test-LablyBaseVHDRegistry` to check (and optionally fix) the Base VHD Registry
- New Function `Get-LablyBaseVHDRegistry` to list the contents of the Base VHD Registry
- New Function `Set-LablyBaseVHD` to set VHD path, FriendlyName, and OS Details in Base VHD Registry
- Improved process that waits for network in VM to become available

## Beta v0.1 -> Beta v0.2:

### Fixes

- **Breaking Change**: Fixed typo "ModifedDateUTC" to "ModifiedDateUTC" when creating/modifying the Base Image Registry.  **Action Required**: If you registered base images with Beta v0.1, open the `BaseImageRegistry.json` file in the Lably subfolder of your user profile and change the label `ModifedDateUTC` to be `ModifiedDateUTC` before registering/unregistering new BaseVHDs.
- Minor fixes to grammar and spacing
- Validate WIM Index Number before creating VHD
- Validate NATIP wasn't in use before assigning in new Hyper-V Switch Build
- Improved likelihood that enabling PSRemoting will work
- Depth Issue was breaking JSON Output in some cases, set depth to 10.

### Other Changes & Enhancements

- Added License and Contributing Files
- Added comment based help to all public functions
- Allow user to set VHDX size when creating new Base VHD
- Added CIDR range to scaffold and show to user on new template based VM build
- Minor updates to output when building Domain Controller to hide unnecessary notices
- Saved Input Responses and Admin Password to Scaffold
- Scaffold now uses the BaseVHD GUID instead of path (easier to move the VHD file(s) later on when we build that out)
- Spelling & Grammar fixes

### New Templates

- Added Windows Domain Joined Client Template as Default

