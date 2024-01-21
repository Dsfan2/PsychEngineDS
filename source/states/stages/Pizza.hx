package states.stages;

import states.stages.objects.*;
import substates.GameOverSubstate;

class Pizza extends BaseStage
{
	var blackStart:FlxSprite;
	var blackStart2:FlxSprite;

	override function create()
	{
		var _song = PlayState.SONG;
		if(_song.gameOverSound == null || _song.gameOverSound.trim().length < 1) GameOverSubstate.deathSoundName = 'fnf_loss_sfx-pixel';
		if(_song.gameOverLoop == null || _song.gameOverLoop.trim().length < 1) GameOverSubstate.loopSoundName = 'gameOver-pixel';
		if(_song.gameOverEnd == null || _song.gameOverEnd.trim().length < 1) GameOverSubstate.endSoundName = 'gameOverEnd-pixel';
		if(_song.gameOverChar == null || _song.gameOverChar.trim().length < 1) GameOverSubstate.characterName = 'bf-pixel-dead';

		var bg:BGSprite = new BGSprite('stages/pizza/johngutterbg', -450, -100, 0.7, 0.7);
		bg.setGraphicSize(Std.int(bg.width * 2));
		bg.updateHitbox();
		bg.antialiasing = false;
		add(bg);
		
		var midg:BGSprite = new BGSprite('stages/pizza/johngutterback', -400, -40, 0.85, 0.85);
		midg.setGraphicSize(Std.int(midg.width * 2));
		midg.updateHitbox();
		midg.antialiasing = false;
		add(midg);

		var fg:BGSprite = new BGSprite('stages/pizza/johngutterfloor', -250, 30, 1, 1);
		fg.setGraphicSize(Std.int(fg.width * 2));
		fg.updateHitbox();
		fg.antialiasing = false;
		add(fg);

		setDefaultGF('gf-pixel');

		blackStart = new FlxSprite().makeGraphic(Std.int(FlxG.width * 2), Std.int(FlxG.height * 2), FlxColor.BLACK);
		blackStart.scrollFactor.set(0, 0);
		if (songName == 'pizza-time')
			add(blackStart);
	}
	
	override function createPost()
	{
		blackStart2 = new FlxSprite().makeGraphic(Std.int(FlxG.width), Std.int(FlxG.height), FlxColor.BLACK);
		blackStart2.cameras = [camDialogue];
		if (songName == 'pizza-time')
			add(blackStart2);
		dad.alpha = 0;
		FlxTween.tween(blackStart2, {alpha: 0}, 15.5);
		if (dsFilterOn) FlxTween.tween(FlxG.camera, {zoom: game.defaultCamZoom - 0.55 - 0.42}, 15.5);
		else FlxTween.tween(FlxG.camera, {zoom: game.defaultCamZoom - 0.55}, 15.5);
	}

	override function beatHit()
	{
		if (curBeat >= 24) {
			blackStart.visible = false;
		}
		if (curBeat >= 656) {
			blackStart2.alpha = 1;
		}
	}
}