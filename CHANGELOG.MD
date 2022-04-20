# Change Log

## Beta v0.1 -> Beta v0.2:

- **Breaking Change**: Fixed typo "ModifedDateUTC" to "ModifiedDateUTC" when creating/modifying the Base Image Registry.  **Action Required**: If you registered base images with Beta v0.1, open the `BaseImageRegistry.json` file in the Lably subfolder of your user profile and change the label `ModifedDateUTC` to be `ModifiedDateUTC` before registering/unregistering new BaseVHDs.
