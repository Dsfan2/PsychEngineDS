package objects;

class CoolScrollText extends FlxText
{
	public var targetY:Float = 0;
	public var yMult:Float = 60;
	public var yAdd:Float = 0;
	public var isSelected:Bool = false;
	var boldText:Bool = true;

	public function new(xValue:Float, yValue:Float, widthValue:Int = 0, textValue:String = '', ?isBold:Bool = true, ?txtSize:Int = 40)
	{
		super();
		x = xValue;
		y = yValue;
		fieldWidth = widthValue;
		text = textValue;
		if (isBold)
		{
			setFormat(Paths.font("freeplay.ttf"), txtSize, FlxColor.WHITE, FlxTextAlign.CENTER);
			setBorderStyle(OUTLINE, 0xFF262626, 3.5);
			boldText = true;
		}
		else
		{
			setFormat(Paths.font("vcr.ttf"), txtSize - 2, FlxColor.WHITE, FlxTextAlign.CENTER);
			setBorderStyle(OUTLINE, FlxColor.BLACK, 1.5);
			boldText = false;
		}
	}

	override function update(elapsed:Float) 
	{
		var scaledY = FlxMath.remapToRange(targetY, 0, 1, 0, 1.3);

		if (boldText)
		{
			if (isSelected)
				setBorderStyle(OUTLINE, FlxColor.BLACK, 3.5);
			else
				setBorderStyle(OUTLINE, 0xFF262626, 3.5);
		}

		var lerpVal:Float = FlxMath.bound(elapsed * 9.6, 0, 1);
		y = FlxMath.lerp(y, (scaledY * yMult) + (FlxG.height * 0.48) + yAdd, lerpVal);

		super.update(elapsed);
	}
}