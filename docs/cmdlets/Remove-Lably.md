---
external help file: Lably-help.xml
Module Name: Lably
online version:
schema: 2.0.0
---

# Remove-Lably

## SYNOPSIS
Remove an existing lab in the current directory or defined path.

## SYNTAX

```
Remove-Lably [[-Path] <String>] [-Confirm] [<CommonParameters>]
```

## DESCRIPTION
This function is used to remove a Lably from the current directory or defined path.
It will also remove the VMs from Hyper-V and cleanup everything associated with the lab.

## EXAMPLES

### EXAMPLE 1
```
Remove-Lably
```

### EXAMPLE 2
```
Remove-Lably -Path C:\Labs\Windows10-Lab
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

### -Confirm
Optional Switch to bypass confirming that you want to delete the Lab and associated data.

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
