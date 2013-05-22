Set-StrictMode -Version Latest

<#
.SYNOPSIS
    Creates a new System.Collections.Generic.HashSet[string] set, using an OrdinalIgnoreCase comparer by default.
.DESCRIPTION
    The InitialContent parameter, if used, must consist of string objects.
#>
function New-StringSet
{
    [CmdletBinding()]
    param( [Parameter( Mandatory = $false )]
           [StringComparer] $Comparer = [StringComparer]::OrdinalIgnoreCase,

           [Parameter( Mandatory = $false )]
           [System.Collections.IEnumerable] $InitialContent = $null
         )

    begin { }
    end { }
    process
    {
        try
        {
            $set = New-Object System.Collections.Generic.HashSet[string] -ArgumentList @( $Comparer )
            if( $null -ne $InitialContent )
            {
                if( $InitialContent -is [System.Collections.Generic.IEnumerable[string]] )
                {
                    # We could also pass it to the constructor, but the constructor just calls UnionWith.
                    $set.UnionWith( $InitialContent )
                }
                else
                {
                    foreach( $thing in $InitialContent )
                    {
                        $null = $set.Add( $thing )
                    }
                }
            }
            $PSCmdlet.WriteObject( $set, $false ) # this is needed to prevent PS from "unrolling" it as a collection
        } finally { }
    }
} # end New-StringSet


<#
.SYNOPSIS
    Alters the given path to be relative to $PWD (if possible).
#>
function ConvertTo-RelativePath
{
    [CmdletBinding()]
    param( [Parameter( Mandatory = $true,
                       Position = 0,
                       ValueFromPipeline = $true,
                       ValueFromPipelineByPropertyName = $true )]
           [ValidateNotNullOrEmpty()]
           [string] $Path
         )

    begin { }
    end { }
    process
    {
        try
        {
            $workingDir = $PWD.Path
            # This takes care of the case where the working dir is the root of a PSDrive (like
            # "Test:\", as well as the case where the $Path is a filename that starts with the dir
            # name.
            if( $workingDir[ $workingDir.Length - 1 ] -ne ([char] '\') )
            {
                $workingDir += '\'
            }

            if( $Path.StartsWith( $workingDir ) )
            {
                return ".\" + $Path.Substring( $workingDir.ToString().Length )
            }
            else
            {
                return $Path
            }
        }
        finally { }
    }
} # end ConvertTo-RelativePath


<#
.SYNOPSIS
    Gets the absolute value of a TimeSpan.
#>
function ConvertTo-AbsoluteValue
{
    [CmdletBinding()]
    param( [Parameter( Mandatory = $true, Position = 0, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true )]
           [TimeSpan] $TimeSpan
         )
    process
    {
        try
        {
            if( $TimeSpan -lt [TimeSpan]::Zero )
            {
                return -$TimeSpan
            }
            else
            {
                return $TimeSpan
            }
        } finally { }
    }
}


<#
.SYNOPSIS
    Allows you to write a collection object to the pipeline without unrolling it.
#>
function Write-Collection
{
    [CmdletBinding()]
    param( [Parameter( Mandatory = $true, Position = 0 )] # Can't pipeline; would defeat the purpose
           [object] $Collection,

           [Parameter( Mandatory = $false )]
           [switch] $Unroll
         )

    begin { }
    end { }
    process
    {
        try
        {
            $PSCmdlet.WriteObject( $Collection, $Unroll )
        }
        finally { }
    }
} # end Write-Collection

