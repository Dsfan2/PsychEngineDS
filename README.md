# Friday Night Funkin' - Psych Engine DS
A massive overhaul upgrade for [Psych Engine](https://gamebanana.com/mods/301107), intended to be a fix for the original's many issues that personally annoy me while keeping the good stuff from it. Also aiming to be more interchangable than the original. This is a replacement for my old DS Engine, hencewhy I've added some of the old DS Engine features.
I also fixed the manny bugs and issues from Psych Engine 0.7 source code.

## Installation:
Step 1: You must have [Haxe version 4.2.5](https://haxe.org/download/version/4.2.5/), seriously, stop using older or newer versions, it won't work!

Step 2: Open up a Command Prompt/PowerShell or Terminal, type `haxelib install hmm`

Step 3: After that finishes, type `haxelib run hmm install` in order to install all the needed libraries for *Psych Engine DS!*

Step 4: Enter all these into the command prompt:
        - haxelib git discord_rpc https://github.com/Aidan63/linc_discord-rpc.git
        - haxelib set flixel-addons 3.0.2
        - haxelib set flixel-tools 1.5.1
        - haxelib set flixel-ui 2.5.0
        - haxelib set flixel 5.2.2
        - haxelib set SScript 4.0.1
        - haxelib set tjson 1.4.0
        - haxelib set hxCodec 2.6.1 *{This is VERY important. DO NOT USE HXCODEC 3.0.2 AS IT WILL NOT COMPILE!}*
        - haxelib set lime 8.0.1
        - haxelib git linc_luajit https://github.com/superpowers04/linc_luajit.git
        - haxelib set openfl 9.2.1
This is to ensure all the needed libraries are at the correct version in order for the game to actually compile properly.

Once you do all that you should be good to go!

## Customization:

if you wish to disable things like *Lua Scripts* or *Video Cutscenes*, you can read over to `Project.xml`

inside `Project.xml`, you will find several variables to customize Psych Engine to your liking

to start you off, disabling Videos should be simple, simply Delete the line `"VIDEOS_ALLOWED"` or comment it out by wrapping the line in XML-like comments, like this `<!-- YOUR_LINE_HERE -->`

same goes for *Lua Scripts*, comment out or delete the line with `LUA_ALLOWED`, this and other customization options are all available within the `Project.xml` file

## Credits:
* Dsfan2 - Base Psych Engine Modifications and source code fixes
* CheezyLover - New Bowser Jr & Monika Sprites
* 5hark - New Pixel Monika & Dsfan2 Sprites
* Monika_Fan - Wendy O Koopa & New Pixel Bowser Jr Sprites
* Sourcandee - Help with FLPs
* DMZapp - Old Bowser Jr Sprites
* SANTIAGO GAMER FAN - Old Monika Sprites
* Viexy - Old Pixel Monika Sprites
* Shadow Mario - OG Programmer
* RiverOaken - OG Artist
* Yoshubs - OG Assistant Programmer

### Special Thanks
* kamvoy - New Pixel Boyfriend & New Pixel Girlfriend sprites
* DrkFon376 - Speakers Only Assets
* Sage_With_A_V - Left Side Boyfriend Sprites
* Elizm - BotPlay & Practice Text Sprites
* DusterBuster - Winning icons for Dad, Spooky, Pico, & Tankman
* Logan McOof - Boyfriend Soundfont in Week ?
* objectshowmaster - Monika Soundfont
* Tour de Pizza - Pizza Tower References & Sprites
* NoahGani1 - Peppino Soundfont (FNATPT)
* Rozebud - Creator of FPS Plus
* bbpanzu - Ex-Programmer
* Yoshubs - New Input System
* SqirraRNG - Crash Handler and Base code for Chart Editor's Waveform
* KadeDev - Fixed some cool stuff on Chart Editor and other PRs
* iFlicky - Composer of Psync and Tea Time, also made the Dialogue Sounds
* PolybiusProxy - .MP4 Video Loader Library (hxCodec)
* Keoiki - Note Splash Animations
* Smokey - Sprite Atlas Support
* Nebula the Zorua - LUA JIT Fork and some Lua reworks
_____________________________________

# Newly Added Features

## Switchable Playable Characters
* You can change playable characters in the settings menu. In the base engine you can play as Boyfriend, Bowser Jr, and Monika; but you can change this by editing the txt file: "playerChar.txt"
* NOTE: The max limit for player characters is 3 and the minimum limit is 1. If there is only 1 value the player character will be set to 1 by default and the option to swap player characters will dissapear from the options menu.


## Changing up the intro sequence a bit
* "title.json" in the images folder has gotten an upgrade and can now say anything as the last three strings of the intro.
* You can add "introText.txt" into your mod folder and the game will use that instead of the regular one.


## Changing up the story menu
* The story menu screen and black bar are now editable images.
* There's a new file called "storytxt.json" in the images folder. This can change the position, font, and color of the text strings in the story menu.


## Mod Support
* It's still here.
* You can now use Lua to create custom Main & Freeplay Menus without making a custom substate first! All you have to do in order to do this is create a Lua file in the `scripts` folder and call it `mainmenu.lua` or `freeplay.lua` for Main Menu & Freeplay respectively.


## Changes to story weeks:
  * The EASY, NORMAL, & HARD difficulties actually live up to their names now.
  * Different vocals depending on the player character you play as.
  * Cutscenes now don't play when in BotPlay or Practice Mode
  * Added the dodge mechanic to the third song of Week 4. Good luck.
  * In week 5, the Upper Boppers are different in Eggnog
  * In Week 5, the Bottom Boppers are different depending on which character you play as.
  * In Week 6, I brought back the random chance easter egg dialogue.
  * In Week 6, the dialogue will be different depending on which character you play as.
  * In Week 7, the cutscenes are now mp4 videos and will be different depending on which character you play as.


## New options menu features:
* I've added a song blurb that appears at the start of a song, along with the option to enable/disable it.
* A feature that turns hurt notes into instakill notes.
* Framerate is 120 by default
* Brought back the option to play Story Mode cutscenes in Freeplay
* Brought back the option to show the results screen at the end of a song (Only in Freeplay)
* Made a DS-Filter that seperates the hud camera from the main camera as if the game were on a Nintendo DS.
* You can make custom DS Borders for when you have the DS Filter on.
* You can change the combo sprites, and the health & time bars, as well as add custom ones.

## Other gameplay features:
* Note splashes are the official ones from the vanilla FNF by default.
* All health icons now have a winning sprite.
* Added a customizable fifth note. There's a file in the `data` folder labeled `ExtraNoteData.json`. You can use that to change the fifth note's properties.