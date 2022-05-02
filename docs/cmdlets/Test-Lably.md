---
external help file: Lably-help.xml
Module Name: Lably
online version:
schema: 2.0.0
---

# Test-Lably

## SYNOPSIS
Tests the Lably Scaffold for Inconsistencies.

## SYNTAX

```
Test-Lably [[-Path] <String>] [-Fix] [<CommonParameters>]
```

## DESCRIPTION
This function is used to test your Lably scaffold against your file system and Hyper-V to ensure consistency.

## EXAMPLES

### EXAMPLE 1
```
Test-Lably
```

### EXAMPLE 2
```
Test-Lably -Fix
```

## PARAMETERS

### -Path
Optional parameter to define where the lably is stored.
If this parameter is not defined, it will default to the path from which the function was called.

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: False
Position: 1
Default value: $PWD
Accept pipeline input: False
Accept wildcard characters: False
```

### -Fix
Switch to resolve issues with if found.

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

### None. You cannot pipe objects to Test-Lably.
## OUTPUTS

### None. The function will either complete successfully or throw an error.
## NOTES

## RELATED LINKS
