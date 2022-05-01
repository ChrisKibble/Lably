---
external help file: Lably-help.xml
Module Name: Lably
online version:
schema: 2.0.0
---

# Start-Lably

## SYNOPSIS
Starts all of the Virtual Machines that are members of the defined lably.

## SYNTAX

```
Start-Lably [[-Path] <String>] [<CommonParameters>]
```

## DESCRIPTION
This function is used to start all of the Virtual Machines that are members of the defined lably.

## EXAMPLES

### EXAMPLE 1
```
Start-Lably
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

### CommonParameters
This cmdlet supports the common parameters: -Debug, -ErrorAction, -ErrorVariable, -InformationAction, -InformationVariable, -OutVariable, -OutBuffer, -PipelineVariable, -Verbose, -WarningAction, and -WarningVariable. For more information, see [about_CommonParameters](http://go.microsoft.com/fwlink/?LinkID=113216).

## INPUTS

### None. You cannot pipe objects to start-Lably.
## OUTPUTS

### None. The function will either complete successfully or throw an error.
## NOTES

## RELATED LINKS
