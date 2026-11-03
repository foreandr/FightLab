param(
    [int]$Matches = 1000,
    [double]$Speed = 4,
    [int]$EvaluateEvery = 100,
    [int]$EvaluationPairs = 10,
    [int]$Seed = 731091,
    [ValidateSet('full', 'collision')]
    [string]$PoseMode = 'full'
)
$fightLabRoot = Split-Path -Parent $PSScriptRoot
$godotTrainer = Join-Path $PSScriptRoot 'Godot_v4.6-stable_win64_console.exe'
& $godotTrainer --headless --path $fightLabRoot --script res://scripts/ai/train_self_play.gd -- --matches=$Matches --speed=$Speed --eval-every=$EvaluateEvery --eval-pairs=$EvaluationPairs --seed=$Seed --pose-mode=$PoseMode
exit $LASTEXITCODE
