package psychlua;

import hxcodec.VideoHandler as NetStreamHandler;
import hxcodec.VideoSprite;

class ModchartVideo extends VideoSprite
{
	public var animOffsets:Map<String, Array<Float>> = new Map<String, Array<Float>>();
	public function new(videoFile:String, ?startOnLoad:Bool = false)
	{
		super();
		antialiasing = ClientPrefs.data.antialiasing;
		if (startOnLoad)
			videoSpriteStart(Paths.video(videoFile), true);
		bitmap.canSkip = false;
		scrollFactor.set();
	}

	public function videoSpriteStart(filename:String, ?loop:Bool = true)
	{
		playVideo(Paths.video(filename), loop);
		setTime(0);
	}

	public function setTime(time:Int)
	{
		bitmap.time = time;
	}
}
