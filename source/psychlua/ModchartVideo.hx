package psychlua;

#if VIDEOS_ALLOWED
import hxcodec.VideoSprite as VideoSprite;
#end

class ModchartVideo extends VideoSprite
{
	public var animOffsets:Map<String, Array<Float>> = new Map<String, Array<Float>>();
	public var videoStr:String = '';
	public function new(videoFile:String)
	{
		super();
		antialiasing = ClientPrefs.data.antialiasing;
		videoStr = videoFile;
		videoSpriteStart(videoFile, true);
		bitmap.canSkip = false;
		scrollFactor.set();
		setGraphicSize(Std.int(width / PlayState.instance.defaultCamZoom));
		updateHitbox();
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
