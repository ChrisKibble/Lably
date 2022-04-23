---
external help file: Lably-help.xml
Module Name: Lably
online version:
schema: 2.0.0
---

# Get-LablyISODetails

## SYNOPSIS
Gets the details from the WIM inside of a supplied ISO.

## SYNTAX

```
Get-LablyISODetails [[-ISO] <String>] [<CommonParameters>]
```

## DESCRIPTION
Gets the details from the WIM inside of a supplied ISO.
Takes the path of the ISO as a parameter.

## EXAMPLES

### EXAMPLE 1
```
Get-LablyISODetais -ISO C:\ISOs\Windows10-Enterprise.iso
```

## PARAMETERS

### -ISO
Full or relative path to the ISO file to get details on.

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: False
Position: 1
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### CommonParameters
This cmdlet supports the common parameters: -Debug, -ErrorAction, -ErrorVariable, -InformationAction, -InformationVariable, -OutVariable, -OutBuffer, -PipelineVariable, -Verbose, -WarningAction, and -WarningVariable. For more information, see [about_CommonParameters](http://go.microsoft.com/fwlink/?LinkID=113216).

## INPUTS

### None. You cannot pipe objects to Get-LablyISODetails.
## OUTPUTS

### System.Collections.Generic.List`1[[Microsoft.Dism.Commands.WimImageInfoObject,
### Microsoft.Dism.PowerShell, Version=10.0.0.0, Culture=neutral, PublicKeyToken=null]]
### System.Collections.Generic.List`1[[Microsoft.Dism.Commands.ImageInfoObject, Microsoft.Dism.PowerShell,
### Version=10.0.0.0, Culture=neutral, PublicKeyToken=null]]
### System.Collections.Generic.List`1[[Microsoft.Dism.Commands.BasicImageInfoObject,
### Microsoft.Dism.PowerShell, Version=10.0.0.0, Culture=neutral, PublicKeyToken=null]]
### System.Collections.Generic.List`1[[Microsoft.Dism.Commands.MountedImageInfoObject,
### Microsoft.Dism.PowerShell, Version=10.0.0.0, Culture=neutral, PublicKeyToken=null]]
## NOTES

## RELATED LINKS
