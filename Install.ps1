<#
.SYNOPSIS
    Installs stuff.
#>
[CmdletBinding()]
param( [Parameter( Mandatory = $false, Position = 0 )]
       [ValidateNotNullOrEmpty()]
       [string] $InstallDirectory,

       [Parameter( Mandatory = $false, Position = 1 )]
       [ValidateNotNullOrEmpty()]
       [string] $SourceDirectory,

       [Parameter()]
       [Switch] $Force
     )

begin
{
    Set-StrictMode -Version Latest

    Add-Type @'
using System;
using System.Net;
using System.IO;

namespace PsModuleUtil
{
    public abstract class FileRetriever : IDisposable
    {
        public string SourceRoot { get; private set; }

        protected FileRetriever( string sourceRoot )
        {
            if( String.IsNullOrEmpty( sourceRoot ) )
                throw new ArgumentNullException( "sourceRoot" );

            SourceRoot = sourceRoot;
        } // end constructor

        public abstract string[] GetManifestList();

        public abstract string ReadManifestContent( string manifestName );

        public abstract void DownloadFile( string filename, string destPath, bool allowOverwrite );


        public static FileRetriever CreateFileRetriever( string sourceRoot )
        {
            if( String.IsNullOrEmpty( sourceRoot ) )
                throw new ArgumentNullException( "sourceRoot" );

            if( Directory.Exists( sourceRoot ) )
                return new FsFileRetriever( sourceRoot );

            if( sourceRoot.StartsWith( "http://", StringComparison.OrdinalIgnoreCase ) ||
                sourceRoot.StartsWith( "https://", StringComparison.OrdinalIgnoreCase ) )
            {
                return new HttpFileRetriever( sourceRoot );
            }

            throw new NotSupportedException( "Either the source does not exist, or the source type is not supported." );
        } // end CreateFileRetriever()

        public void Dispose()
        {
            Dispose( true );
            GC.SuppressFinalize( this );
        }

        protected virtual void Dispose( bool disposing )
        {
        }
    } // end class FileRetriever


    // Works for local directories or file shares (SMB).
    internal class FsFileRetriever : FileRetriever
    {
        public FsFileRetriever( string sourceRoot )
            : base( sourceRoot )
        {
            // This should get checked by the static factory method.
         // if( !Directory.Exists( SourceRoot ) )
         //     throw new ArgumentException( String.Format( "The directory \"{0}\" does not exist.", SourceRoot ) );
        }

        public override string[] GetManifestList()
        {
            return Directory.GetFiles( SourceRoot, "*.psd1" );
        }

        public override string ReadManifestContent( string manifestName )
        {
            if( String.IsNullOrEmpty( manifestName ) )
                throw new ArgumentNullException( "manifestName" );

            return File.ReadAllText( Path.Combine( SourceRoot, manifestName ) );
        }

        public override void DownloadFile( string filename, string destDir, bool allowOverwrite ) // TODO: Progress?
        {
            if( String.IsNullOrEmpty( filename ) )
                throw new ArgumentNullException( "filename" );

            if( String.IsNullOrEmpty( destDir ) )
                throw new ArgumentNullException( "destDir" );

            File.Copy( Path.Combine( SourceRoot, filename ),
                       Path.Combine( destDir, filename ),
                       allowOverwrite );
        }
    } // end class FsFileRetriever


    // Works for files distributed via the Web (ex. GitHub).
    internal sealed class HttpFileRetriever : FileRetriever
    {
        private const string c_ManifestListFile = "_PsModuleUtil.ManifestList";
        private static readonly string[] sm_lineDelims = new string[] { Environment.NewLine, "\n" };

        private WebClient m_wc;

        public HttpFileRetriever( string sourceRoot )
            : base( sourceRoot )
        {
            m_wc = new WebClient();
            m_wc.BaseAddress = SourceRoot;
        }

        public override string[] GetManifestList()
        {
            try
            {
                string listContent = m_wc.DownloadString( c_ManifestListFile );
                return listContent.Split( sm_lineDelims, StringSplitOptions.RemoveEmptyEntries );
            }
            catch( System.Net.WebException we )
            {
                throw new InvalidOperationException( String.Format( "Could not find a manifest list file at {0}. If there is a valid PS module there, it is not enabled for installation over http[s] via Install.ps1. <TODO: instructions to enable it>",
                                                                    SourceRoot ),
                                                     we );
            }
        }

        public override string ReadManifestContent( string manifestName )
        {
            try
            {
                return m_wc.DownloadString( manifestName );
            }
            catch( System.Net.WebException we )
            {
                throw new FileNotFoundException( String.Format( "Couldn't get file {0} from {1}.",
                                                                manifestName,
                                                                SourceRoot ),
                                                 we );
            }
        }

        public override void DownloadFile( string filename, string destDir, bool allowOverwrite ) // TODO: Progress?
        {
            // I'll just let the other APIs throw.
         // if( String.IsNullOrEmpty( filename ) )
         //     throw new ArgumentNullException( "filename" );

         // if( String.IsNullOrEmpty( destDir ) )
         //     throw new ArgumentNullException( "destDir" );

            string destFile = Path.Combine( destDir, filename );
            // TODO: Wlil this overwrite? I'm guessing not...
            try
            {
                m_wc.DownloadFile( filename, destFile );
            }
            catch( System.Net.WebException we )
            {
                throw new FileNotFoundException( String.Format( "Couldn't get file {0} from {1}.",
                                                                filename,
                                                                SourceRoot ),
                                                 we );
            }
        }

        protected override void Dispose( bool disposing )
        {
            if( disposing && (null != m_wc) )
            {
                m_wc.Dispose();
                m_wc = null;
            }
        } // end Dispose()
    } // end class FsFileRetriever

    // FUTURE: .zip? FTP? Self-extracting PS1 (all content is stored in the ps1)?
}
'@
}


process
{
    function _TryFindSource()
    {
        try
        {
            # This means $PSScriptRoot isn't set, so we are being invoke
            # dynamically. We just need to figure out where from.
            #return $MyInvocation
            #return (Get-PSCallstack)
            $s = Get-PSCallstack
            $global:TheStack = $s
            if( $s.Count -lt 3 )
            {
                return
            }
            $candidates = $s[ 2..($s.Count - 1) ] | % {

                $frame = $_
                if( $null -eq $frame.InvocationInfo.MyCommand )
                {
                    return
                }

                $c = $frame.InvocationInfo.MyCommand.Definition
                $tokens = $null
                $errors = $null
                $sba = [System.Management.Automation.Language.Parser]::ParseInput( $c, [ref] $tokens, [ref] $errors )
                # There shouldn't be any errors... this was already parsed and is executing!
                if( $errors -and ($errors.Count -gt 0) )
                {
                    throw $errors[ 0 ]
                }
                $installPs1 = 'Install.ps1'
                $tokens | % {
                    if( ($_.Kind -eq 'StringLiteral') -and ($_.Value.EndsWith( $installPs1, [StringComparison]::OrdinalIgnoreCase )) )
                    {
                        #$_.Value
                        $s = $_.Value
                        if( $s.Length -gt $installPs1.Length )
                        {
                            $s.Substring( 0, $s.Length - $installPs1.Length )
                        }
                    }
                } # end foreach( token )
            } # end foreach( stack frame )
            $candidates
        }
        finally { }
    } # end _TryFindSource()


    function _TryCreateFileRetriever()
    {
        try
        {
            if( $SourceDirectory )
            {
                return [PsModuleUtil.FileRetriever]::CreateFileRetriever( $SourceDirectory )
            }

            try
            {
                $SourceDirectory = $PSScriptRoot
            }
            catch
            {
                # Ignore. This means we are being invoked dynamically somehow.
            }

            if( $SourceDirectory )
            {
                return [PsModuleUtil.FileRetriever]::CreateFileRetriever( $SourceDirectory )
            }

            # We must be invoked dynamically. Let's try and guess where we are
            # being installed from. (If this fails, the user will be required
            # to tell us where to install from.)
            $errors = @()
            [string[]] $sourcesTried = @()
            $retriever = _TryFindSource | % {
                try
                {
                    $candidateSourceRoot = $_
                    $sourcesTried += $candidateSourceRoot
                    $retriever = [PsModuleUtil.FileRetriever]::CreateFileRetriever( $candidateSourceRoot )
                    return $retriever
                }
                catch
                {
                    $errors += $_
                }
            } | Select-Object -First 1

            if( !$retriever )
            {
                # We couldn't find anything.
                throw ("Could not detect the installation source; please run again, but with the -SourceDirectory parameter. Source locations attempted: $([string]::Join( ', ', $sourcesTried )).")
            }
            $retriever
        }
        finally { }
    } # end _TryCreateFileRetriever


    try
    {
        $retriever = _TryCreateFileRetriever

        Write-Verbose "The installation source is: $($retriever.SourceRoot)"

        $manifests = $retriever.GetManifestList()

        $manifests
    }
    finally { }
}

end { }

