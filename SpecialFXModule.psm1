function ShowMatrix {
    param()
    $Host.UI.RawUI.BackgroundColor = "Black"
    # $Host.UI.RawUI.ForegroundColor = "Green"

    $colors = @("Green", "Cyan", "Blue")
    $matrixChars = @([char]::ConvertFromUtf32(63), [char]::ConvertFromUtf32(63), [char]::ConvertFromUtf32(63), [char]::ConvertFromUtf32(63), ' ')

    # dynamaically set to window width
    $MAX = $Host.UI.RawUI.WindowSize.Width 

    for ($j = 0; $j -lt 10; $j++) {
        $randomChar = ""

        for ($i = 0; $i -lt $MAX; $i++) {
            $randomChar += $matrixChars | Get-Random
        }

        $randomColor = $colors | Get-Random
        $Host.UI.RawUI.ForegroundColor = $randomColor
        Write-Host -NoNewline $randomChar

        # Add a small delay for the animation effect
        Start-Sleep -Milliseconds 10
    }
}

function ShowMatrix2 {
    param()
    $Host.UI.RawUI.BackgroundColor = "Black"

    # Array of random colors
    $colors = @("Green", "Cyan", "Magenta", "Yellow", "Blue", "Red")

    # Dynamically set to window width
    $MAX = $Host.UI.RawUI.WindowSize.Width
    $MAXROWS = 10

    for ($j = 0; $j -lt $MAXROWS; $j++) {
        for ($i = 0; $i -lt $MAX; $i++) {
            $randomChar = $matrixChars | Get-Random
            # Choose a random color for each character
            $randomColor = $colors | Get-Random
            $Host.UI.RawUI.ForegroundColor = $randomColor
        }

        Write-Host -NoNewline $randomChar
        # Add a small delay for the animation effect
        Start-Sleep -Milliseconds 10
    }
}