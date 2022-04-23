---
external help file: Lably-help.xml
Module Name: Lably
online version:
schema: 2.0.0
---

# New-Lably

## SYNOPSIS
Creates a new empty lab in the current directory or defined path.

## SYNTAX

### NewSwitch (Default)
```
New-Lably [-Path <String>] [-Name <String>] [-CreateSwitch <String>] [-VirtualDiskPath <String>]
 [-SecretKeyFile] [<CommonParameters>]
```

### NewSwitchNAT
```
New-Lably [-Path <String>] [-Name <String>] [-CreateSwitch <String>] -NATIPAddress <String>
 -NATRangeCIDR <String> [-VirtualDiskPath <String>] [-SecretKeyFile] [<CommonParameters>]
```

### Switch
```
New-Lably [-Path <String>] [-Name <String>] [-Switch <String>] [-VirtualDiskPath <String>] [-SecretKeyFile]
 [<CommonParameters>]
```

## DESCRIPTION
This function is used to create a new Lably (lab or lab scaffold) that will be used to store the meta data for this specific lab.
Function will create a scaffold.lably.json in the defined path that other Lably functions will use to store the metadata.

## EXAMPLES

### EXAMPLE 1
```
New-Lably -Name "Chris' Lab"
```

### EXAMPLE 2
```
New-Lably -Name "Chris' Lab" -CreateSwitch "Test Switch #1"
```

### EXAMPLE 3
```
New-Lably -Name "Chris' Lab" -CreateSwitch "Test Switch #2" -NATIPAddress 10.0.0.1 -NATIPCIDRRange 10.0.0.0/24
```

### EXAMPLE 4
```
New-Lably -Name "Chris' Lab" -Switch "Existing Switch #3"
```

### EXAMPLE 5
```
New-Lably -Name "Chris' Lab" -VirtualDiskPath "D:\LabVMs" -SecretKeyFile
```

## PARAMETERS

### -Path
Optional parameter to define where the lably will be created.
The scaffold, template cache, and (optionally) virtual disks folders will be created within this folder.
If this parameter is not defined, it will default to the path from which the function was called.

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: $PWD
Accept pipeline input: False
Accept wildcard characters: False
```

### -Name
Optional name of the Lably.
Used as a description when using and describing the lab, as well as the default prefix for the display name of VMs created in Hyper-V.
If this parameter is not defined, it will default to the name of the folder it's being created it.

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: (Split-Path $Path -Leaf)
Accept pipeline input: False
Accept wildcard characters: False
```

### -CreateSwitch
Name of switch to be created in Hyper-V for this lab.
Either CreateSwitch or SwitchName are required.
If neither parameter is defined, it will default creating a new switch using the name of the folder it's being created it.

```yaml
Type: String
Parameter Sets: NewSwitch, NewSwitchNAT
Aliases:

Required: False
Position: Named
Default value: (Split-Path $Path -Leaf)
Accept pipeline input: False
Accept wildcard characters: False
```

### -NATIPAddress
Optional parameter to be used when using CreateSwitch to define the IP Address to create for this network to use to access the host's network.

```yaml
Type: String
Parameter Sets: NewSwitchNAT
Aliases:

Required: True
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -NATRangeCIDR
{{ Fill NATRangeCIDR Description }}

```yaml
Type: String
Parameter Sets: NewSwitchNAT
Aliases:

Required: True
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -Switch
Name of exiting Hyper-V switch to be used for this lab.
Either CreateSwitch or SwitchName are required.
If neither parameter is defined, it will default creating a new switch using the name of the folder it's being created it.

```yaml
Type: String
Parameter Sets: Switch
Aliases:

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -VirtualDiskPath
Optional parameter to define the folder in which new differencing disks for this lab will be created when New-LablyVM is called.
Defaults to a 'Virtual Disks' subfolder of the 'Path' parameter.

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -SecretKeyFile
Switch used to indicate that instead of using the computer/user accounts to encrypt secrets that an AES key file should be created.
When using keyfiles, ensure that appropriate NTFS permissions are set on your Lably folder to ensure that keys cannot be read by other users.

```yaml
Type: SwitchParameter
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: False
Accept pipeline input: False
Accept wildcard characters: False
```

### CommonParameters
This cmdlet supports the common parameters: -Debug, -ErrorAction, -ErrorVariable, -InformationAction, -InformationVariable, -OutVariable, -OutBuffer, -PipelineVariable, -Verbose, -WarningAction, and -WarningVariable. For more information, see [about_CommonParameters](http://go.microsoft.com/fwlink/?LinkID=113216).

## INPUTS

### None. You cannot pipe objects to New-Lably.
## OUTPUTS

### None. The function will either complete successfully or throw an error.
## NOTES

## RELATED LINKS
