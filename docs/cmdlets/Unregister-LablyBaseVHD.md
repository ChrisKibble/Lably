---
external help file: Lably-help.xml
Module Name: Lably
online version:
schema: 2.0.0
---

# Unregister-LablyBaseVHD

## SYNOPSIS
Unregisters a Base VHD from the Lably Base Image Registry.

## SYNTAX

### VHD (Default)
```
Unregister-LablyBaseVHD -VHD <String> [<CommonParameters>]
```

### ID
```
Unregister-LablyBaseVHD -ID <String> [<CommonParameters>]
```

### FriendlyName
```
Unregister-LablyBaseVHD -FriendlyName <String> [<CommonParameters>]
```

## DESCRIPTION
This function is used to unregister a Base VHD from the Lably Base Image Registry that is stored in the Lably subfolder of your user profile.
The Base Image Registry is used when creating new VMs.

## EXAMPLES

### EXAMPLE 1
```
Unregister-LablyBaseVHD -VHD C:\BaseVHDs\Windows10-Ent.vhdx
```

### EXAMPLE 2
```
Unregister-LablyBaseVHD -ID "491e26d4-b6da-4828-b6ee-318536646f75"
```

### EXAMPLE 3
```
Unregister-LablyBaseVHD -FriendlyName "Windows 10 Enterprise (April 2022)"
```

## PARAMETERS

### -VHD
Full path to the Base VHD.
Either VHD, ID, or FriendlyName are required.
This parameter supports auto-complete, you can tab through options or use CTRL+SPACE to view all options.

```yaml
Type: String
Parameter Sets: VHD
Aliases:

Required: True
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -ID
Registry ID of the Base VHD.
Either VHD, ID, or FriendlyName are required.
This parameter supports auto-complete, you can tab through options or use CTRL+SPACE to view all options.

```yaml
Type: String
Parameter Sets: ID
Aliases:

Required: True
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -FriendlyName
Friendly name for the Base VHD.
Either VHD, ID, or FriendlyName are required.
This parameter supports auto-complete, you can tab through options or use CTRL+SPACE to view all options.

```yaml
Type: String
Parameter Sets: FriendlyName
Aliases:

Required: True
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### CommonParameters
This cmdlet supports the common parameters: -Debug, -ErrorAction, -ErrorVariable, -InformationAction, -InformationVariable, -OutVariable, -OutBuffer, -PipelineVariable, -Verbose, -WarningAction, and -WarningVariable. For more information, see [about_CommonParameters](http://go.microsoft.com/fwlink/?LinkID=113216).

## INPUTS

### None. You cannot pipe objects to Register-LablyBaseVHD.
## OUTPUTS

### None. The function will either complete successfully or throw an error.
## NOTES

## RELATED LINKS
