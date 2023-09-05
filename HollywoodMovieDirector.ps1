Import-Module .\ConfigurationModule.psm1
Import-Module .\OpenAIModule.psm1
Import-Module .\SpeechSynthesisModule.psm1
Import-Module .\SVGModule.psm1
Import-Module .\PromptInteractionModule.psm1
Import-Module .\SpecialFXModule.psm1
Import-Module .\PaullyGPT.psm1

#NOTICE: This is just a example of the cognitive abilities of GPT tailored to a specific fan scenario, 
#in this case the 1980s Lucasfilm golden era Indiana Jones. The above example are not intended as any claim on the intellectual property 
#of the Indiana Jones owners of or intended to be used for any commercial purposes but merely educational and learning purposes.

$global:DEBUG = $false
$global:MaxTokens = 500
$global:Temperature = 0.9
$global:MaxCompletionLoop = 5
$global:MaxExceptionLoop = 5

# function PlayHollywoodMelody {
#     $ebFrequency = 311.13  # E-flat
#     $fFrequency = 349.23   # F
#     $gFrequency = 392.00   # G
#     $cFrequency = 523.25   # C

#     $eighthDuration = 120   # 1/8th note duration in milliseconds
#     $halfDuration = 500    # Half note duration in milliseconds

#     PlayNote -Frequency $ebFrequency -Duration $halfDuration
#     PlayNote -Frequency $fFrequency -Duration $eighthDuration
#     PlayNote -Frequency $gFrequency -Duration $eighthDuration
#     PlayNote -Frequency $cFrequency -Duration $halfDuration
# }

$firstPrompt = "With flair start the introduction about our text game, Hollywood Movie Director, then some imaginary movies to direct with hilarious names and descriptions."
#OPTIMIZED VERSION OF THE ABOVE - COMPACTED AND SUMMARIZED
#------------------------------------------------------------------------------------------------------------#
#
#           Hollywood Movie Director GPT Game - Choose your own procedurally generated text based adventures game 
#
#------------------------------------------------------------------------------------------------------------#
$directives = "Try to keep prompts under 1000 characters. First the users to choose an movie first.
Prepare a choice of 3 unique base script titles, with suggested detailed choices such as  default genre, locations, scene variety, period, plots, climax,scene editing, special fx, twists, villians, and/or sidekicks that will be kept or changed by me. The game should be a choose-your-own-adventure text game based on the making a Hollywood movie theme, inspired by the Steven Spielburg.
Start the game as an upcoming Director, daydreaming at my desk in Hollywood. Notice letters on my desk, each representing a different script option and each when chosen have a written letter that you will write in quotes containing some correspondence to Steven. Each character should possess special skills and items that can affect the path and outcome of the game, they can also have inspiration from hollywood movies.
Once an base script is chosen, you as the director's smart but hilarious assistant, will ask me to go over all the major details if I want to override any of the base details, suggest up to 5 choices for the player or ask for me to enter others. These choices may include one that benefits from and include an option for looking around for clues that slowly lead to the right choice.
Mainly you will be making a movie using numbered options (which have some cost in money or risk) but sometimes I will be making text choices too like for naming or renaming scripts.
You will also encounter on-set mishaps and accidents and be able to do order retakes in my option. I can also change the script after hearing the actor or actress say it to me. I will be able to give them advice as well to improve the scene.
It should feel like I are making my own story, be it love, sci-fi, action, or comedy, 
Throughout the game, provide descriptions of the set and suggest scenes to do with exotic locals, risky transportation, striking sights, sounds, and smells, as well as deep thoughts about fortune, glory, life, death, and love. Mention strengths, hear tones of voice, and quirks, as well as those of the supporting characters, keeping them logically accurate based on the character's background.
Introduce the game's rules, objective, and background story. Ensure the following features are incorporated:
1) Allow the user to ask questions but always redirect them the current location and provide 5 choices of various risks for the player to choose from, including a fatal option or to look for clues. Depending on his cost of luck, I may be able to overcome the risks
2) One option is could be fatal and comically dark or gruesome but PG-13, while one or two others are dead ends that take I back, and the remaining are the different valid paths forward.
4) Continue to introduce exciting plotlines, twists, characters, obstacles, and lore based on the context of the location and overall story that is influenced by the script.
5) Continuously track time, score, cost, ratings, and objectives without resetting until the game starts over.
7) After each script is released as a movie, allow choices that affect the movie's ratings and box office success.
8) Finish the game with a win, lose, or quit screen, and ask if the player wants to play again. Describe conclusion the ending in a paragraph or two and ask the user if they want to try again.
10) The movie studio directors have to like the preview scripts each chapter for more funding of the entire movie or next."

#PlayHollywoodMelody
Invoke_PaullyGPT_V1 -Directives $directives -FirstPrompt $firstPrompt -ResumeLastSession $true -SaveSession $true -SessionFile "HollywoodMovieDirector.json"