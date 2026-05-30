[CmdletBinding()]
param(
  [switch]$SkipRCheck,
  [switch]$SkipLocalizerInspect,
  [switch]$SkipGitHubAuth
)

$ErrorActionPreference = "Stop"

function Write-Step {
  param([string]$Message)
  Write-Output ""
  Write-Output ("==> " + $Message)
}

function Assert-NoOutput {
  param(
    [string]$Name,
    [scriptblock]$Script
  )

  $output = & $Script
  if ($output) {
    Write-Output $output
    throw "$Name failed."
  }
  Write-Output "$Name OK"
}

$repoRoot = (Resolve-Path -LiteralPath (Join-Path $PSScriptRoot "..")).Path
Set-Location $repoRoot

Write-Step "Git state"
$branch = git branch --show-current
$head = git log --oneline -1
Write-Output "Branch: $branch"
Write-Output "Head: $head"
Assert-NoOutput -Name "Git working tree clean" -Script { git status --short }

Write-Step "Forbidden release artifacts"
Assert-NoOutput -Name "Forbidden file scan" -Script {
  Get-ChildItem -Recurse -Force -File |
    Where-Object {
      $_.FullName -notmatch "\\.git\\" -and
      (
        $_.FullName -match "\\.Rcheck\\" -or
        $_.Name -match "\.tar\.gz$" -or
        $_.FullName -match "\\verification" -or
        $_.FullName -match "\\backups\\" -or
        $_.FullName -match "\\user-state" -or
        $_.FullName -match "\\\.positai\\" -or
        $_.FullName -match "Program Files_RStudio" -or
        $_.Name -match "\.cache\.js$"
      )
    } |
    ForEach-Object { $_.FullName }
}

Write-Step "High-confidence secret scan"
Assert-NoOutput -Name "Secret pattern scan" -Script {
  $patterns = @(
    "ghp_[A-Za-z0-9_]{20,}",
    "github_pat_[A-Za-z0-9_]{30,}",
    "sk-[A-Za-z0-9]{32,}",
    "AIza[0-9A-Za-z_-]{35}",
    "xox[baprs]-[0-9A-Za-z-]{20,}",
    "-----BEGIN (RSA |OPENSSH |EC |DSA )?PRIVATE KEY-----"
  )
  foreach ($pattern in $patterns) {
    rg -n --hidden --glob "!.git/**" --glob "!*.png" -- $pattern . 2>$null
  }
}

Write-Step "R package base tests"
Push-Location (Join-Path $repoRoot "packages\rstudiozhai")
try {
  & "C:\Program Files\R\R-4.6.0\bin\x64\Rscript.exe" tests\base\run-tests.R
  if ($LASTEXITCODE -ne 0) { throw "R base tests failed." }
} finally {
  Pop-Location
}

if (-not $SkipRCheck) {
  Write-Step "R CMD build/check"
  $checkRoot = Join-Path $env:TEMP ("r-zh-agent-workbench-check-" + (Get-Date -Format "yyyyMMddHHmmss"))
  New-Item -ItemType Directory -Force -Path $checkRoot | Out-Null
  Push-Location $checkRoot
  try {
    & "C:\Program Files\R\R-4.6.0\bin\x64\R.exe" CMD build (Join-Path $repoRoot "packages\rstudiozhai") --no-build-vignettes
    if ($LASTEXITCODE -ne 0) { throw "R CMD build failed." }
    $tar = Get-ChildItem -LiteralPath $checkRoot -Filter "rstudiozhai_*.tar.gz" | Select-Object -First 1
    if (-not $tar) { throw "Built tarball not found in $checkRoot." }
    & "C:\Program Files\R\R-4.6.0\bin\x64\R.exe" CMD check --no-manual --no-build-vignettes $tar.FullName
    if ($LASTEXITCODE -ne 0) { throw "R CMD check failed." }
  } finally {
    Pop-Location
  }
}

if (-not $SkipLocalizerInspect) {
  Write-Step "Localizer inspect"
  & powershell -ExecutionPolicy Bypass -File (Join-Path $repoRoot "localizer\tools\Invoke-RStudioZhLocalization.ps1") -Mode Inspect
  if ($LASTEXITCODE -ne 0) { throw "Localizer inspect failed." }
}

if (-not $SkipGitHubAuth) {
  Write-Step "GitHub auth"
  gh auth status
  if ($LASTEXITCODE -ne 0) {
    throw "GitHub CLI is not authenticated. Run: gh auth login"
  }
} else {
  Write-Step "GitHub auth"
  Write-Output "Skipped by -SkipGitHubAuth."
}

Write-Output ""
Write-Output "Release readiness checks passed."
