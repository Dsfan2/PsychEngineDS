package objects;

// Yeah... this is just an edited version of the one from Doki Doki Takeover Plus. Cry about it. XP
class CoolSongBlurb extends FlxSpriteGroup
{
    var dataName:FlxText;
    var dataComp:FlxText;
    public function new(songName:String = '', songComp:String = '')
    {
        super();

        // Set up song name
        dataName = new FlxText(0, 720, FlxG.width, "", 36);
		dataName.setFormat(Paths.font('vcr.ttf'), 36, FlxColor.WHITE, LEFT);
		dataName.setBorderStyle(OUTLINE, FlxColor.BLACK, 3);
        dataName.text = "Now Playing: " + songName + " (" + Difficulty.getString().toUpperCase() + ")";
        dataName.updateHitbox();
        dataName.scrollFactor.set();
        dataName.alpha = 0;
        dataName.antialiasing = ClientPrefs.data.antialiasing;
        dataName.y = FlxG.height - (dataName.height - 20);

        // Set up artist(s)
        dataComp = new FlxText(0, 720, FlxG.width, "", 20);
        dataComp.setFormat(Paths.font('vcr.ttf'), 20, FlxColor.WHITE, LEFT);
		dataComp.setBorderStyle(OUTLINE, FlxColor.BLACK, 1.4);
        dataComp.text = songComp;
        dataComp.updateHitbox();
        dataComp.scrollFactor.set();
        dataComp.alpha = 0;
        dataComp.antialiasing = ClientPrefs.data.antialiasing;
        dataComp.y = FlxG.height - (dataComp.height - 20);
        
        // Finally, add them into this sprite group
        add(dataName);
        add(dataComp);
    }

    public function tweenIn()
    {
        // Move them into the display
		FlxTween.tween(dataName, {alpha: 1, y: 640}, 0.4, {ease: FlxEase.quartInOut, startDelay: 0.3});
		FlxTween.tween(dataComp, {alpha: 1, y: 690}, 0.4, {ease: FlxEase.quartInOut, startDelay: 0.4});
    }

    public function tweenOut()
    {
        // Move them out from display
		FlxTween.tween(dataName, {alpha: 0, y: FlxG.height - (dataName.height - 20)}, 0.4, {ease: FlxEase.quartInOut, startDelay: 0.3});
		FlxTween.tween(dataComp, {alpha: 0, y: FlxG.height - (dataComp.height - 20)}, 0.4, {ease: FlxEase.quartInOut, startDelay: 0.3});
    }
}