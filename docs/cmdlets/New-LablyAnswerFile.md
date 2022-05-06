---
external help file: Lably-help.xml
Module Name: Lably
online version:
schema: 2.0.0
---

# New-LablyAnswerFile

## SYNOPSIS
Creates a new answer file for a template.

## SYNTAX

```
New-LablyAnswerFile [-Template] <String> [-IncludeHelpMessages] [<CommonParameters>]
```

## DESCRIPTION
This function is used create an answer file that can be passed to New-LablyVM as a parameter to answer the questions posed by a template.

## EXAMPLES

### EXAMPLE 1
```
New-LablyAnswerFile -Template "My Template Name" | Out-File c:\AnswerFiles\TemplateAnswerFile.json
```

## PARAMETERS

### -Template
Template to be used.
Templates will be loaded from the "Templates" subfolder of the module and custom ones can be installed into the Lably\Templates folder of the user profile.
This parameter supports auto-complete, you can tab through options or use CTRL+SPACE to view all options.

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

### -IncludeHelpMessages
{{ Fill IncludeHelpMessages Description }}

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

### None. You cannot pipe objects to New-LablyAnswerFile.
## OUTPUTS

### None. The function will either complete successfully or throw an error.
## NOTES

## RELATED LINKS
