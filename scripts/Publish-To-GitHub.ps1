[CmdletBinding()]
param(
  [string]$RepoName = "r-zh-agent-workbench",
  [ValidateSet("public", "private")]
  [string]$Visibility = "public"
)

$ErrorActionPreference = "Stop"

if (-not (Get-Command gh -ErrorAction SilentlyContinue)) {
  throw "GitHub CLI is not installed or not on PATH."
}

gh auth status

if (-not (Test-Path -LiteralPath ".git")) {
  git init
}

git status --short

Write-Output "Creating GitHub repository: $RepoName ($Visibility)"
gh repo create $RepoName "--$Visibility" --source . --remote origin --push
