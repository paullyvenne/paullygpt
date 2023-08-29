Import-Module Microsoft.PowerShell.ConsoleGuiTools 

$module = (Get-Module Microsoft.PowerShell.ConsoleGuiTools -List).ModuleBase
Add-Type -Path (Join-path $module Terminal.Gui.dll)


function CreateLabel {
    param(
        [String]$text = "Label"
    )
    $control = [Terminal.Gui.Label]::new()
    $control.Text = $text
    return $control
}

function CreateButton{
        param(
            [String]$text = "Enter"
        )
    $control = [Terminal.Gui.Button]::new()
    $control.Text = $text
    return control
}

function CreateFrameView {
    param(
        [String]$title = "Frame View"
    )

    $frameView = [Terminal.Gui.FrameView]::new()
    $frameView.Width = [Terminal.Gui.Dim]::Fill()
    $frameView.Height = [Terminal.Gui.Dim]::Fill()
    $frameView.Title = $title

    return $frameView
}

function CreateTopMenuBar {
    param(
        [String[]]$items = @()
    )

    $topMenuBar = [System.ConsoleColor]::DarkGray
    [System.Console]::BackgroundColor = $topMenuBar
    [System.Console]::Clear()

    $topMenuItems = @()
    foreach ($item in $items) {
        $topMenuItems += $item
    }

    $topMenuString = $topMenuItems -join " | "
    [System.Console]::SetCursorPosition(0, 0)
    [System.Console]::Write($topMenuString)

    $removeFormatting = [System.ConsoleColor]::Black
    [System.Console]::BackgroundColor = $removeFormatting

    return $topMenuBar
}

function CreateScrollView {
    param(
        [int]$width,
        [int]$height,
        [string]$content
    )

    $scrollView = [Terminal.Gui.ScrollView]::new()
    $scrollView.Width = $width
    $scrollView.Height = $height

    $textView = [Terminal.Gui.TextView]::new()
    $textView.Width = $width - 2
    $textView.Height = $height - 2
    $textView.Text = $content

    $scrollView.ContentView = $textView

    return $scrollView

    # Example usage:
    # $scrollView = CreateScrollView -x 2 -y 2 -width 40 -height 10 -content "This is the content of the scroll view."

    # # Add the scroll view to a window
    # $window = [Terminal.Gui.Window]::new()
    # $window.Add($scrollView)

    # # Run the application
    # $application = [Terminal.Gui.Application]::new()
    # $application.Run($window)
}

# function ShowMessageBox {
#     param(
#         [String]$title,
#         [String]$message
#     )

#     $messageBoxWidth = [Math]::Max($title.Length, $message.Length) + 6
#     $messageBoxHeight = 7
#     $messageBoxX = [Math]::Ceiling(([Terminal.Gui.Application]::TerminalSize.Width - $messageBoxWidth) / 2)
#     $messageBoxY = [Math]::Ceiling(([Terminal.Gui.Application]::TerminalSize.Height - $messageBoxHeight) / 2)

#     $window = [Terminal.Gui.Window]::new($title)
#     $window.X = $messageBoxX
#     $window.Y = $messageBoxY
#     $window.Width = $messageBoxWidth
#     $window.Height = $messageBoxHeight

#     $label = [Terminal.Gui.Label]::new()
#     $label.Text = $message
#     $label.X = 1
#     $label.Y = 1
#     $label.Width = $messageBoxWidth - 2

#     $button = [Terminal.Gui.Button]::new("OK")
#     $button.X = [Terminal.Gui.Pos]::Center()
#     $button.Y = $messageBoxHeight - 2
#     $button.Clicked = { $window.Close() }
#     $button.MouseClick = { $window.Close() }

#     $window.Add($label, $button)
#     $window.Run()

#     #[Terminal.Gui.Application]::Run($window)
# }

function CreateWindow {
    param(
            [string]$title,
            [ConsoleColor]$foregroundcolor = [ConsoleColor]::White,
            [ConsoleColor]$backgroundcolor = [ConsoleColor]::DarkBlue
        )
    [Terminal.Gui.Application]::Init()
    try {
        $foregroundColor = [ConsoleColor]::White
        $backgroundColor = [ConsoleColor]::DarkBlue
        
        $Window = [Terminal.Gui.Window]::new()
        $Window.Title = $title
        $Window.ColorScheme.Normal = [Terminal.Gui.Attribute]::new($foregroundColor, $backgroundColor)
        return $Window
    } catch  {
        [Terminal.Gui.MessageBox]::ErrorQuery("Failed", $_.Message)
    }
}



#----------------------------------------------
# [Terminal.Gui.MessageBox]::Query("Hello", "World")
# $result = [Terminal.Gui.MessageBox]::Query("Hello", "Go to IronmanSoftware.com?", @("Ok", "Cancel"))
# if ($result -eq 0)
# {
#     Start-Process https://www.ironmansoftware.com
# }
# #----------------------------------------------
# [Terminal.Gui.MessageBox]::ErrorQuery("Failed", "Catastrophic failure");
# #----------------------------------------------
# $Dialog = [Terminal.Gui.Dialog]::new()
# $Dialog.Title = "Whoa"
# $Textfield = [Terminal.Gui.Textfield]::new()
# $Textfield.Width = 10
# $Dialog.Add($Textfield)
# [Terminal.Gui.Application]::Run($Dialog)