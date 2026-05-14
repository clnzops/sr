[CmdletBinding()]
param()

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

function Invoke-ScriptRepoBootstrap {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory, Position = 0)]
        [ValidateNotNullOrEmpty()]
        [string]$Path,

        [Parameter()]
        [ValidatePattern('^[^/]+/[^/]+$')]
        [string]$Repository = 'clnzops/ps-scriptrepo',

        [Parameter()]
        [ValidateNotNullOrEmpty()]
        [string]$Ref = 'main',

        [Parameter(ValueFromRemainingArguments)]
        [object[]]$ScriptArguments = @()
    )

    $secureToken = Read-Host 'GitHub token' -AsSecureString
    $plainToken = [Net.NetworkCredential]::new('', $secureToken).Password
    $launcherPath = Join-Path $env:TEMP ('Invoke-ScriptRepoScript-' + [guid]::NewGuid() + '.ps1')
    $encodedRef = [Uri]::EscapeDataString($Ref)
    $launcherUri = "https://api.github.com/repos/$Repository/contents/launcher/Invoke-ScriptRepoScript.ps1?ref=$encodedRef"

    try {
        $headers = @{
            Authorization          = "Bearer $plainToken"
            Accept                 = 'application/vnd.github.raw+json'
            'X-GitHub-Api-Version' = '2022-11-28'
            'User-Agent'           = 'ps-scriptrepo-bootstrap'
        }

        Invoke-RestMethod -Uri $launcherUri -Headers $headers -Method Get -OutFile $launcherPath
        & $launcherPath -Repository $Repository -Path $Path -Ref $Ref -GitHubToken $secureToken -ScriptArguments $ScriptArguments
    }
    finally {
        $plainToken = $null
        $secureToken = $null
        Remove-Item -LiteralPath $launcherPath -Force -ErrorAction SilentlyContinue
    }
}

Set-Alias -Name sr -Value Invoke-ScriptRepoBootstrap -Scope Global
