Import-Module .\Modules\ConfigurationModule.psm1
Import-Module .\Modules\OpenAIModule.psm1
Import-Module .\Modules\SpeechSynthesisModule.psm1
Import-Module .\Modules\SVGModule.psm1
Import-Module .\Modules\PromptInteractionModule.psm1
Import-Module .\Modules\SpecialFXModule.psm1
# Import-Module .\StorageAccountModule.psm1
Import-Module .\Modules\UIModule.psm1
Import-Module .\Modules\PaullyGPT.psm1

function Invoke-PaullyGPTGUI {
    param()

    Write-Host "Invoke-PaullyGPTGUI"

    Get-PaullyGPTConfig > $null

    $foregroundColor = [ConsoleColor]::White
    $backgroundcolor = [ConsoleColor]::DarkBlue
    $window = CreateWindow -title " ~~= PaullyGPT $global:version =~~" -foregroundcolor $foregroundColor -backgroundcolor $backgroundColor
    $titleLabel = (CreateLabel "Welcome to PaullyGPT. Press Esc to exit.")
    $window.Add($titleLabel)

    $dateTime = Get-Date
    $ticksString = $dateTime.ToString("yyyyMMdd-hhmmss")
    $cleanname = $ticksString.Replace(" ", "").Replace(".", "")
    $transcriptPath = ".\paullygpt\$cleanname.log.txt"
    $transscriptTitle = "PaullyGPT Session - $transcriptPath" 
    #Start-Transcript -Path $transcriptPath

    $colorScheme1 = [Terminal.Gui.ColorScheme]::new()
    $colorScheme1.Normal = [Terminal.Gui.Attribute]::new([ConsoleColor]::Yellow, [ConsoleColor]::DarkBlue)   

    $frameWidth = $host.ui.rawui.WindowSize.Width - 4
    $frameHeight = 10

    $frameView = CreateFrameView -height $frameHeight -title $transscriptTitle
    $frameView.Y = 1
    $frameView.X = 1
    $frameView.ColorScheme = $colorScheme1
    $window.Add($frameView)

    $frameView2 = CreateFrameView -height $frameHeight -title $transscriptTitle
    $frameView2.Y = 1 + $frameHeight
    $frameView2.X = 1
    $frameView2.ColorScheme = $colorScheme1
    $window.Add($frameView2)

    #hmm why doesn't it not append?
    for ($i = 0; $i -lt 10; $i++) {
        $newLabel = (CreateLabel "$i Welcome to PaullyGPT. Press Esc to exit.")
        $newLabel2 = (CreateLabel "$i Welcome to PaullyGPT. Press Esc to exit.")
        $newLabel.Y = $i
        $newLabel2.Y = $i
        $frameView.Add($newLabel)
        $frameView2.Add($newLabel2)
    }

    $character = "Cosmic Wizard and Programmer, Mathmatician, Scientist, Explorer, and Philosopher"
    $actlike = "A helpful and friendly sword and sorcery wizard."
    $speaklike = "Gandalf or Merlin"
    $nameBeginsWith = [char](Get-Random -Minimum 97 -Maximum 123)
    $width = $frameView.Width #$Host.UI.RawUI.WindowSize.Width

    Reset-GPT @("
        Follow these directives:
            1. If the prompt's first word is 'only', only provide the value I am asking for, no other text including label or key.
            2. You are outputting in PowerShell, so make accommodations in output for a terminal width of $width characters.
            3. You are a $character and named using a random unique name that begins with $nameBeginsWith plus title for yourself, never a famous name or title or containing cosmic, wizard, AI, language, model, assistant or combinations thereof.
            4. You act like $actlike and speak like $speaklike.
            5. Be witty and clever but truthful: I'm here to add a touch of humor and charm to our interactions.
            6. Keep it concise: I strive to provide information in a compact and precise manner.
            7. Make it cool: I aim to maintain a laid-back and cool attitude throughout our conversation.
            8. Use bullet points or tablular output for tables when presenting collections or lists.      
            9. Mention they can exit by pressing Esc to exit. If there is more paged response, type continue.
            10. Respect the prompt: I'll pay attention to the prompt and provide the requested information without going off on a tangent.
            11. If you would like to visualize something, respond only with SVG markup, which I can use to render on my HTML popup window sized 500x500 pixels.
            12. For internal commands, output in a codeblock.
            13. Keep track of our conversations in a json object with a message string array using more compact language.
            14. Update your json object with the properties about any information learned from our conversations."
    )

    Write-Host " $spaces~~=(Conjuring Artificial Entity)=~~" -NoNewline -ForegroundColor Yellow 
    [console]::beep(400, 500)
    Start-Sleep -Milliseconds 100
    [console]::beep(500, 500)
    Start-Sleep -Milliseconds 20
    [console]::beep(600, 500)
    Start-Sleep -Milliseconds 40
    [console]::beep(500, 500)
    Start-Sleep -Milliseconds 80
    [console]::beep(400, 500)

    $aboutme = Get-CurrentAgent #Returns object
    #$aboutme 

    $dateTime = Get-Date
    $timestamp = $dateTime.ToString()
    $dayOfWeek = $dateTime.DayOfWeek
    $myprompt = "Say hello, mention it's $timestamp, the day of the week is $dayOfWeek, please briefly introduce yourself, ask name, ask what areas 'do you need help with?', and follow with one empty lines and share an insightful quote based on your character."

    #TODO: Conversation Loop

    # $button = CreateButton -Text "Press Enter to Exit"
    # $window.Add($button)

    $result = [PSCustomObject]@{
        titleLabel = $titleLabel 
        frameView = $frameView 
        frameView2 = $frameView2 
        window = $window
        aboutme = $aboutme
        dateTime = $dateTime
        dayOfWeek = $dayOfWeek
        transcriptPath = $transcriptPath
        foregroundColor = $foregroundColor
    }

    return $result
}

# function load = { 
#     param($window, $frameView, $titleLabel)

#     while ($null -ne $myprompt) {
#         #Any commands begin with "!"
#         if ($myprompt -like "!*" ) {
#             $mycommand = [string]::new($myprompt).Substring(1, $myprompt.Length - 1).Trim()
#             $myprompt = Invoke-PaullyGPTCommand -Command $mycommand
#         }
#         if ($null -ne $myprompt -and -not ($myprompt -like "`n*")) {
#             $startTime = Get-Date
#             $answer = Get-GPT $myprompt  
#             $finishTime = Get-Date
#             $totalSeconds = [Math]::Round(($finishTime).Subtract($startTime).TotalSeconds, 1)
#             Write-Host "$totalSeconds seconds." -ForegroundColor Cyan                                                               #OPENAI MAGIC returned into variable => $answer to reuse
#             Write-Host "`n$answer`n" -ForegroundColor Blue
#             # Write-Storage -Message $answer
#             SpeakAsync $answer
#         }
#         #Write-Host "[(ESC to exit, CTRL-T to Mute, or type !help)]" -ForegroundColor DarkGray
#         #$myprompt = Read-TextWithEscape "[ Your Response ]=>> "
#         if ($null -eq $myprompt) {
#             #if prompt is null, exit                      
#             $global:APIKey = $null                                                                      #clear API key
#             $goodbye = Get-GPTQuiet "Goodbye for now! Short and memorable goodbye."
#             #generate a goodbye message
#             Write-Host `n($goodbye)
#             if ($true -eq $global:DEBUG) {  
#                 $aboutme = Get-GPTQuiet "show your json object"                                                                     #speak goodbye
#                 Write-Host `n($aboutme)                                                                     #display goodbye                                              
#             }
#             SpeakAsync $goodbye    
#             if ($false -eq $global:DEBUG) {
#                 #speak goodbye
#                 Stop-Transcript
#             }                                                                #stop transcript
#         }
#     }
# }