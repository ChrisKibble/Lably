---
external help file: Lably-help.xml
Module Name: Lably
online version:
schema: 2.0.0
---

# New-LablyVM

## SYNOPSIS
Creates a new VM in Hyper-V using a Base VHD.

## SYNTAX

### TemplateAnswers (Default)
```
New-LablyVM [-Path <String>] [-Template <String>] [-TemplateAnswers <Hashtable>] [-DisplayName <String>]
 [-Hostname <String>] -BaseVHD <String> -AdminPassword <SecureString> [-MemorySizeInBytes <Int64>]
 [-MemoryMinimumInBytes <Int64>] [-MemoryMaximumInBytes <Int64>] [-CPUCount <Int32>] [-ProductKey <String>]
 [-Timezone <String>] [-Locale <String>] [-Force] [<CommonParameters>]
```

### TemplateAnswerFile
```
New-LablyVM [-Path <String>] [-Template <String>] [-TemplateAnswerFile <String>] [-DisplayName <String>]
 [-Hostname <String>] -BaseVHD <String> -AdminPassword <SecureString> [-MemorySizeInBytes <Int64>]
 [-MemoryMinimumInBytes <Int64>] [-MemoryMaximumInBytes <Int64>] [-CPUCount <Int32>] [-ProductKey <String>]
 [-Timezone <String>] [-Locale <String>] [-Force] [<CommonParameters>]
```

## DESCRIPTION
This function is used to create a new Hyper-V VM that will use a differencing disk based on a registered Base VHD.

## EXAMPLES

### EXAMPLE 1
```
New-LablyVM -BaseVHD C:\BaseVHDs\Windows10-Ent.vhdx -AdminPassword $("S3cur3P@s5w0rd" | ConvertTo-SecureString -AsPlainText -Force)
```

### EXAMPLE 2
```
New-LablyVM -BaseVHD C:\BaseVHDs\WindowsServer2022.vhdx -Template "Windows Active Directory Forest" -Hostname LABDC01 -MemorySizeInBytes 4GB -MemoryMinimumInBytes 512MB -MemoryMaximumInBytes 4GB -CPUCount 2
```

### EXAMPLE 3
```
$AdminPassword = "MySuperPassword###1" | ConvertTo-SecureString -AsPlainText -Force
```

New-LablyVM -BaseVHD C:\BaseVHDs\Windows10-Ent.vhdx -MemorySizeInBytes 4GB -Timezone "Eastern Standard Time" -Locale "en-us" -AdminPassword $AdminPassword

## PARAMETERS

### -Path
Optional parameter to define where the lably that this VM will join is stored.
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

### -Template
Optional template to be used.
Templates will be loaded from the "Templates" subfolder of the module and custom ones can be installed into the Lably\Templates folder of the user profile.
This parameter supports auto-complete, you can tab through options or use CTRL+SPACE to view all options.

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

### -TemplateAnswers
{{ Fill TemplateAnswers Description }}

```yaml
Type: Hashtable
Parameter Sets: TemplateAnswers
Aliases:

Required: False
Position: Named
Default value: @{}
Accept pipeline input: False
Accept wildcard characters: False
```

### -TemplateAnswerFile
{{ Fill TemplateAnswerFile Description }}

```yaml
Type: String
Parameter Sets: TemplateAnswerFile
Aliases:

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -DisplayName
Optional DisplayName to be used in Hyper-V.
Defaults to the hostname of the VM prefixed by the name of the Lably (e.g., \[Chris' Lab\] LABDC01).

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

### -Hostname
Optional Hostname for the VM.
Defaults to 'LAB-' followed by a random string of 8 random alphanumeric characters.
Some templates may require that a hostname be defined.

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: "LAB-$([Guid]::NewGuid().ToString().split('-')[0].ToUpper())"
Accept pipeline input: False
Accept wildcard characters: False
```

### -BaseVHD
The path or friendly name of the BaseVHD that should be used to create this VM.
This parameter supports auto-complete, you can tab through options or use CTRL+SPACE to view all options.

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: True
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -AdminPassword
SecureString input of the AdminPassword that should be used to login to the VM.
This parameter will not take plain text, see examples for assistance creating secure strings.

```yaml
Type: SecureString
Parameter Sets: (All)
Aliases:

Required: True
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -MemorySizeInBytes
Optional Memory that should be assigned to the VM.
Defaults to 4GB.
Although this parameter takes the value in bytes, PowerShell will calculate this value for you if you use MB or GB in after a value (e.g.
512MB or 2GB).

```yaml
Type: Int64
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: 4294967296
Accept pipeline input: False
Accept wildcard characters: False
```

### -MemoryMinimumInBytes
Optional Minimum Memory that should be assigned to the VM.
Defaults to 512MB.
Although this parameter takes the value in bytes, PowerShell will calculate this value for you if you use MB or GB in after a value (e.g.
512MB or 2GB).

```yaml
Type: Int64
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: 536870912
Accept pipeline input: False
Accept wildcard characters: False
```

### -MemoryMaximumInBytes
Optional Maximum Memory that should be assigned to the VM.
Defaults to the same value supplied to MemorySizeInBytes.
Although this parameter takes the value in bytes, PowerShell will calculate this value for you if you use MB or GB in after a value (e.g.
512MB or 2GB).

```yaml
Type: Int64
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: $MemorySizeInBytes
Accept pipeline input: False
Accept wildcard characters: False
```

### -CPUCount
Optional number of virtual CPUs to assign to the VM.
Defaults to 1/4th of the total number of logical processors that the host has.

```yaml
Type: Int32
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: [Math]::Max(1,$(Get-CimInstance -Class Win32_Processor).NumberOfLogicalProcessors/4)
Accept pipeline input: False
Accept wildcard characters: False
```

### -ProductKey
Optional product key that should be used when building the VM.
The product key is typically stored in the Base VHD, so this parameter is only necessary if you didn't include one in the Base VHD or if you'd like to use a different one for this VM.

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

### -Timezone
Optional TimeZone ID to use when building this VM.
Defaults to the timezone of the host.

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: $(Get-Timezone).Id
Accept pipeline input: False
Accept wildcard characters: False
```

### -Locale
Optional Windows Locale ID to use when building this VM.
Defaults to the Locale ID of the host.

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: $(Get-WinSystemLocale).Name
Accept pipeline input: False
Accept wildcard characters: False
```

### -Force
Switch that defines that the VHD should be overwritten if it already exists.

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

### None. You cannot pipe objects to New-LablyVM.
## OUTPUTS

### None. The function will either complete successfully or throw an error.
## NOTES

## RELATED LINKS
