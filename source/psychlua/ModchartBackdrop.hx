package psychlua;

import flixel.graphics.FlxGraphic;
import flixel.system.FlxAssets;

class ModchartBackdrop extends FlxBackdrop
{
	public var animOffsets:Map<String, Array<Float>> = new Map<String, Array<Float>>();
	public function new(graphic:FlxGraphicAsset)
	{
		super(graphic);
		antialiasing = ClientPrefs.data.antialiasing;
	}
}
