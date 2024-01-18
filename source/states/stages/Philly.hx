package states.stages;

import states.stages.objects.*;
import objects.Character;

class Philly extends BaseStage
{
	var phillyLightsColors:Array<FlxColor>;
	public static var phillyWindow:BGSprite;
	var phillyStreet:BGSprite;
	var phillyTrain:PhillyTrain;
	var curLight:Int = -1;

	override function create()
	{
		if(!ClientPrefs.data.lowQuality) {
			var bg:BGSprite = new BGSprite('stages/philly/sky', -100, 0, 0.1, 0.1);
			add(bg);
		}

		var city:BGSprite = new BGSprite('stages/philly/city', -10, 0, 0.3, 0.3);
		city.setGraphicSize(Std.int(city.width * 0.85));
		city.updateHitbox();
		add(city);

		phillyLightsColors = [0xFF31A2FD, 0xFF31FD8C, 0xFFFB33F5, 0xFFFD4531, 0xFFFBA633];
		phillyWindow = new BGSprite('stages/philly/window', city.x, city.y, 0.3, 0.3);
		phillyWindow.setGraphicSize(Std.int(phillyWindow.width * 0.85));
		phillyWindow.updateHitbox();
		add(phillyWindow);
		phillyWindow.alpha = 0;

		if(!ClientPrefs.data.lowQuality) {
			var streetBehind:BGSprite = new BGSprite('stages/philly/behindTrain', -40, 50);
			add(streetBehind);
		}

		phillyTrain = new PhillyTrain(2000, 360);
		add(phillyTrain);

		phillyStreet = new BGSprite('stages/philly/street', -40, 50);
		add(phillyStreet);
	}

	override function update(elapsed:Float)
	{
		phillyWindow.alpha -= (Conductor.crochet / 1000) * FlxG.elapsed * 1.5;
	}

	override function beatHit()
	{
		phillyTrain.beatHit(curBeat);
		if (curBeat % 4 == 0)
		{
			curLight = FlxG.random.int(0, phillyLightsColors.length - 1, [curLight]);
			phillyWindow.color = phillyLightsColors[curLight];
			phillyWindow.alpha = 1;
		}
	}
}