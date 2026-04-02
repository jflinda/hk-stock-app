$gitPath = "C:\Program Files\Git\bin\git.exe"
$repoDir = "C:\Users\jflin\WorkBuddy\20260329125422\stocktrading\frontend"
Set-Location $repoDir

Write-Host "=== Git Status ==="
& $gitPath status --short

Write-Host ""
Write-Host "=== Staging changes ==="
& $gitPath add -A

Write-Host ""
Write-Host "=== Committing ==="
& $gitPath commit -m "Sprint 4: Fix all analyze issues (0 warnings), rebuild release APK+AAB

- Replace flutter_chen_kchart with CustomPainter K-line chart (fixes 11 errors)
- Fix all deprecated APIs: withOpacity->withValues, print->debugPrint
- Fix use_super_parameters in all screens and widgets
- Fix background->surface in ColorScheme.dark (main.dart)
- Fix activeColor->activeThumbColor in Switch widget  
- Fix use_build_context_synchronously with mounted checks
- Fix DropdownButtonFormField value->initialValue (tools_screen)
- flutter analyze: No issues found (0 errors, 0 warnings)
- Release APK: 51.7MB, Release AAB: 42.4MB (signed with hkstock keystore)
- Update Sprint4_Testing_Guide.md"

Write-Host ""
Write-Host "=== Pushing to GitHub ==="
& $gitPath push origin main 2>&1
Write-Host "Exit: $LASTEXITCODE"
& $gitPath log --oneline -5
