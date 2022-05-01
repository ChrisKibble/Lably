---
external help file: Lably-help.xml
Module Name: Lably
online version:
schema: 2.0.0
---

# Set-LablyBaseVHD

## SYNOPSIS
Sets specific options in Base VHD registry

## SYNTAX

### VHD (Default)
```
Set-LablyBaseVHD -VHD <String> [-NewVHDPath <String>] [-NewFriendlyName <String>] [-NewOSEdition <String>]
 [-NewOSVersion <String>] [-NewProductKey <String>] [-Force] [<CommonParameters>]
```

### ID
```
Set-LablyBaseVHD -ID <String> [-NewVHDPath <String>] [-NewFriendlyName <String>] [-NewOSEdition <String>]
 [-NewOSVersion <String>] [-NewProductKey <String>] [-Force] [<CommonParameters>]
```

### FriendlyName
```
Set-LablyBaseVHD -FriendlyName <String> [-NewVHDPath <String>] [-NewFriendlyName <String>]
 [-NewOSEdition <String>] [-NewOSVersion <String>] [-NewProductKey <String>] [-Force] [<CommonParameters>]
```

## DESCRIPTION
This function is used to set properties of Base VHDs in the Base VHD Registry.

## EXAMPLES

### EXAMPLE 1
```
Set-LablyBaseVHD -VHD C:\BaseVHDs\Windows10-Ent.vhdx
```

### EXAMPLE 2
```
Set-LablyBaseVHD -ID "491e26d4-b6da-4828-b6ee-318536646f75"
```

### EXAMPLE 3
```
Set-LablyBaseVHD -FriendlyName "Windows 10 Enterprise (April 2022)"
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

### -NewVHDPath
Optional New Path for Base VHD.
Will validate that the file exists unless -Force is specified.

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

### -NewFriendlyName
Optional New Friendly New for this Base VHD.

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

### -NewOSEdition
Optional New OS Edition for this Base VHD.
This updates the registry only and not the VHD file.

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

### -NewOSVersion
Optional New OS Version for this Base VHD.
This updates the registry only and not the VHD file.

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

### -NewProductKey
Optional New OS Product Key for this Base VHD.
This updates the registry only and not the VHD file.

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

### -Force
Switch that will set the new Base VHD Path even if it doesn't exist.

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

### None. You cannot pipe objects to Register-LablyBaseVHD.
## OUTPUTS

### None. The function will either complete successfully or throw an error.
## NOTES

## RELATED LINKS
