param(
    [string]$Repository = "G34A4OD/MovilSQA",
    [string]$Gerardo = "G34A4OD",
    [string]$Eva = "pizzatoev",
    [string]$Waldir = "riblawaldir",
    [switch]$Apply,
    [switch]$SyncPlan
)
$scriptArgs = @((Join-Path $PSScriptRoot "bootstrap_github.py"),"--repo",$Repository,"--gerardo",$Gerardo)
if ($Eva) { $scriptArgs += @("--eva",$Eva) }
if ($Waldir) { $scriptArgs += @("--waldir",$Waldir) }
if ($Apply) { $scriptArgs += "--apply" }
if ($SyncPlan) { $scriptArgs += "--sync-plan" }
& python @scriptArgs
exit $LASTEXITCODE
