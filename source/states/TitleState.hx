package states;

import backend.WeekData;
import backend.Highscore;
import backend.Achievements;

import flixel.input.keyboard.FlxKey;
import flixel.addons.transition.FlxTransitionableState;
import flixel.graphics.frames.FlxAtlasFrames;
import flixel.graphics.frames.FlxFrame;
import flixel.group.FlxGroup;
import flixel.input.gamepad.FlxGamepad;
import tjson.TJSON as Json;

import openfl.Assets;
import openfl.display.Bitmap;
import openfl.display.BitmapData;

import shaders.ColorSwap;

import states.StoryMenuState;
import states.OutdatedState;
import states.MainMenuState;

#if MODS_ALLOWED
import sys.FileSystem;
import sys.io.File;
#end

import TeamDSIntro;

typedef TitleData =
{
	alphabetScale:Float,
	titlex:Float,
	titley:Float,
	startx:Float,
	starty:Float,
	gfx:Float,
	gfy:Float,
	backgroundSprite:String,
	scrollingBG:String,
	bgScrollX:Int,
	bgScrollY:Int,
	bpm:Int,
	midLine1:String,
	midLine2:String,
	midLine3:String,
	endLine1:String,
	endLine2:String,
	endLine3:String
}

class TitleState extends MusicBeatState
{
	public static var muteKeys:Array<FlxKey> = [FlxKey.ZERO];
	public static var volumeDownKeys:Array<FlxKey> = [FlxKey.NUMPADMINUS, FlxKey.MINUS];
	public static var volumeUpKeys:Array<FlxKey> = [FlxKey.NUMPADPLUS, FlxKey.PLUS];

	public static var initialized:Bool = false;

	var blackScreen:FlxSprite;
	var credGroup:FlxGroup;
	var credTextTrash:Alphabet;
	var textGroup:FlxGroup;
	var dsSpr:FlxSprite;
	
	var titleTextColors:Array<FlxColor> = [0xFF33FFFF, 0xFF3333CC];
	var titleTextAlphas:Array<Float> = [1, .64];

	var curWacky:Array<String> = [];

	var wackyImage:FlxSprite;

	#if TITLE_SCREEN_EASTER_EGG
	var easterEggKeys:Array<String> = [
		'DSFAN', 'SHARK', 'CHEEZE', 'SOUR', 'MONIKA'
	];
	var allowedKeys:String = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ';
	var easterEggKeysBuffer:String = '';
	#end

	var mustUpdate:Bool = false;
	public static var alphabetScale:Float = 1.0;

	var titleJSON:TitleData;

	public static var updateVersion:String = '';

	override public function create():Void
	{
		FlxG.fixedTimestep = false;
		FlxG.game.focusLostFramerate = 120;
		FlxG.keys.preventDefaultKeys = [TAB];

		curWacky = FlxG.random.getObject(getIntroTextTrash());

		super.create();

		if (!TeamDSIntro.leftState) {
			FlxG.save.bind('funkin', CoolUtil.getSavePath());
			ClientPrefs.loadPrefs();
		}

		// gonna remove this because I could never get this to work for whatever reason...
		#if CHECK_FOR_UPDATES
		if(ClientPrefs.data.checkForUpdates && !closedState) {
			trace('checking for update');
			var http = new haxe.Http("https://raw.githubusercontent.com/Dsfan2/PsychEngineDS/main/gitVersion.txt");

			http.onData = function (data:String)
			{
				updateVersion = data.split('\n')[0].trim();
				var curVersion:String = MainMenuState.psychEngineVersion.trim();
				trace('version online: ' + updateVersion + ', your version: ' + curVersion);
				if(updateVersion != curVersion) {
					trace('versions arent matching!');
					mustUpdate = true;
				}
			}

			http.onError = function (error) {
				trace('error: $error');
			}

			http.request();
		}
		#end

		Highscore.load();

		// IGNORE THIS!!!
		titleJSON = Json.parse(Paths.getTextFromFile('images/title.json'));
		if (titleJSON.alphabetScale > 0)
			alphabetScale = titleJSON.alphabetScale;

		#if TITLE_SCREEN_EASTER_EGG
		if (FlxG.save.data.psychDevsEasterEgg == null) FlxG.save.data.psychDevsEasterEgg = ''; //Crash prevention
		switch(FlxG.save.data.psychDevsEasterEgg.toUpperCase())
		{
			case 'DSFAN':
				titleJSON.gfx = 712;
				titleJSON.gfy = 40;
			case 'SHARK':
				titleJSON.gfx = 642;
				titleJSON.gfy = 40;
			case 'CHEEZE':
				titleJSON.gfx = 618;
				titleJSON.gfy = 55;
			case 'SOUR':
				titleJSON.gfx = 712;
				titleJSON.gfy = 150;
			case 'MONIKA':
				titleJSON.gfx = 679;
				titleJSON.gfy = 40;
		}
		#end

		if(!initialized)
		{
			if(FlxG.save.data != null && FlxG.save.data.fullscreen)
			{
				FlxG.fullscreen = FlxG.save.data.fullscreen;
			}
			persistentUpdate = true;
			persistentDraw = true;
		}

		if (FlxG.save.data.weekCompleted != null) {
			StoryMenuState.weekCompleted = FlxG.save.data.weekCompleted;
		}
		if (FlxG.save.data.jrWeeksCleared != null) {
			PlayState.jrWeeksCleared = FlxG.save.data.jrWeeksCleared;
		}
		if (FlxG.save.data.moniWeeksCleared != null) {
			PlayState.moniWeeksCleared = FlxG.save.data.moniWeeksCleared;
		}

		FlxG.mouse.visible = false;
		#if FREEPLAY
		MusicBeatState.switchState(new FreeplayState());
		#elseif CHARTING
		MusicBeatState.switchState(new ChartingState());
		#else
		if (initialized)
			startIntro();
		else
		{
			new FlxTimer().start(1, function(tmr:FlxTimer)
			{
				startIntro();
			});
		}
		#end
	}

	var logoBl:FlxSprite;
	var gfDance:FlxSprite;
	var danceLeft:Bool = false;
	var titleText:FlxSprite;
	var swagShader:ColorSwap = null;

	function startIntro()
	{
		if (!initialized)
		{
			if(FlxG.sound.music == null) {
				FlxG.sound.playMusic(Paths.music('freakyMenu'), 0);
			}
		}

		Conductor.bpm = titleJSON.bpm;
		persistentUpdate = true;

		var bg:FlxSprite = new FlxSprite();
		var scrollBG:FlxBackdrop;
		if (titleJSON.scrollingBG == 'true'){
			if (titleJSON.backgroundSprite != null && titleJSON.backgroundSprite.length > 0 && titleJSON.backgroundSprite != "none"){
				scrollBG = new FlxBackdrop(Paths.image(titleJSON.backgroundSprite));
				scrollBG.velocity.set(titleJSON.bgScrollX, titleJSON.bgScrollY);
				add(scrollBG);
			}else{
				bg.makeGraphic(FlxG.width, FlxG.height, FlxColor.BLACK);
				add(bg);
			}
		}else{
			if (titleJSON.backgroundSprite != null && titleJSON.backgroundSprite.length > 0 && titleJSON.backgroundSprite != "none"){
				bg.loadGraphic(Paths.image(titleJSON.backgroundSprite));
				add(bg);
			}else{
				bg.makeGraphic(FlxG.width, FlxG.height, FlxColor.BLACK);
				add(bg);
			}
		}

		logoBl = new FlxSprite(titleJSON.titlex, titleJSON.titley);
		logoBl.frames = Paths.getSparrowAtlas('logoBumpin');
		logoBl.antialiasing = ClientPrefs.data.antialiasing;

		logoBl.animation.addByPrefix('bump', 'logo bumpin', 24, false);
		logoBl.animation.play('bump');
		logoBl.updateHitbox();

		if(ClientPrefs.data.shaders) swagShader = new ColorSwap();
		gfDance = new FlxSprite(titleJSON.gfx, titleJSON.gfy);
		gfDance.antialiasing = ClientPrefs.data.antialiasing;

		var easterEgg:String = FlxG.save.data.psychDevsEasterEgg;
		if(easterEgg == null) easterEgg = ''; //html5 fix

		switch(easterEgg.toUpperCase())
		{
			// IGNORE THESE, GO DOWN A BIT
			#if TITLE_SCREEN_EASTER_EGG
			case 'DSFAN':
				gfDance.frames = Paths.getSparrowAtlas('DSBump');
				gfDance.animation.addByPrefix('danceLeft', 'DS Title Bump', 24, false);
				gfDance.animation.addByPrefix('danceRight', 'DS Title Bump', 24, false);
			case 'SHARK':
				gfDance.frames = Paths.getSparrowAtlas('SharkBump');
				gfDance.animation.addByPrefix('danceLeft', 'Shark Title Bump', 24, false);
				gfDance.animation.addByPrefix('danceRight', 'Shark Title Bump', 24, false);
			case 'CHEEZE':
				gfDance.frames = Paths.getSparrowAtlas('CheezeBump');
				gfDance.animation.addByPrefix('danceLeft', 'Cheeze Title Bump', 24, false);
				gfDance.animation.addByPrefix('danceRight', 'Cheeze Title Bump', 24, false);
			case 'SOUR':
				gfDance.frames = Paths.getSparrowAtlas('SourBump');
				gfDance.animation.addByPrefix('danceLeft', 'Sour Title Bump', 24, false);
				gfDance.animation.addByPrefix('danceRight', 'Sour Title Bump', 24, false);
			case 'MONIKA':
				gfDance.frames = Paths.getSparrowAtlas('MFanBump');
				gfDance.animation.addByPrefix('danceLeft', 'MFan Title Bump', 24, false);
				gfDance.animation.addByPrefix('danceRight', 'MFan Title Bump', 24, false);
			#end

			default:
			//EDIT THIS ONE IF YOU'RE MAKING A SOURCE CODE MOD!!!!
			//EDIT THIS ONE IF YOU'RE MAKING A SOURCE CODE MOD!!!!
			//EDIT THIS ONE IF YOU'RE MAKING A SOURCE CODE MOD!!!!
				gfDance.frames = Paths.getSparrowAtlas('gfDanceTitle');
				gfDance.animation.addByIndices('danceLeft', 'gfDance', [30, 0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14], "", 24, false);
				gfDance.animation.addByIndices('danceRight', 'gfDance', [15, 16, 17, 18, 19, 20, 21, 22, 23, 24, 25, 26, 27, 28, 29], "", 24, false);
		}

		add(gfDance);
		add(logoBl);
		if(swagShader != null)
		{
			gfDance.shader = swagShader.shader;
			logoBl.shader = swagShader.shader;
		}

		titleText = new FlxSprite(titleJSON.startx, titleJSON.starty);
		titleText.frames = Paths.getSparrowAtlas('titleEnter');
		var animFrames:Array<FlxFrame> = [];
		@:privateAccess {
			titleText.animation.findByPrefix(animFrames, "ENTER IDLE");
			titleText.animation.findByPrefix(animFrames, "ENTER FREEZE");
		}
		
		if (animFrames.length > 0) {
			newTitle = true;
			
			titleText.animation.addByPrefix('idle', "ENTER IDLE", 24);
			titleText.animation.addByPrefix('press', ClientPrefs.data.flashing ? "ENTER PRESSED" : "ENTER FREEZE", 24);
		}
		else {
			newTitle = false;
			
			titleText.animation.addByPrefix('idle', "Press Enter to Begin", 24);
			titleText.animation.addByPrefix('press', "ENTER PRESSED", 24);
		}
		
		titleText.animation.play('idle');
		titleText.updateHitbox();
		add(titleText);

		var logo:FlxSprite = new FlxSprite().loadGraphic(Paths.image('logo'));
		logo.antialiasing = ClientPrefs.data.antialiasing;
		logo.screenCenter();

		credGroup = new FlxGroup();
		add(credGroup);
		textGroup = new FlxGroup();

		blackScreen = new FlxSprite().makeGraphic(FlxG.width, FlxG.height, FlxColor.BLACK);
		credGroup.add(blackScreen);

		credTextTrash = new Alphabet(0, 0, "", true);
		credTextTrash.screenCenter();

		credTextTrash.visible = false;

		dsSpr = new FlxSprite(0, FlxG.height * 0.52).loadGraphic(Paths.image('team_ds_logo-new'));
		add(dsSpr);
		dsSpr.visible = false;
		dsSpr.setGraphicSize(Std.int(dsSpr.width * 0.8));
		dsSpr.updateHitbox();
		dsSpr.screenCenter();
		dsSpr.antialiasing = ClientPrefs.data.antialiasing;

		FlxTween.tween(credTextTrash, {y: credTextTrash.y + 20}, 2.9, {ease: FlxEase.quadInOut, type: PINGPONG});

		if (initialized)
			skipIntro();
		else
			initialized = true;
	}

	function getIntroTextTrash():Array<Array<String>>
	{
		var fullText:String;
		#if MODS_ALLOWED
		if (FileSystem.exists(Paths.modFolders('data/introText.txt'))){
			fullText = File.getContent(Paths.modFolders('data/introText.txt'));
		}
		else {
			fullText = Assets.getText(Paths.txt('introText'));
		}
		#else	
		fullText = Assets.getText(Paths.txt('introText'));
		#end
		var firstArray:Array<String> = fullText.split('\n');
		var swagGoodArray:Array<Array<String>> = [];

		for (i in firstArray)
		{
			swagGoodArray.push(i.split('--'));
		}

		return swagGoodArray;
	}

	var transitioning:Bool = false;
	private static var playJingle:Bool = false;
	
	var newTitle:Bool = false;
	var titleTimer:Float = 0;

	override function update(elapsed:Float)
	{
		if (FlxG.sound.music != null)
			Conductor.songPosition = FlxG.sound.music.time;

		var pressedEnter:Bool = FlxG.keys.justPressed.ENTER || controls.ACCEPT;

		#if mobile
		for (touch in FlxG.touches.list)
		{
			if (touch.justPressed)
			{
				pressedEnter = true;
			}
		}
		#end

		var gamepad:FlxGamepad = FlxG.gamepads.lastActive;

		if (gamepad != null)
		{
			if (gamepad.justPressed.START)
				pressedEnter = true;

			#if switch
			if (gamepad.justPressed.B)
				pressedEnter = true;
			#end
		}
		
		if (newTitle) {
			titleTimer += FlxMath.bound(elapsed, 0, 1);
			if (titleTimer > 2) titleTimer -= 2;
		}

		// EASTER EGG

		if (initialized && !transitioning && skippedIntro)
		{
			if (newTitle && !pressedEnter)
			{
				var timer:Float = titleTimer;
				if (timer >= 1)
					timer = (-timer) + 2;
				
				timer = FlxEase.quadInOut(timer);
				
				titleText.color = FlxColor.interpolate(titleTextColors[0], titleTextColors[1], timer);
				titleText.alpha = FlxMath.lerp(titleTextAlphas[0], titleTextAlphas[1], timer);
			}
			
			if(pressedEnter)
			{
				titleText.color = FlxColor.WHITE;
				titleText.alpha = 1;
				
				if(titleText != null) titleText.animation.play('press');

				FlxG.camera.flash(ClientPrefs.data.flashing ? FlxColor.WHITE : 0x4CFFFFFF, 1);
				FlxG.sound.play(Paths.sound('confirmMenu'), 0.7);

				transitioning = true;

				new FlxTimer().start(1, function(tmr:FlxTimer)
				{
					if (mustUpdate) {
						MusicBeatState.switchState(new OutdatedState());
					} else {
						MusicBeatState.switchState(new MainMenuState());
					}
					closedState = true;
				});
			}
			#if TITLE_SCREEN_EASTER_EGG
			else if (FlxG.keys.firstJustPressed() != FlxKey.NONE)
			{
				var keyPressed:FlxKey = FlxG.keys.firstJustPressed();
				var keyName:String = Std.string(keyPressed);
				if(allowedKeys.contains(keyName)) {
					easterEggKeysBuffer += keyName;
					if(easterEggKeysBuffer.length >= 32) easterEggKeysBuffer = easterEggKeysBuffer.substring(1);

					for (wordRaw in easterEggKeys)
					{
						var word:String = wordRaw.toUpperCase(); //just for being sure you're doing it right
						if (easterEggKeysBuffer.contains(word))
						{
							if (FlxG.save.data.psychDevsEasterEgg == word)
								FlxG.save.data.psychDevsEasterEgg = '';
							else
								FlxG.save.data.psychDevsEasterEgg = word;
							FlxG.save.flush();

							FlxG.sound.play(Paths.sound('ToggleJingle'));

							var black:FlxSprite = new FlxSprite(0, 0).makeGraphic(FlxG.width, FlxG.height, FlxColor.BLACK);
							black.alpha = 0;
							add(black);

							FlxTween.tween(black, {alpha: 1}, 1, {onComplete:
								function(twn:FlxTween) {
									FlxTransitionableState.skipNextTransIn = true;
									FlxTransitionableState.skipNextTransOut = true;
									MusicBeatState.switchState(new TitleState());
								}
							});
							FlxG.sound.music.fadeOut();
							if(FreeplayState.vocals != null)
							{
								FreeplayState.vocals.fadeOut();
							}
							closedState = true;
							transitioning = true;
							playJingle = true;
							easterEggKeysBuffer = '';
							break;
						}
					}
				}
			}
			#end
		}

		if (initialized && pressedEnter && !skippedIntro)
		{
			skipIntro();
		}

		if(swagShader != null)
		{
			if(controls.UI_LEFT) swagShader.hue -= elapsed * 0.1;
			if(controls.UI_RIGHT) swagShader.hue += elapsed * 0.1;
		}

		super.update(elapsed);
	}

	function createCoolText(textArray:Array<String>, ?offset:Float = 0, ?fadeTime:Float = 0.001)
	{
		for (i in 0...textArray.length)
		{
			var money:Alphabet = new Alphabet(0, 0, textArray[i], true);
			money.setScale(1 * alphabetScale);
			money.screenCenter(X);
			money.y += (i * 60) + 200 + offset;
			money.alpha = 0;
			if(credGroup != null && textGroup != null) {
				credGroup.add(money);
				textGroup.add(money);
			}
			FlxTween.tween(money, {alpha: 1}, fadeTime, {ease: FlxEase.expoIn});
		}
	}

	function addMoreText(text:String, ?offset:Float = 0, ?fadeTime:Float = 0.001)
	{
		if(textGroup != null && credGroup != null) {
			var coolText:Alphabet = new Alphabet(0, 0, text, true);
			coolText.setScale(1 * alphabetScale);
			coolText.screenCenter(X);
			coolText.y += (textGroup.length * 60) + 200 + offset;
			coolText.alpha = 0;
			credGroup.add(coolText);
			textGroup.add(coolText);
			FlxTween.tween(coolText, {alpha: 1}, fadeTime, {ease: FlxEase.sineIn});
		}
	}

	function deleteCoolText()
	{
		while (textGroup.members.length > 0)
		{
			credGroup.remove(textGroup.members[0], true);
			textGroup.remove(textGroup.members[0], true);
		}
	}

	private var sickBeats:Int = 0; //Basically curBeat but won't be skipped if you hold the tab or resize the screen
	public static var closedState:Bool = false;
	override function beatHit()
	{
		super.beatHit();

		if(logoBl != null)
			logoBl.animation.play('bump', true);

		if(gfDance != null) {
			danceLeft = !danceLeft;
			if (danceLeft)
				gfDance.animation.play('danceRight');
			else
				gfDance.animation.play('danceLeft');
		}

		if(!closedState) {
			sickBeats++;
			switch (sickBeats)
			{
				case 1:
					FlxG.sound.playMusic(Paths.music('freakyMenu'), 0);
					FlxG.sound.music.fadeIn(4, 0, 0.7);
				case 2:
					createCoolText(['Original', 'Psych Engine by'], 40);
				case 4:
					addMoreText('Shadow Mario', 40);
					addMoreText('Riveren', 40);
				case 5:
					deleteCoolText();
				case 6:
					createCoolText([titleJSON.midLine1, titleJSON.midLine2], 30);
				case 8:
					deleteCoolText();
					createCoolText([titleJSON.midLine3], -80);
					dsSpr.visible = true;
				case 9:
					deleteCoolText();
					dsSpr.visible = false;
				case 10:
					createCoolText([curWacky[0]]);
				case 12:
					addMoreText(curWacky[1]);
				case 13:
					deleteCoolText();
				case 14:
					addMoreText(titleJSON.endLine1);
				case 15:
					addMoreText(titleJSON.endLine2);
				case 16:
					addMoreText(titleJSON.endLine3);
				case 17:
					skipIntro();
			}
		}
	}

	var skippedIntro:Bool = false;
	var increaseVolume:Bool = false;
	function skipIntro():Void
	{
		if (!skippedIntro)
		{
			if (playJingle) //Ignore deez
			{
				var easteregg:String = FlxG.save.data.psychDevsEasterEgg;
				if (easteregg == null) easteregg = '';
				easteregg = easteregg.toUpperCase();

				var sound:FlxSound = null;
				switch(easteregg)
				{
					case 'DSFAN':
						sound = FlxG.sound.play(Paths.sound('JingleDS'));
					case 'SHARK':
						sound = FlxG.sound.play(Paths.sound('JingleShark'));
					case 'CHEEZE':
						sound = FlxG.sound.play(Paths.sound('JingleCheeze'));
					case 'SOUR':
						sound = FlxG.sound.play(Paths.sound('JingleSour'));
					case 'MONIKA':
						sound = FlxG.sound.play(Paths.sound('JingleMFan'));

					default: //Go back to normal ugly boring GF
						remove(dsSpr);
						remove(credGroup);
						FlxG.camera.flash(FlxColor.WHITE, 2);
						skippedIntro = true;
						playJingle = false;

						FlxG.sound.playMusic(Paths.music('freakyMenu'), 0);
						FlxG.sound.music.fadeIn(4, 0, 0.7);
						return;
				}

				transitioning = true;
				if(easteregg == 'DSFAN')
				{
					new FlxTimer().start(2.09, function(tmr:FlxTimer)
					{
						remove(dsSpr);
						remove(credGroup);
						FlxG.camera.flash(FlxColor.WHITE, 0.6);
						transitioning = false;
						new FlxTimer().start(2.1, function(tmr:FlxTimer)
						{
							FlxG.sound.playMusic(Paths.music('freakyMenu'), 0);
							FlxG.sound.music.fadeIn(4, 0, 0.7);
						});
					});
				}
				else if(easteregg == 'SHARK')
				{
					new FlxTimer().start(4, function(tmr:FlxTimer)
					{
						remove(dsSpr);
						remove(credGroup);
						FlxG.camera.flash(FlxColor.WHITE, 0.6);
						transitioning = false;
						new FlxTimer().start(1, function(tmr:FlxTimer)
						{
							FlxG.sound.playMusic(Paths.music('freakyMenu'), 0);
							FlxG.sound.music.fadeIn(4, 0, 0.7);
						});
					});
				}
				else
				{
					remove(dsSpr);
					remove(credGroup);
					FlxG.camera.flash(FlxColor.WHITE, 3);
					sound.onComplete = function() {
						FlxG.sound.playMusic(Paths.music('freakyMenu'), 0);
						FlxG.sound.music.fadeIn(4, 0, 0.7);
						transitioning = false;
					};
				}
				playJingle = false;
			}
			else //Default! Edit this one!!
			{
				remove(dsSpr);
				remove(credGroup);
				FlxG.camera.flash(FlxColor.WHITE, 4);

				var easteregg:String = FlxG.save.data.psychDevsEasterEgg;
				if (easteregg == null) easteregg = '';
				easteregg = easteregg.toUpperCase();
				#if TITLE_SCREEN_EASTER_EGG
				if(easteregg == 'DSFAN')
				{
					FlxG.sound.music.fadeOut();
					if(FreeplayState.vocals != null)
					{
						FreeplayState.vocals.fadeOut();
					}
				}
				#end
			}
			skippedIntro = true;
		}
	}
}
