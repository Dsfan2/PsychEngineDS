package states.stages;

import states.stages.objects.*;

class DimensionalBorder extends BaseStage
{
	var warningTxt:FlxSprite;

	override function create()
	{
		var bg:BGSprite = new BGSprite('stages/secret/secretBG1', -600, -200, 0.7, 0.7);
		add(bg);
		
		var energyThingy:BGSprite = new BGSprite('stages/secret/secretBG3', -360, 200, 0.8, 0.8);
		energyThingy.setGraphicSize(Std.int(energyThingy.width * 0.8));
		energyThingy.updateHitbox();
		add(energyThingy);

		var fg:BGSprite = new BGSprite('stages/secret/secretBG2', -500, 600, 1, 1);
		fg.setGraphicSize(Std.int(fg.width * 1.1));
		fg.updateHitbox();
		add(fg);
	}
	
	override function createPost()
	{
		warningTxt = new FlxSprite(-69, 100).loadGraphic(Paths.image('stages/secret/Warning'));
		warningTxt.scrollFactor.set();
		warningTxt.setGraphicSize(Std.int(warningTxt.width * 0.9));
		add(warningTxt);
		warningTxt.cameras = [camDialogue];
		if (songName != 'konga-conga-kappa')
			warningTxt.visible = false;
	}

	override function beatHit()
	{
		if (curBeat >= 8)
			warningTxt.visible = false;
	}
}