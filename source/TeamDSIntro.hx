package;

import flixel.effects.FlxFlicker;
import flixel.addons.transition.FlxTransitionSprite.GraphicTransTileDiamond;
import flixel.addons.transition.FlxTransitionableState;
import flixel.addons.transition.TransitionData;
import states.TitleState;
import states.FlashingState;

#if MODS_ALLOWED
import sys.FileSystem;
import sys.io.File;
#end
import openfl.utils.AssetType;
import openfl.utils.Assets;

class TeamDSIntro extends MusicBeatState
{
	public static var leftState:Bool = false;

	var teamDSGuys:FlxSprite;
	var textThing:FlxSprite;
	var fadetoblack:FlxSprite;

	var skipDSIntro:Bool = false;

	override function create()
	{
		Paths.clearStoredMemory();
		Paths.clearUnusedMemory();

		#if LUA_ALLOWED
		Mods.pushGlobalMods();
		#end
		Mods.loadTopMod();
		
		FlxG.mouse.visible = false;
		super.create();
		FlxG.save.bind('funkin', CoolUtil.getSavePath());
		ClientPrefs.loadPrefs();

		#if MODS_ALLOWED
		if (FileSystem.exists(Paths.modFolders('data/skipdsintro.txt')))
		#else
		if (Assets.exists(Paths.getPreloadPath('data/skipdsintro.txt')))
		#end
		{
			skipDSIntro = true;
		}

		if(FlxG.save.data.flashing == null && !FlashingState.leftState) {
			FlxTransitionableState.skipNextTransIn = true;
			FlxTransitionableState.skipNextTransOut = true;
			MusicBeatState.switchState(new FlashingState());
		}
		else
		{
			if (skipDSIntro)
			{
				leftState = true;
				FlxTransitionableState.skipNextTransIn = true;
				FlxTransitionableState.skipNextTransOut = true;
				MusicBeatState.switchState(new TitleState());
			}
			else
			{
				new FlxTimer().start(1, function(tmr:FlxTimer) {
					var bg:FlxSprite = new FlxSprite().makeGraphic(FlxG.width, FlxG.height, FlxColor.WHITE);
					add(bg);

					teamDSGuys = new FlxSprite(0, 0);
					teamDSGuys.frames = Paths.getSparrowAtlas('Best-Friends');
					teamDSGuys.animation.addByPrefix('idle', 'Intro', 13, false);
					teamDSGuys.setGraphicSize(Std.int(teamDSGuys.width * 0.3));
					teamDSGuys.updateHitbox();
					teamDSGuys.screenCenter(X);
					teamDSGuys.antialiasing = true;
					add(teamDSGuys);

					textThing = new FlxSprite(0, 510);
					textThing.frames = Paths.getSparrowAtlas('Text');
					textThing.animation.addByPrefix('idle', 'Idle', 24, true);
					textThing.animation.addByPrefix('flash', 'Flash', 21, false);
					textThing.setGraphicSize(Std.int(textThing.width * 0.4));
					textThing.updateHitbox();
					textThing.screenCenter(X);
					textThing.visible = false;
					textThing.antialiasing = true;
					add(textThing);

					fadetoblack = new FlxSprite().makeGraphic(FlxG.width, FlxG.height, FlxColor.BLACK);
					fadetoblack.alpha = 0;
					add(fadetoblack);

					FlxG.sound.play(Paths.sound('daSound'));
					teamDSGuys.animation.play('idle');
					textThing.animation.play('idle');

					if(!leftState) {
						new FlxTimer().start(5, function(tmr:FlxTimer) {
							FlxTween.tween(fadetoblack, {alpha: 1}, 2, {onComplete: function(twn:FlxTween)
							{
								leftState = true;
								FlxTransitionableState.skipNextTransIn = true;
								FlxTransitionableState.skipNextTransOut = true;
								MusicBeatState.switchState(new TitleState());
							}});
						});
						new FlxTimer().start(1.851, function(tmr:FlxTimer) {
							if (FlxG.save.data.flashing)
								FlxG.camera.flash(FlxColor.WHITE, 0.2);
							textThing.visible = true;
						});
						new FlxTimer().start(2.478, function(tmr:FlxTimer) {
							textThing.animation.play('flash');
						});
					}
				});
			}
		}
	}

	override function update(elapsed:Float)
	{
		super.update(elapsed);
	}
}
