function Update-SVG {
    param (
        [string]$SVGMarkup,
        [string]$svgTitle = "Smiling Lady",
        [string]$svgFile = "output.svg"
    )

    # Save the SVG markup to a file
    $SVGMarkup | Out-File -FilePath $svgFile

    # Create a Windows Forms Form
    $form = New-Object System.Windows.Forms.Form
    $form.Text = $svgTitle
    $form.Size = New-Object System.Drawing.Size(500, 500)

    # Create a WebBrowser control
    $webBrowser = New-Object System.Windows.Forms.WebBrowser
    $webBrowser.Dock = 'Fill'

    # Load the SVG file into the WebBrowser control
    $webBrowser.Navigate((Convert-Path $svgFile))

    # Add the WebBrowser control to the form
    $form.Controls.Add($webBrowser)

    # Show the form
    $form.Add_Shown({$form.Activate()})
    $form.TopMost = $true
    [void]$form.ShowDialog()
}