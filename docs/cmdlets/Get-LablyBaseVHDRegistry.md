---
external help file: Lably-help.xml
Module Name: Lably
online version:
schema: 2.0.0
---

# Get-LablyBaseVHDRegistry

## SYNOPSIS
Gets list of Lably Base VHDs from Registry

## SYNTAX

```
Get-LablyBaseVHDRegistry [-Meta] [<CommonParameters>]
```

## DESCRIPTION
This function is used to display the Base VHDs currently stored in the Base VHD Registry.

## EXAMPLES

### EXAMPLE 1
```
Get-LablyBaseVHDRegistry
```

### EXAMPLE 2
```
Get-LablyBaseVHDRegistry -Meta
```

## PARAMETERS

### -Meta
Switch to get the meta data from the registry instead of the Base VHDs.

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

### None. You cannot pipe objects to Get-LablyBaseVHDRegistry.
## OUTPUTS

### Array of Base VHDs from Registry.
## NOTES

## RELATED LINKS
