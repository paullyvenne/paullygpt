# Import-Module .\UIModule.psm1
# Import-Module .\PaullyGPT-GUI.psm1
# $window = Invoke-PaullyGPTGUI
# #--------------------------------------------------------------------------------------------#

Import-Module .\Modules\ConfigurationModule.psm1
Import-Module .\Modules\OpenAIModule.psm1
Import-Module .\Modules\SpeechSynthesisModule.psm1
Import-Module .\Modules\SVGModule.psm1
Import-Module .\Modules\PromptInteractionModule.psm1
Import-Module .\Modules\SpecialFXModule.psm1
# Import-Module .\StorageAccountModule.psm1
Import-Module .\Modules\UIModule.psm1
Import-Module .\Modules\PaullyGPT.psm1
Import-Module .\Modules\PaullyGPT-GUI.psm1

$ErrorActionPreference = "stop"
$result = Invoke-PaullyGPTGUI
[Terminal.Gui.Application]::Top.Add($result.window)
[Terminal.Gui.Application]::Run()
[Terminal.Gui.Application]::Shutdown()