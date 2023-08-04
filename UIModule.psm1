Import-Module Microsoft.PowerShell.ConsoleGuiTools 

$module = (Get-Module Microsoft.PowerShell.ConsoleGuiTools -List).ModuleBase
Add-Type -Path (Join-path $module Terminal.Gui.dll)

[Terminal.Gui.Application]::Init()


function Invoke_TerminalGuiWindow {
    param(
        [string]$title = " ~~= PaullyGPT 1.0 =~~"
    )
    # # Create a script block from the string
    # $ScriptBlock = [ScriptBlock]::Create($ScriptBlock)
    # $ScriptBlock.Invoke()

    # Create a terminal window
    $Window = [Terminal.Gui.Window]::new()
    $Window.Title = $title
    #$Window.ForegroundColor = [Terminal.Gui.Attribute]::new([ConsoleColor]::Green, [ConsoleColor]::Black)


    $Button = [Terminal.Gui.Button]::new()
    $Button.Text = "Button" 
    $Window.Add($Button)

    $Label = [Terminal.Gui.Label]::new()
$Label.Text = "Enable Disco"
$Label.Height = 1
$Label.Width = 20
$Window.Add($Label)

$Checkbox = [Terminal.Gui.Checkbox]::new()
$Checkbox.Checked = $true
$Checkbox.X = [Terminal.Gui.Pos]::Right($Label)
$Window.Add($Checkbox)

$Frame1 = [Terminal.Gui.FrameView]::new()
$Frame1.Width = [Terminal.Gui.Dim]::Percent(50)
$Frame1.Height = [Terminal.Gui.Dim]::Fill()
$Frame1.Title = "Frame 1"
$Window.Add($Frame1)

$Frame2 = [Terminal.Gui.FrameView]::new()
$Frame2.Width = [Terminal.Gui.Dim]::Percent(50)
$Frame2.Height = [Terminal.Gui.Dim]::Fill()
$Frame2.X = [Terminal.Gui.Pos]::Right($Frame1)
$Frame2.Title = "Frame 2"
$Window.Add($Frame2)

$Label1 = [Terminal.Gui.Label]::new()
$Label1.Text = "Frame 1 Content"
$Label1.Height = 1
$Label1.Width = 20
$Frame1.Add($Label1)

$Label2 = [Terminal.Gui.Label]::new()
$Label2.Text = "Frame 2 Content"
$Label2.Height = 1
$Label2.Width = 20
$Frame2.Add($Label2)

$Textfield = [Terminal.Gui.Textfield]::new()
$Textfield.Text = "What now?" 
$Textfield.Width = [Terminal.Gui.Dim]::Fill()
$Frame2.Add($Textfield)

    return $Window
}

$window = Invoke_TerminalGuiWindow -title " ~~= PaullyGPT 1.0 =~~"
[Terminal.Gui.Application]::Top.Add($window)
[Terminal.Gui.Application]::Run()
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