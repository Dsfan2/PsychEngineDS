package states.stages;

import flixel.math.FlxPoint;
import animateatlas.AtlasFrameMaker;

import states.stages.objects.*;
import substates.GameOverSubstate;
import objects.Character;

import cutscenes.DialogueBoxPsych;

#if VIDEOS_ALLOWED
import hxcodec.VideoHandler as NetStreamHandler;
import hxcodec.VideoSprite;
#end

class Tank extends BaseStage
{
	var tankWatchtower:BGSprite;
	var tankGround:BackgroundTank;
	var tankmanRun:FlxTypedGroup<TankmenBG>;
	var foregroundSprites:FlxTypedGroup<BGSprite>;

	var tankascends:VideoSprite;

	override function create()
	{
		var sky:BGSprite = new BGSprite('stages/tank/tankSky', -400, -400, 0, 0);
		add(sky);

		if(!ClientPrefs.data.lowQuality)
		{
			var clouds:BGSprite = new BGSprite('stages/tank/tankClouds', FlxG.random.int(-700, -100), FlxG.random.int(-20, 20), 0.1, 0.1);
			clouds.active = true;
			clouds.velocity.x = FlxG.random.float(5, 15);
			add(clouds);

			var mountains:BGSprite = new BGSprite('stages/tank/tankMountains', -300, -20, 0.2, 0.2);
			mountains.setGraphicSize(Std.int(1.2 * mountains.width));
			mountains.updateHitbox();
			add(mountains);

			var buildings:BGSprite = new BGSprite('stages/tank/tankBuildings', -200, 0, 0.3, 0.3);
			buildings.setGraphicSize(Std.int(1.1 * buildings.width));
			buildings.updateHitbox();
			add(buildings);
		}

		var ruins:BGSprite = new BGSprite('stages/tank/tankRuins',-200,0,.35,.35);
		ruins.setGraphicSize(Std.int(1.1 * ruins.width));
		ruins.updateHitbox();
		add(ruins);

		if(!ClientPrefs.data.lowQuality)
		{
			var smokeLeft:BGSprite = new BGSprite('stages/tank/smokeLeft', -200, -100, 0.4, 0.4, ['SmokeBlurLeft'], true);
			add(smokeLeft);
			var smokeRight:BGSprite = new BGSprite('stages/tank/smokeRight', 1100, -100, 0.4, 0.4, ['SmokeRight'], true);
			add(smokeRight);

			tankWatchtower = new BGSprite('stages/tank/tankWatchtower', 100, 50, 0.5, 0.5, ['watchtower gradient color']);
			add(tankWatchtower);
		}

		tankGround = new BackgroundTank();
		add(tankGround);

		tankmanRun = new FlxTypedGroup<TankmenBG>();
		add(tankmanRun);

		var ground:BGSprite = new BGSprite('stages/tank/tankGround', -420, -150);
		ground.setGraphicSize(Std.int(1.15 * ground.width));
		ground.updateHitbox();
		add(ground);

		foregroundSprites = new FlxTypedGroup<BGSprite>();
		foregroundSprites.add(new BGSprite('stages/tank/tank0', -500, 650, 1.7, 1.5, ['fg']));
		if(!ClientPrefs.data.lowQuality) foregroundSprites.add(new BGSprite('stages/tank/tank1', -300, 750, 2, 0.2, ['fg']));
		foregroundSprites.add(new BGSprite('stages/tank/tank2', 450, 940, 1.5, 1.5, ['foreground']));
		if(!ClientPrefs.data.lowQuality) foregroundSprites.add(new BGSprite('stages/tank/tank4', 1300, 900, 1.5, 1.5, ['fg']));
		foregroundSprites.add(new BGSprite('stages/tank/tank5', 1620, 700, 1.5, 1.5, ['fg']));
		if(!ClientPrefs.data.lowQuality) foregroundSprites.add(new BGSprite('stages/tank/tank3', 1300, 1200, 3.5, 2.5, ['fg']));

		// Default GFs
		if(songName == 'stress') setDefaultGF('pico-speaker');
		else setDefaultGF('gf-tankmen');
		
		if ((isStoryMode || freeplayCutscenes) && !seenCutscene)
		{
			switch (songName)
			{
				case 'guns':
					setStartCallback(presongDialogue);
					setEndCallback(postsongDialogue);
				case 'stress':
					setStartCallback(videoCutscene);
				default:
					setStartCallback(presongDialogue);
			}
		}

		tankascends = new VideoSprite();
		tankascends.playVideo(Paths.video('tankboi-ascends'), true);
		tankascends.bitmap.canSkip = false;
		tankascends.scrollFactor.set();
		tankascends.setGraphicSize(Std.int(tankascends.width / defaultCamZoom));
		tankascends.updateHitbox();
		tankascends.antialiasing = ClientPrefs.data.antialiasing;
		tankascends.cameras = [camHUD];
		tankascends.alpha = 0;
		add(tankascends);
	}
	override function createPost()
	{
		add(foregroundSprites);

		if(!ClientPrefs.data.lowQuality)
		{
			for (daGf in gfGroup)
			{
				var gf:Character = cast daGf;
				if(gf.curCharacter == 'pico-speaker')
				{
					var firstTank:TankmenBG = new TankmenBG(20, 500, true);
					firstTank.resetJunk(20, 600, true);
					firstTank.strumTime = 10;
					firstTank.visible = false;
					tankmanRun.add(firstTank);

					for (i in 0...TankmenBG.animationNotes.length)
					{
						if(FlxG.random.bool(16)) {
							var tankBih = tankmanRun.recycle(TankmenBG);
							tankBih.strumTime = TankmenBG.animationNotes[i][0];
							tankBih.resetJunk(500, 200 + FlxG.random.int(50, 100), TankmenBG.animationNotes[i][1] < 2);
							tankmanRun.add(tankBih);
						}
					}
					break;
				}
			}
		}
	}

	override function countdownTick(count:Countdown, num:Int) if(num % 2 == 0) everyoneDance();
	override function beatHit() 
	{
		everyoneDance();
	}
	function everyoneDance()
	{
		if(!ClientPrefs.data.lowQuality) tankWatchtower.dance();
		foregroundSprites.forEach(function(spr:BGSprite)
		{
			spr.dance();
		});
	}

	override function stepHit()
	{
		if (songName == 'guns') {
			switch (curStep)
			{
				case 895:
					tankascends.bitmap.time = 0;
				case 896:
					tankascends.alpha = 1;
				case 1152:
					FlxG.camera.flash(FlxColor.WHITE, 0.55, null, true);
					tankascends.alpha = 0;
			}
		}
	}

	// Cutscenes
	public function presongDialogue()
	{
		FlxG.sound.playMusic(Paths.music('distorto'), 0);
		FlxG.sound.music.fadeIn(2, 0, 1);

		new FlxTimer().start(1, function(tmr:FlxTimer) {
			switch (curPlayer) {
				case 1:
					PlayState.instance.startDialogue(DialogueBoxPsych.parseDialogue(Paths.json(songName + '/dialogueBF')));
				case 2:
					PlayState.instance.startDialogue(DialogueBoxPsych.parseDialogue(Paths.json(songName + '/dialogueJR')));
				case 3:
					PlayState.instance.startDialogue(DialogueBoxPsych.parseDialogue(Paths.json(songName + '/dialogueMONI')));
			}
		});
	}
	function postsongDialogue()
	{
		new FlxTimer().start(0.1, function(tmr:FlxTimer) {
			switch (curPlayer) {
				case 1:
					PlayState.instance.startDialogue(DialogueBoxPsych.parseDialogue(Paths.json(songName + '/dialogueEndBF')));
				case 2:
					PlayState.instance.startDialogue(DialogueBoxPsych.parseDialogue(Paths.json(songName + '/dialogueEndJR')));
				case 3:
					PlayState.instance.startDialogue(DialogueBoxPsych.parseDialogue(Paths.json(songName + '/dialogueEndMONI')));
			}
		});
	}
	function videoCutscene()
	{
		switch (curPlayer)
		{
			case 1:
				PlayState.instance.startVideo('Stress-Cutscene-BF');
			case 2:
				PlayState.instance.startVideo('Stress-Cutscene-JR');
			case 3:
				PlayState.instance.startVideo('Stress-Cutscene-MONI');
		}
	}
}