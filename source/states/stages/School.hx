package states.stages;

import states.stages.objects.*;
import substates.GameOverSubstate;
import cutscenes.DialogueBoxDS;

import openfl.utils.Assets as OpenFlAssets;

class School extends BaseStage
{
	var bgGirls:BackgroundGirls;
	override function create()
	{
		var _song = PlayState.SONG;
		if(_song.gameOverSound == null || _song.gameOverSound.trim().length < 1) GameOverSubstate.deathSoundName = 'fnf_loss_sfx-pixel';
		if(_song.gameOverLoop == null || _song.gameOverLoop.trim().length < 1) GameOverSubstate.loopSoundName = 'gameOver-pixel';
		if(_song.gameOverEnd == null || _song.gameOverEnd.trim().length < 1) GameOverSubstate.endSoundName = 'gameOverEnd-pixel';
		if(_song.gameOverChar == null || _song.gameOverChar.trim().length < 1) GameOverSubstate.characterName = 'bf-pixel-dead';

		var bgSky:BGSprite = new BGSprite('stages/weeb/weebSky', 0, 0, 0.1, 0.1);
		add(bgSky);
		bgSky.antialiasing = false;

		var repositionCrud = -200;

		var bgSchool:BGSprite = new BGSprite('stages/weeb/weebSchool', repositionCrud, 0, 0.6, 0.90);
		add(bgSchool);
		bgSchool.antialiasing = false;

		var bgStreet:BGSprite = new BGSprite('stages/weeb/weebStreet', repositionCrud, 0, 0.95, 0.95);
		add(bgStreet);
		bgStreet.antialiasing = false;

		var widJunk = Std.int(bgSky.width * PlayState.daPixelZoom);
		if(!ClientPrefs.data.lowQuality) {
			var fgTrees:BGSprite = new BGSprite('stages/weeb/weebTreesBack', repositionCrud + 170, 130, 0.9, 0.9);
			fgTrees.setGraphicSize(Std.int(widJunk * 0.8));
			fgTrees.updateHitbox();
			add(fgTrees);
			fgTrees.antialiasing = false;
		}

		var bgTrees:FlxSprite = new FlxSprite(repositionCrud - 380, -800);
		bgTrees.frames = Paths.getPackerAtlas('stages/weeb/weebTrees');
		bgTrees.animation.add('treeLoop', [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18], 12);
		bgTrees.animation.play('treeLoop');
		bgTrees.scrollFactor.set(0.85, 0.85);
		add(bgTrees);
		bgTrees.antialiasing = false;

		if(!ClientPrefs.data.lowQuality) {
			var treeLeaves:BGSprite = new BGSprite('stages/weeb/petals', repositionCrud, -40, 0.85, 0.85, ['PETALS ALL'], true);
			treeLeaves.setGraphicSize(widJunk);
			treeLeaves.updateHitbox();
			add(treeLeaves);
			treeLeaves.antialiasing = false;
		}

		bgSky.setGraphicSize(widJunk);
		bgSchool.setGraphicSize(widJunk);
		bgStreet.setGraphicSize(widJunk);
		bgTrees.setGraphicSize(Std.int(widJunk * 1.4));

		bgSky.updateHitbox();
		bgSchool.updateHitbox();
		bgStreet.updateHitbox();
		bgTrees.updateHitbox();

		if(!ClientPrefs.data.lowQuality) {
			bgGirls = new BackgroundGirls(-100, 190);
			bgGirls.scrollFactor.set(0.9, 0.9);
			add(bgGirls);
		}
		setDefaultGF('gf-pixel');

		if((isStoryMode || freeplayCutscenes) && !seenCutscene)
		{
			setStartCallback(schoolIntro);
		}
	}

	override function beatHit()
	{
		if(bgGirls != null) bgGirls.dance();
	}

	// For events
	override function eventCalled(eventName:String, value1:String, value2:String, flValue1:Null<Float>, flValue2:Null<Float>, strumTime:Float)
	{
		switch(eventName)
		{
			case "BG Freaks Expression":
				if(bgGirls != null) bgGirls.swapDanceType();
		}
	}
	
	function schoolIntro():Void
	{
		inCutscene = true;
		if (songName == 'senpai')
		{
			FlxG.sound.playMusic(Paths.music('Lunchbox'), 0);
			FlxG.sound.music.fadeIn(1, 0, 0.8);

			var black:FlxSprite = new FlxSprite(0, 0).makeGraphic(FlxG.width * 2, FlxG.height * 2, FlxColor.BLACK);
			black.scrollFactor.set();
			add(black);

			new FlxTimer().start(0.3, function(tmr:FlxTimer)
			{
				black.alpha -= 0.15;

				if (black.alpha > 0)
				{
					tmr.reset(0.3);
				}
				else
				{
					remove(black);
					switch (curPlayer)
					{
						case 1:
							PlayState.instance.startDSDialogue(DialogueBoxDS.parseDialogue(Paths.json('senpai/dialogueBF')));
						case 2:
							PlayState.instance.startDSDialogue(DialogueBoxDS.parseDialogue(Paths.json('senpai/dialogueJR')));
						case 3:
							PlayState.instance.startDSDialogue(DialogueBoxDS.parseDialogue(Paths.json('senpai/dialogueMONI')));
					}
				}
			});
		}
		if (songName == 'roses')
		{
			FlxG.sound.play(Paths.sound('ANGRY_TEXT_BOX'));
			new FlxTimer().start(2.1, function(tmr:FlxTimer)
			{
				FlxG.sound.play(Paths.sound('ANGRY'));
				switch (curPlayer)
				{
					case 1:
						if (FlxG.random.bool(20))
							PlayState.instance.startDSDialogue(DialogueBoxDS.parseDialogue(Paths.json('roses/roSUS')));
						else
							PlayState.instance.startDSDialogue(DialogueBoxDS.parseDialogue(Paths.json('roses/dialogueBF')));
					case 2:
						if (FlxG.random.bool(20))
							PlayState.instance.startDSDialogue(DialogueBoxDS.parseDialogue(Paths.json('roses/iAmTheSenate')));
						else
							PlayState.instance.startDSDialogue(DialogueBoxDS.parseDialogue(Paths.json('roses/dialogueJR')));
					case 3:
						if (FlxG.random.bool(20))
							PlayState.instance.startDSDialogue(DialogueBoxDS.parseDialogue(Paths.json('roses/buddyChumPal')));
						else
							PlayState.instance.startDSDialogue(DialogueBoxDS.parseDialogue(Paths.json('roses/dialogueMONI')));
				}
			});
		}
	}
}