---
external help file: Lably-help.xml
Module Name: Lably
online version:
schema: 2.0.0
---

# Remove-LablyVM

## SYNOPSIS
Remove a VM from Lably and from Hyper-V.

## SYNTAX

### DisplayName (Default)
```
Remove-LablyVM [-Path <String>] [-DisplayName] <String> [-Confirm] [<CommonParameters>]
```

### VMID
```
Remove-LablyVM [-Path <String>] [-VMId] <String> [-Confirm] [<CommonParameters>]
```

## DESCRIPTION
This function is used to remove a VM from Lably and from Hyper-V.

## EXAMPLES

### EXAMPLE 1
```
Remove-LablyVM -DisplayName "[Chris' Lab] LABDC01"
```

### EXAMPLE 2
```
Remove-LablyVM -VMID 717b54e6-a50a-480e-8a3f-9f21ab2e08e9
```

## PARAMETERS

### -Path
Optional parameter to define where the lably that this VM is a member of is stored.
If this parameter is not defined, it will default to the path from which the function was called.

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: $PWD
Accept pipeline input: False
Accept wildcard characters: False
```

### -DisplayName
Display Name of the VM to be removed.
Either this or the VMID parameter is required.
This parameter supports auto-complete, you can tab through options or use CTRL+SPACE to view all options.

```yaml
Type: String
Parameter Sets: DisplayName
Aliases:

Required: True
Position: 1
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -VMId
Lably ID of the VM to be removed.
Either this or the DisplayName parameter is required.

```yaml
Type: String
Parameter Sets: VMID
Aliases:

Required: True
Position: 1
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -Confirm
Optional Switch to bypass confirming that you want to delete the Virtual Machine.

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

### None. You cannot pipe objects to Remove-LablyVM.
## OUTPUTS

### None. The function will either complete successfully or throw an error.
## NOTES

## RELATED LINKS
