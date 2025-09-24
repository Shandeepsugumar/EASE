# PowerShell script to fix Admins.dart by removing dead code after line 2582
$content = Get-Content "lib\Admins.dart"
$outputLines = @()
$foundEnd = $false

for ($i = 0; $i -lt $content.Length; $i++) {
    $line = $content[$i]
    
    # Add lines up to line 2582 (0-indexed would be 2581)
    if ($i -le 2581) {
        $outputLines += $line
    }
    
    # Stop after we find the proper end of the class
    if ($i -eq 2581 -and $line.Trim() -eq "}") {
        break
    }
}

# Write the corrected content back to the file
$outputLines | Out-File "lib\Admins.dart" -Encoding UTF8
Write-Host "Fixed Admins.dart by removing dead code after the main class"