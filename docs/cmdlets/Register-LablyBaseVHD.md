---
external help file: Lably-help.xml
Module Name: Lably
online version:
schema: 2.0.0
---

# Register-LablyBaseVHD

## SYNOPSIS
Registers a Base VHD in the Lably Base Image Registry.

## SYNTAX

### ProductKey (Default)
```
Register-LablyBaseVHD -VHD <String> [-PartitionNumber <Int32>] [-FriendlyName <String>] [-ProductKey <String>]
 [<CommonParameters>]
```

### NoProductKey
```
Register-LablyBaseVHD -VHD <String> [-PartitionNumber <Int32>] [-FriendlyName <String>] [-NoProductKey]
 [<CommonParameters>]
```

## DESCRIPTION
This function is used to register a Base VHD in the Lably Base Image Registry that is stored in the Lably subfolder of your user profile.
The Base Image Registry is used when creating new VMs.

## EXAMPLES

### EXAMPLE 1
```
Register-LablyBaseVHD -VHD C:\BaseVHDs\Windows10-Ent.vhdx -FriendlyName "Windows 10 Enterprise (April 2022)" -ProductKey "XYXY8-TFTF4-N0K3Y-J994X-FAKEX"
```

## PARAMETERS

### -VHD
Full or relative path to the Base VHD.
This can be created with New-LablyBaseVHD or manually.

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: True
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -PartitionNumber
Optional partition number on the VHD where the OS resides.
This will be detected automatically, but may need to be defined if you've manually created a BaseVHD without using the Lably module.

```yaml
Type: Int32
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: 0
Accept pipeline input: False
Accept wildcard characters: False
```

### -FriendlyName
Optional friendly name for the Base VHD that you can use later to easily identify the purpose of the VHD.

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

### -ProductKey
The product key to use when building the VM.
Required if you do not specify the -NoProductKey switch.

```yaml
Type: String
Parameter Sets: ProductKey
Aliases:

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -NoProductKey
Switch used to define that you do not want to embed a product key when building VMs with this VHD.
Not that some Operating Systems will not build without a product key defined.

```yaml
Type: SwitchParameter
Parameter Sets: NoProductKey
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

### None. You cannot pipe objects to Register-LablyBaseVHD.
## OUTPUTS

### None. The function will either complete successfully or throw an error.
## NOTES

## RELATED LINKS
