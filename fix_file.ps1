$content = Get-Content lib\Admins.dart
$newContent = $content[0..2148] + $content[2639..($content.Length-1)]
$newContent | Set-Content lib\Admins.dart