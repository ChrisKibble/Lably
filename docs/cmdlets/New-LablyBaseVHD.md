---
external help file: Lably-help.xml
Module Name: Lably
online version:
schema: 2.0.0
---

# New-LablyBaseVHD

## SYNOPSIS
Creates a new Base VHD file for use in creating new VMs.

## SYNTAX

```
New-LablyBaseVHD [-ISO] <String> [-VHD] <String> [-VHDSizeInBytes <Int64>] [-Index <Int32>] [-Force]
 [<CommonParameters>]
```

## DESCRIPTION
This function is used to creates a new Base VHD file for use in creating new VMs.
It is not tied to any specific lab, any lab can use any of the Base VHDs.
Once the VHD is created, the Register-LablyBaseVHD should be used to add it to the image registry.

## EXAMPLES

### EXAMPLE 1
```
New-LablyBaseVHD -ISO C:\ISOs\Windows10-Enterprise.iso -Index 4 -VHD C:\VHDRepo\Win10Ent.vhdx
```

## PARAMETERS

### -ISO
Full or relative path to the ISO that has the Operating System installer on it.

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: True
Position: 1
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -VHD
Full or relative path to where the Base VHD should be created.

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: True
Position: 2
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -VHDSizeInBytes
Optional size of the Base VHD.
As the VHD expands to fit the content and doesn't use the full space unless necessary, there is unlikely to be a value in setting this parameter.
Defaults to 127GB.

```yaml
Type: Int64
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: 136365211648
Accept pipeline input: False
Accept wildcard characters: False
```

### -Index
Index number of the Operating System to create the Base VHD for.
Default to 1.
If you're unsure of the Index Number, use Get-LablyISODetails to identify it.

```yaml
Type: Int32
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: 1
Accept pipeline input: False
Accept wildcard characters: False
```

### -Force
Switch that defines that the VHD should be overwritten if the file exists.

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

### None. You cannot pipe objects to New-LablyBaseVHD.
## OUTPUTS

### None. The function will either complete successfully or throw an error.
## NOTES

## RELATED LINKS
