# Template Development

## Introduction

Templates are what makes Lably extendable. Templates allow you to build and share instructions to regularly recreate the same type of systems in a lab. Unlike other lab building solutions, templates are meant to be dynamic in that the user of your template can define their own system names, IP ranges, domain names, etc. It should feel personal to them.

## Template Format & Path

Templates are stored in JSON format. They can be loaded from the `templates` subfolder of the installed Lably module, however as a best practice you should not store new modules here. Instead, custom modules or modules being shared can be placed in to the `Lably\Templates` folder of the user's home directory.

The Template has three sections:

- Meta: Containing information about the template and it's author.
- Input: Where you'll collect data from the user of the template in order to build the lab.
- Requirements: Where you'll define any specific requirements that the template has.
- Asset: Where you'll build your VM from the input.
- Properties: Where you can store public information in the Lably scaffold that other VMs may be able to take advantage of.

Each of these sections is described below. The order of the sections does not matter, although the Lably authors suggest following the order outlined above for consistency when viewing and editing templates. Both JSON and Lably are case insensitive, the property names can be in any case.

## Template Meta Section

The Meta section of the template requires five specific values. An example of the meta section from the a template that builds a Domain Controller is shown here.

```json
"Meta": {
    "Id":"68b744e1-8297-4bb5-bfd9-dbc5833edc87",
    "Name":"Windows-Basic-Domain",
    "Version":"1.0",
    "Author":"Chris Kibble",
    "Description":"Windows Domain with one site and one domain controller.",
    "Schema":"0.1"
},
```

The ID should be a unique GUID for your template that should not change even when the version is updated. You can generate a GUID for your template using PowerShell by executing `[GUID]::NewGuid()`. There are also GUID generators online that you can use.

The Name property should contain a name for your template that gives an idea of its purpose.

The Version property should contain a version in valid version format, containing at least a major and minor version, and optionally containing a build and release section.

The author can contain any value that the author of the template would like, including their name, email address, twitter handle, GitHub nickname, etc. This is where you take credit for your work.

The description property is a free form description of your template.

Finally, the schema version is a Lably specific number that identifies how the rest of the document will be interpreted. At this time, although it is ignored by the processor, only 0.1 is supported and should be included here.

## Template Input Section

The input section contains the questions that you need to ask the user in order to build the VM in the next section. The following example shows all of the possibly properties that can be used in a question:

```json
"DHCPIPStart":{
    "Prompt":{
        "en-us":"Enter the Start IP Address for your DHCP Scope (e.g. 10.0.0.10)"
    },
    "Validate":{
        "Message":{
            "en-us":"Must be in valid IPv4 address format."
        },
        "RegEx":"^(?:(?:25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\\.){3}(?:25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)$"
    },
    "AskWhen":"If('[[DHCP]]' -eq 'Y') { $true } else { $false }",
    "Secure": false
}
```

We start by defining the name of the question, which will not be shown to the user. This name will ultimately become the variable you reference when using the answer to this question. In this example, the name is `DHCPIPStart`.

In the `Prompt` section, we ask the question to the user. The question can be asked in a variety of languages and the version that gets used will be based on the OS language of the users host Operating System. If no match is found, we'll default to the first language shown.

The validate section is optional and allows you to use RegEx to define a valid response to the question. If the user does not provide a valid response, the value of `Message` will be displayed (following the same language rules as the previous section.)

If you define an `AskWhen` section, you can provide PowerShell that will define when this question is asked. Your PowerShell must return a True/False value that identifies if the question will be asked. In the given example, the answer to the question named `DHCP` (not shown in the example) is used to decide if this question should be asked or ignored.

The Secure property defines if the question should be asked as a SecureString and saved encrypted instead of in plaintext.  The property is optional and will be assumed false if not present. When a SecureString is used, the user will be asked to confirm their answer since it will not be visible on screen.

## Template Requirements Section

The requirements section allows the author of the template to define a list of requirements in order for the template to be used. Below is an example that shows all of the available properties.

```json
"Requirements":{
    "BaseVHD":{
        "OSName":["Windows"],
        "OSVersion":["10.0.*"],
        "OSEdition":["*Server*"]    
    },
    "DenyDefaultHostname":true
```

In the BaseVHD section we're able to ensure that the user is building a VM that meets the requirements for the template being used. The Operating System Name, Version, and Edition can be checked, an each can have an array of allowed values. Wildcards can be used, as shown, to test different values.

In addition to the BaseVHD requirements, one additional property is available named `DenyDefaultHostname`. When set to `True`, the user will be required to define a hostname and not have one autogenerated.

## Template Asset Section

The Asset section defines the VM that is being built. As shown in the example below, the Asset section must have a PostBuild section nested within it (no other sections are supported at this time.)

The PostBuild section can contain one or more actions that need to be taken on the VM after it is built.

```json
"Asset":{
    "PostBuild":[
            {
                "Name":"Install Remote Server Administration Tools",
                "Action":"Script",
                "Language":"PowerShell",
                "Script":[
                    "$WarningPreference = 'SilentlyContinue'",
                    "Get-WindowsFeature -Name RSAT* | Where { $_.InstallState -eq \"Available\" } | Install-WindowsFeature | Out-Null"
                ]
            },
```

In this example, the first step after the VM is built is to run a PowerShell script that installs the RSAT Windows Features. 

The `Name` and `Action` properties are required for each step in this section. The Name is displayed to the user as the action being taken, and the Action can be one of the following values:

### Script Action

When the action is defined as `Script`, a `Language` property and an array named `Script` should be supplied as shown in the example above. As the script must be stored in JSON, you may need to use escape characters in some of your code to ensure it can be saved in JSON properly (e.g., escaping backslashes) and read by Lably.

### Reboot Action

Use the `Reboot` action to reboot the VM and wait for it to come back online. By default, Lably will use the known administrator username and password to reconnect to the VM when it comes back online. During certain operations (such as promoting a server to a domain controller), the username may change as part of the reboot. If this happens, you can use the `ValidationCredential` section, as shown in this example, to change the credentials used.

```json
{
    "Name":"Reboot to Complete Setup",
    "Action":"Reboot",
    "ValidationCredential":{
        "Username":"[[NetBIOSName]]\\Administrator"
    }
}
```

Note that in this example, the variable `NetBIOSName` is defined elsewhere in the template.

## Template Properties Section

In this final section, you can define public properties to save in the Scaffold of the users Lab in order for other templates or VMs to take advantage of it. Below is an example of how variables created within the template can be saved.

```json
"Properties":{
    "Microsoft-ActiveDirectory-Forests":{
        "Value":"[[DomainName]]"
    },
    "Microsoft-ActiveDirectory-Domains":{
        "Value":"[[DomainName]]"
    }
}
```

You do not need to define all of your variables here, and in fact you may not need to save any. Variables and their values are stored privately within the Scaffold for your template, this section is only required for them to be _publicly_ accessible. 