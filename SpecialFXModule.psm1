$Host.UI.RawUI.BackgroundColor = "Black"
$Host.UI.RawUI.ForegroundColor = "Green"
$matrixChars = @('█', '▓', '▒', '░', ' ')

function ShowMatrix {
    # dynamaically set to window width
    $MAX = $Host.UI.RawUI.WindowSize.Width 

    for ($j = 0; $j -lt 10; $j++) {
        $randomChar = ""

        for ($i = 0; $i -lt $MAX; $i++) {
            $randomChar += $matrixChars | Get-Random
        }

        Write-Host -NoNewline $randomChar

        # Add a small delay for the animation effect
        Start-Sleep -Milliseconds 10
    }
}