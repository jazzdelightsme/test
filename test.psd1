#
# Module manifest for module 'test'
#
#

@{

# Script module or binary module file associated with this manifest.
RootModule = 'test.psm1'

# Version number of this module.
ModuleVersion = '1.0.0.1'

# ID used to uniquely identify this module
GUID = '7a3d0b31-a3e0-44b1-b525-b1c74e85f30d'

# Author of this module
Author = 'somebody'

# Company or vendor of this module
CompanyName = 'somebody'

# Copyright statement for this module
Copyright = '(c) 2013 somebody. All rights reserved.'

# Description of the functionality provided by this module
# Description = ''

# Minimum version of the Windows PowerShell engine required by this module
PowerShellVersion = '3.0'

# Name of the Windows PowerShell host required by this module
# PowerShellHostName = ''

# Minimum version of the Windows PowerShell host required by this module
# PowerShellHostVersion = ''

# Minimum version of the .NET Framework required by this module
DotNetFrameworkVersion = '4.5'

# Minimum version of the common language runtime (CLR) required by this module
# CLRVersion = ''

# Processor architecture (None, X86, Amd64) required by this module
# ProcessorArchitecture = ''

# Modules that must be imported into the global environment prior to importing this module
# RequiredModules = @()

# Assemblies that must be loaded prior to importing this module
# RequiredAssemblies = @()

# Script files (.ps1) that are run in the caller's environment prior to importing this module.
# ScriptsToProcess = @()

# Type files (.ps1xml) to be loaded when importing this module
# TypesToProcess = @()

# Format files (.ps1xml) to be loaded when importing this module
FormatsToProcess = @( 'test.Format.ps1xml' )

# Modules to import as nested modules of the module specified in RootModule/ModuleToProcess
# NestedModules = @()

# Functions to export from this module
FunctionsToExport = '*'

# Cmdlets to export from this module
CmdletsToExport = '*'

# Variables to export from this module
VariablesToExport = '*'

# Aliases to export from this module
AliasesToExport = '*'

# List of all modules packaged with this module.
# ModuleList = @()

# List of all files packaged with this module
FileList = @( 'test.psd1', 'test.psm1', 'test.Format.ps1xml' )

# Private data to pass to the module specified in RootModule/ModuleToProcess
PrivateData = @{ 'blah' = $False 
                 'PsModuleUtil.FileHashes' = @{ 'test.psd1' = '0F15B0799B4087E66FA2285BEB46F7B8A59BA70A';
                                                'test.psm1' = 'B914B860C23D118BB4E7A1B58FCB6648E5FA625B';
                                                'test.Format.ps1xml' = '03105D2763075E926C9E79B85FB876C437285C34';
                                              }
                 'PsModuleUtil.DevBuild' = $False
               }

}

