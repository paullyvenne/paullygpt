# Import-Module .\UIModule.psm1
# Import-Module .\PaullyGPT-GUI.psm1
# $window = Invoke-PaullyGPTGUI
# #--------------------------------------------------------------------------------------------#

Import-Module .\ConfigurationModule.psm1
Import-Module .\OpenAIModule.psm1
Import-Module .\SpeechSynthesisModule.psm1
Import-Module .\SVGModule.psm1
Import-Module .\PromptInteractionModule.psm1
Import-Module .\SpecialFXModule.psm1
# Import-Module .\StorageAccountModule.psm1
Import-Module .\UIModule.psm1
Import-Module .\PaullyGPT.psm1
Import-Module .\PaullyGPT-GUI.psm1

$ErrorActionPreference = "stop"
$result = Invoke-PaullyGPTGUI
[Terminal.Gui.Application]::Top.Add($result.window)
[Terminal.Gui.Application]::Run()
[Terminal.Gui.Application]::Shutdown()