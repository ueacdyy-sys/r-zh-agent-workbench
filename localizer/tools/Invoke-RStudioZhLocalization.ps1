[CmdletBinding(SupportsShouldProcess = $true)]
param(
  [ValidateSet("Inspect", "Install", "Remove", "Restore")]
  [string]$Mode = "Inspect",

  [string]$RStudioRoot = "C:\Program Files\RStudio",

  [string]$DictionaryPath = "",

  [string]$BackupRoot = (Join-Path $env:LOCALAPPDATA "RStudioZhLocalizer\backups"),

  [string]$ExpectedVersion = "2026.05.0+218",

  [string]$BackupFile = "",

  [switch]$SkipVersionCheck
)

$ErrorActionPreference = "Stop"
$encoding = [System.Text.Encoding]::UTF8
$begin = "/* >>> rstudio-zh-runtime-overlay >>> */"
$end = "/* <<< rstudio-zh-runtime-overlay <<< */"

if ([string]::IsNullOrWhiteSpace($DictionaryPath)) {
  $DictionaryPath = Join-Path (Split-Path -Parent $PSScriptRoot) "dictionary\rstudio-2026.05.0-zh-CN.tsv"
}

function Get-RStudioPaths {
  param([string]$Root)

  $appRoot = Join-Path $Root "resources\app"
  $packageJson = Join-Path $appRoot "package.json"
  $nocacheFile = Join-Path $appRoot "www\rstudio\rstudio.nocache.js"

  [pscustomobject]@{
    AppRoot = $appRoot
    PackageJson = $packageJson
    NocacheFile = $nocacheFile
  }
}

function Get-RStudioVersion {
  param([string]$PackageJson)

  if (-not (Test-Path -LiteralPath $PackageJson)) {
    throw "RStudio package metadata not found: $PackageJson"
  }

  $json = Get-Content -LiteralPath $PackageJson -Raw -Encoding UTF8 | ConvertFrom-Json
  return [string]$json.version
}

function Read-TranslationMap {
  param([string]$Path)

  if (-not (Test-Path -LiteralPath $Path)) {
    throw "Dictionary not found: $Path"
  }

  $map = [ordered]@{}
  foreach ($line in (Get-Content -LiteralPath $Path -Encoding UTF8)) {
    if ([string]::IsNullOrWhiteSpace($line) -or $line.StartsWith("#")) { continue }
    $parts = $line -split "`t", 2
    if ($parts.Count -ne 2) { continue }

    $from = $parts[0].Trim().Trim("'").Replace("\'", "'")
    $to = $parts[1].Trim().Trim("'").Replace("\'", "'")
    if ([string]::IsNullOrWhiteSpace($from) -or [string]::IsNullOrWhiteSpace($to)) { continue }
    if ($from.Length -lt 2) { continue }

    $keys = New-Object "System.Collections.Generic.HashSet[string]"
    [void]$keys.Add($from)
    [void]$keys.Add($from.Replace("_", ""))

    foreach ($key in $keys) {
      if (-not [string]::IsNullOrWhiteSpace($key) -and $key.Length -ge 2) {
        $map[$key] = $to
      }
    }
  }

  return $map
}

function New-Backup {
  param(
    [string]$SourceFile,
    [string]$BackupDirectory
  )

  New-Item -ItemType Directory -Force -Path $BackupDirectory | Out-Null
  $stamp = Get-Date -Format "yyyyMMddHHmmss"
  $backup = Join-Path $BackupDirectory ("rstudio.nocache.js.{0}.bak" -f $stamp)
  Copy-Item -LiteralPath $SourceFile -Destination $backup -Force
  return $backup
}

function Remove-OverlayBlock {
  param([string]$Text)

  $pattern = [regex]::Escape($begin) + "[\s\S]*?" + [regex]::Escape($end)
  return [regex]::Replace($Text, $pattern, "").TrimEnd() + [Environment]::NewLine
}

function New-Overlay {
  param([System.Collections.IDictionary]$Map)

  $json = $Map | ConvertTo-Json -Compress -Depth 2
  return @"
$begin
(function () {
  if (window.__rstudioZhOverlayInstalled) return;
  window.__rstudioZhOverlayInstalled = true;

  var dictionary = $json;
  var attrs = ["title", "aria-label", "placeholder", "alt"];

  function translateText(value) {
    if (!value) return value;
    var normalized = String(value).replace(/\u00a0/g, " ");
    var trimmed = normalized.trim();
    var translated = dictionary[trimmed];
    if (!translated) return value;
    return String(value).replace(trimmed, translated);
  }

  function translateElement(el) {
    if (!el || el.nodeType !== 1) return;
    for (var i = 0; i < attrs.length; i++) {
      var name = attrs[i];
      if (el.hasAttribute && el.hasAttribute(name)) {
        var oldValue = el.getAttribute(name);
        var newValue = translateText(oldValue);
        if (newValue !== oldValue) el.setAttribute(name, newValue);
      }
    }
  }

  function translateTree(root) {
    if (!root) return;
    if (root.nodeType === 3) {
      var next = translateText(root.nodeValue);
      if (next !== root.nodeValue) root.nodeValue = next;
      return;
    }
    if (root.nodeType !== 1 && root.nodeType !== 9 && root.nodeType !== 11) return;
    if (root.nodeType === 1) translateElement(root);

    var all = root.querySelectorAll ? root.querySelectorAll("*") : [];
    for (var a = 0; a < all.length; a++) translateElement(all[a]);

    var walker = document.createTreeWalker(root, NodeFilter.SHOW_TEXT, {
      acceptNode: function (node) {
        if (!node.nodeValue || !node.nodeValue.trim()) return NodeFilter.FILTER_REJECT;
        var parent = node.parentElement;
        if (!parent) return NodeFilter.FILTER_REJECT;
        var tag = parent.tagName;
        if (tag === "SCRIPT" || tag === "STYLE" || tag === "TEXTAREA") return NodeFilter.FILTER_REJECT;
        return NodeFilter.FILTER_ACCEPT;
      }
    });

    var nodes = [];
    while (walker.nextNode()) nodes.push(walker.currentNode);
    for (var n = 0; n < nodes.length; n++) {
      var oldText = nodes[n].nodeValue;
      var newText = translateText(oldText);
      if (newText !== oldText) nodes[n].nodeValue = newText;
    }
  }

  function start() {
    translateTree(document.body);
    var pending = false;
    var observer = new MutationObserver(function (mutations) {
      for (var i = 0; i < mutations.length; i++) {
        var mutation = mutations[i];
        if (mutation.type === "characterData") translateTree(mutation.target);
        if (mutation.type === "attributes") translateElement(mutation.target);
        for (var j = 0; j < mutation.addedNodes.length; j++) translateTree(mutation.addedNodes[j]);
      }
      if (!pending) {
        pending = true;
        setTimeout(function () {
          pending = false;
          translateTree(document.body);
        }, 50);
      }
    });
    observer.observe(document.body, {
      childList: true,
      subtree: true,
      characterData: true,
      attributes: true,
      attributeFilter: attrs
    });
    setInterval(function () { translateTree(document.body); }, 1000);
  }

  if (document.body) start();
  else document.addEventListener("DOMContentLoaded", start);
})();
$end
"@
}

$paths = Get-RStudioPaths -Root $RStudioRoot
if (-not (Test-Path -LiteralPath $paths.NocacheFile)) {
  throw "RStudio bootstrap file not found: $($paths.NocacheFile)"
}

$version = Get-RStudioVersion -PackageJson $paths.PackageJson
if (-not $SkipVersionCheck -and $version -ne $ExpectedVersion) {
  throw "Unsupported RStudio version: $version. Expected: $ExpectedVersion. Re-run with -SkipVersionCheck only after manual verification."
}

$map = Read-TranslationMap -Path $DictionaryPath
$text = [System.IO.File]::ReadAllText($paths.NocacheFile, $encoding)
$hasOverlay = $text.Contains($begin)

if ($Mode -eq "Inspect") {
  [pscustomobject]@{
    RStudioRoot = $RStudioRoot
    Version = $version
    ExpectedVersion = $ExpectedVersion
    NocacheFile = $paths.NocacheFile
    DictionaryPath = (Resolve-Path -LiteralPath $DictionaryPath).Path
    TranslationEntries = $map.Count
    OverlayInstalled = $hasOverlay
    BackupRoot = $BackupRoot
  } | Format-List
  return
}

$running = Get-Process -ErrorAction SilentlyContinue | Where-Object { $_.ProcessName -match "^(rstudio|rsession)" }
if ($running) {
  Write-Warning "RStudio is running. Changes will be visible after restarting RStudio."
}

if ($Mode -eq "Install") {
  if ($PSCmdlet.ShouldProcess($paths.NocacheFile, "install Chinese runtime overlay")) {
    $backup = New-Backup -SourceFile $paths.NocacheFile -BackupDirectory $BackupRoot
    $clean = Remove-OverlayBlock -Text $text
    $overlay = New-Overlay -Map $map
    [System.IO.File]::WriteAllText($paths.NocacheFile, $clean.TrimEnd() + [Environment]::NewLine + $overlay + [Environment]::NewLine, $encoding)
    Write-Output "Installed runtime overlay: $($paths.NocacheFile)"
    Write-Output "Backup: $backup"
  }
  return
}

if ($Mode -eq "Remove") {
  if ($PSCmdlet.ShouldProcess($paths.NocacheFile, "remove Chinese runtime overlay")) {
    $backup = New-Backup -SourceFile $paths.NocacheFile -BackupDirectory $BackupRoot
    $clean = Remove-OverlayBlock -Text $text
    [System.IO.File]::WriteAllText($paths.NocacheFile, $clean, $encoding)
    Write-Output "Removed runtime overlay: $($paths.NocacheFile)"
    Write-Output "Backup: $backup"
  }
  return
}

if ($Mode -eq "Restore") {
  if ([string]::IsNullOrWhiteSpace($BackupFile)) {
    throw "Mode Restore requires -BackupFile."
  }
  if (-not (Test-Path -LiteralPath $BackupFile)) {
    throw "Backup file not found: $BackupFile"
  }
  if ($PSCmdlet.ShouldProcess($paths.NocacheFile, "restore backup $BackupFile")) {
    $safetyBackup = New-Backup -SourceFile $paths.NocacheFile -BackupDirectory $BackupRoot
    Copy-Item -LiteralPath $BackupFile -Destination $paths.NocacheFile -Force
    Write-Output "Restored: $($paths.NocacheFile)"
    Write-Output "From: $BackupFile"
    Write-Output "Safety backup before restore: $safetyBackup"
  }
}
