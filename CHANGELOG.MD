# Change Log

## Beta v0.2 -> vNext

### Fixes

- Public modules will now validate admin permissions (when required) and that necessary Hyper-V modules are installed

### Other Changes & Enhancements

- Added template documentation

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

