$global:prevFore = $Host.UI.RawUI.ForegroundColor
$global:prevBack = $Host.UI.RawUI.BackgroundColor

#PROTOYPE

function PlayNote {
    Param(
        [int]$Frequency,
        [int]$Duration
    )

    [console]::Beep($Frequency, $Duration)
    # Start-Sleep -Milliseconds 20
}
function PlayIntroMusic {
    if($false -eq $global:DEBUG) {
        PlayNote -Frequency 440 -Duration 500
        PlayNote -Frequency 587 -Duration 500
        PlayNote -Frequency 659 -Duration 1000
        PlayNote -Frequency 784 -Duration 500
    }
}

function ShowMatrix {
    param()

    # Backup Colors
    $global:prevFore = $Host.UI.RawUI.ForegroundColor
    $global:prevBack = $Host.UI.RawUI.BackgroundColor

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

    # Restore colors
    $Host.UI.RawUI.ForegroundColor = $global:prevFore 
    $Host.UI.RawUI.BackgroundColor = $global:prevBack 
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


function GetStarPatternProbabilities {
    param (
        [string]$starPattern
    )

    $Probabilities = @{}

    # Remove newlines from the star pattern
    $starPattern = $starPattern -replace "`r`n", ""

    # Calculate the total characters (excluding newlines)
    $totalCharacters = $starPattern.Length

    # Count the occurrences of each character in the star pattern
    foreach ($character in $starPattern) {
        if ($character -notin $Probabilities.Keys) {
            $Probabilities[$character] = 0
        }
        $Probabilities[$character]++
    }

    # Calculate the probabilities for each character
    foreach ($key in $Probabilities.Keys) {
        $Probabilities[$key] = [Math]::Round($Probabilities[$key] / $totalCharacters, 2)
    }

    return $Probabilities
}

function GenerateStarPattern {
    param (
        [int]$Width,
        [int]$Height,
        [hashtable]$Probabilities,
        [int]$RandomSeed = (Get-Date).Millisecond
    )

    $random = New-Object System.Random($RandomSeed)
    $starPattern = ""

    # Create the new star pattern
    for ($y = 1; $y -le $Height; $y++) {
        for ($x = 1; $x -le $Width; $x++) {
            $randomValue = $random.NextDouble()
            $selectedCharacter = $null

            # Select the character based on the probabilities
            foreach ($key in $Probabilities.Keys) {
                if ($randomValue -lt $Probabilities[$key]) {
                    $selectedCharacter = $key
                    break
                }
                $randomValue -= $Probabilities[$key]
            }

            # If no character is selected, default to a whitespace
            if (-not $selectedCharacter) {
                $selectedCharacter = " "
            }

            $starPattern += $selectedCharacter
        }

        # Add a newline after each row
        $starPattern += "`r`n"
    }

    return $starPattern
}

function starExample {
    param()
    
    # Example usage
    $starPattern = "
        *  .  .       *
        .       .   *
    *   .    .       .
        .    *
    *    .   *    +
        *    .  .       *
        .       .   *
    *   .    .       .
        .    *
    *    .   *    +"

    $Probabilities = GetStarPatternProbabilities -starPattern $starPattern

    $Width = 20
    $Height = 10

    GenerateStarPattern -width $Width -height $Height -probabilities $Probabilities
}
