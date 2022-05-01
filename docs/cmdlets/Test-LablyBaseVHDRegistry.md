---
external help file: Lably-help.xml
Module Name: Lably
online version:
schema: 2.0.0
---

# Test-LablyBaseVHDRegistry

## SYNOPSIS
Tests the Lably Base VHD registry.

## SYNTAX

```
Test-LablyBaseVHDRegistry [-Fix] [<CommonParameters>]
```

## DESCRIPTION
This function is used to test to ensure that all of the Base VHDs in the registry exist and are valid.

## EXAMPLES

### EXAMPLE 1
```
Test-LablyBaseVHDRegistry
```

### EXAMPLE 2
```
Test-LablyBaseVHDRegistry -Clean
```

## PARAMETERS

### -Fix
Switch to resolve issues with OS Edition and Version if found.

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

### None. You cannot pipe objects to Test-LablyBaseVHDRegistry.
## OUTPUTS

### None. The function will either complete successfully or throw an error.
## NOTES

## RELATED LINKS
