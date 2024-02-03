package states;

// If you want to add your stage to the game, copy states/stages/Template.hx,
// and put your stage code there, then, on PlayState, search for
// "switch (curStage)", and add your stage to that list.

// If you want to code Events, you can either code it on a Stage file or on PlayState, if you're doing the latter, search for:
// "function eventPushed" - Only called *one time* when the game loads, use it for precaching events that use the same assets, no matter the values
// "function eventPushedUnique" - Called one time per event, use it for precaching events that uses different assets based on its values
// "function eventEarlyTrigger" - Used for making your event start a few MILLISECONDS earlier
// "function triggerEvent" - Called when the song hits your event's timestamp, this is probably what you were looking for

import backend.Achievements;
import backend.Highscore;
import backend.StageData;
import backend.WeekData;
import backend.Song;
import backend.Section;
import backend.Rating;

import flixel.FlxBasic;
import flixel.FlxObject;
import flixel.FlxSubState;
import flixel.addons.transition.FlxTransitionableState;
import flixel.math.FlxPoint;
import flixel.util.FlxSort;
import flixel.util.FlxStringUtil;
import flixel.util.FlxSave;
import flixel.input.keyboard.FlxKey;
import flixel.animation.FlxAnimationController;
import lime.utils.Assets;
import openfl.utils.Assets as OpenFlAssets;
import openfl.events.KeyboardEvent;
import tjson.TJSON as Json;

import cutscenes.DialogueBoxPsych;
import cutscenes.DialogueBoxDS;

import states.StoryMenuState;
import states.FreeplayState;
import states.editors.ChartingState;
import states.editors.CharacterEditorState;

import substates.PauseSubState;
import substates.GameOverSubstate;
import substates.ResultsScreen;

#if !flash 
import flixel.addons.display.FlxRuntimeShader;
import openfl.filters.ShaderFilter;
#end

#if sys
import sys.FileSystem;
import sys.io.File;
#end

#if VIDEOS_ALLOWED
import hxcodec.VideoSprite;
#end

import objects.Note.EventNote;
import objects.*;
import states.stages.objects.*;

#if LUA_ALLOWED
import psychlua.*;
#else
import psychlua.FunkinLua;
import psychlua.LuaUtils;
import psychlua.HScript;
#end

#if (SScript >= "3.0.0" && HSCRIPT_ALLOWED)
import tea.SScript;
#end

class PlayState extends MusicBeatState
{
	public var isPlayState:Bool = false;

	public static var jrWeeksCleared:Map<String, Bool> = new Map<String, Bool>();
	public static var moniWeeksCleared:Map<String, Bool> = new Map<String, Bool>();

	public static var STRUM_X = 42;
	public static var STRUM_X_MIDDLESCROLL = -278;

	public static var ratingStuff:Array<Dynamic> = [
		['U SUK', 0.6], //From 0% to 59%
		['H', 0.65], //From 60% to 64%
		['G', 0.7], //From 65% to 69%
		['F', 0.75], //From 70% to 74%
		['E', 0.8], //From 75% to 79%
		['D', 0.83], //From 80% to 82%
		['C', 0.87], //From 84% to 86%
		['B', 0.9], //From 87% to 89%
		['A', 0.95], //From 90% to 94%
		['S', 0.98], //From 95% to 97%
		['S+', 1], //From 98% to 99%
		['S++', 1] //The value on this one isn't used actually, since Perfect is always "1"
	];

	//event variables
	private var isCameraOnForcedPos:Bool = false;

	public var boyfriendMap:Map<String, Character> = new Map<String, Character>();
	public var dadMap:Map<String, Character> = new Map<String, Character>();
	public var gfMap:Map<String, Character> = new Map<String, Character>();
	public var variables:Map<String, Dynamic> = new Map<String, Dynamic>();
	
	#if HSCRIPT_ALLOWED
	public var hscriptArray:Array<HScript> = [];
	#end

	#if LUA_ALLOWED
	public var modchartTweens:Map<String, FlxTween> = new Map<String, FlxTween>();
	public var modchartSprites:Map<String, ModchartSprite> = new Map<String, ModchartSprite>();
	#if VIDEOS_ALLOWED
	public var modchartVideos:Map<String, ModchartVideo> = new Map<String, ModchartVideo>();
	#end
	public var modchartBackdrops:Map<String, ModchartBackdrop> = new Map<String, ModchartBackdrop>();
	public var modchartTimers:Map<String, FlxTimer> = new Map<String, FlxTimer>();
	public var modchartSounds:Map<String, FlxSound> = new Map<String, FlxSound>();
	public var modchartTexts:Map<String, FlxText> = new Map<String, FlxText>();
	public var modchartSaves:Map<String, FlxSave> = new Map<String, FlxSave>();
	#end

	public var BF_X:Float = 770;
	public var BF_Y:Float = 100;
	public var DAD_X:Float = 100;
	public var DAD_Y:Float = 100;
	public var GF_X:Float = 400;
	public var GF_Y:Float = 130;

	public var songSpeedTween:FlxTween;
	public var songSpeed(default, set):Float = 1;
	public var songSpeedType:String = "multiplicative";
	public var noteKillOffset:Float = 350;

	public var playbackRate(default, set):Float = 1;

	public var boyfriendGroup:FlxSpriteGroup;
	public var dadGroup:FlxSpriteGroup;
	public var gfGroup:FlxSpriteGroup;
	public static var curStage:String = '';
	public static var stageUI:String = "default";
	public static var isPixelStage:Bool = false;

	public static var SONG:SwagSong = null;
	public static var isStoryMode:Bool = false;
	public static var storyWeek:Int = 0;
	public static var storyPlaylist:Array<String> = [];
	public static var storyDifficulty:Int = 1;

	public var spawnTime:Float = 2000;

	public var vocals:FlxSound;
	public var inst:FlxSound;

	public var dad:Character = null;
	public var gf:Character = null;
	public var boyfriend:Character = null;

	public var notes:FlxTypedGroup<Note>;
	public var unspawnNotes:Array<Note> = [];
	public var eventNotes:Array<EventNote> = [];

	public var camFollow:FlxObject;
	private static var prevCamFollow:FlxObject;

	public var strumLineNotes:FlxTypedGroup<StrumNote>;
	public var opponentStrums:FlxTypedGroup<StrumNote>;
	public var playerStrums:FlxTypedGroup<StrumNote>;
	public var grpNoteSplashes:FlxTypedGroup<NoteSplash>;
	public var spacebarNote:StrumNote;

	public var hasExtraNote = false;

	public var camZooming:Bool = false;
	public var camZoomingMult:Float = 1;
	public var camZoomingDecay:Float = 1;
	private var curSong:String = "";

	public var gfSpeed:Int = 1;
	public var health:Float = 1;
	public var combo:Int = 0;

	public var healthBar:HealthBar;
	public var timeBar:HealthBar;
	var songPercent:Float = 0;

	public var ratingsData:Array<Rating> = Rating.loadDefault();
	public var fullComboFunction:Void->Void = null;

	private var generatedMusic:Bool = false;
	public var endingSong:Bool = false;
	public var startingSong:Bool = false;
	private var updateTime:Bool = true;
	public static var changedDifficulty:Bool = false;
	public static var chartingMode:Bool = false;

	//Gameplay settings
	public var healthGain:Float = 1;
	public var healthLoss:Float = 1;
	public var instakillOnMiss:Bool = false;
	public var cpuControlled:Bool = false;
	public var practiceMode:Bool = false;

	public var botplaySine:Float = 0;
	public var botplayTxt:FlxText;

	public var iconP1:HealthIcon;
	public var iconP2:HealthIcon;
	public var camHUD:FlxCamera;
	public var camGame:FlxCamera;
	public var camOther:FlxCamera;
	public var cameraSpeed:Float = 1;

	public var songScore:Int = 0;
	public var songHits:Int = 0;
	public var songMisses:Int = 0;
	public var scoreTxt:FlxText;
	var timeTxt:FlxText;
	var scoreTxtTween:FlxTween;

	public var stageZoomVal:Float = 1; //For the Camera Zoom event.

	public static var campaignScore:Int = 0;
	public static var campaignMisses:Int = 0;
	public static var seenCutscene:Bool = false;
	public static var deathCounter:Int = 0;

	public var defaultCamZoom:Float = 1.05;

	// how big to stretch the pixel art assets
	public static var daPixelZoom:Float = 6;
	private var singAnimations:Array<String> = ['singLEFT', 'singDOWN', 'singUP', 'singRIGHT'];

	public var inCutscene:Bool = false;
	public var skipCountdown:Bool = false;
	var songLength:Float = 0;

	public var boyfriendCameraOffset:Array<Float> = null;
	public var opponentCameraOffset:Array<Float> = null;
	public var girlfriendCameraOffset:Array<Float> = null;

	#if desktop
	// Discord RPC variables
	var storyDifficultyText:String = "";
	var detailsText:String = "";
	var detailsPausedText:String = "";
	#end

	//Achievement stuff
	var keysPressed:Array<Int> = [];
	var boyfriendIdleTime:Float = 0.0;
	var boyfriendIdled:Bool = false;

	// Lua stuff
	public static var instance:PlayState;
	public var luaArray:Array<FunkinLua> = [];
	#if LUA_ALLOWED
	private var luaDebugGroup:FlxTypedGroup<DebugLuaText>;
	#end
	public var introSoundsSuffix:String = '';

	// Less laggy controls
	private var keysArray:Array<String>;

	public var precacheList:Map<String, String> = new Map<String, String>();
	public var songName:String;

	// Callbacks for stages
	public var startCallback:Void->Void = null;
	public var endCallback:Void->Void = null;

	// Variables required for the results screen
	public static var sicks:Int = 0;
	public static var goods:Int = 0;
	public static var bads:Int = 0;
	public static var trashes:Int = 0;

	public var lyricText:FlxText;

	var dadbattleBlack:BGSprite;
	var dadbattleLight:BGSprite;
	var dadbattleFog:DadBattleFog;

	//For Philly Glow events
	var blammedLightsBlack:FlxSprite;
	var phillyGlowGradient:PhillyGlowGradient;
	var phillyGlowParticles:FlxTypedGroup<PhillyGlowParticle>;
	var phillyWindowEvent:BGSprite;
	var curLightEvent:Int = -1;
	var phillyLightsColors:Array<FlxColor>;

	//New Psych DS Variables
	public var extraSong:String = '';
	public var instaKillNotes:Bool = true;
	public var botplaySpr:FlxSprite;
	public var practiceSpr:FlxSprite;
	public var practiceSine:Float = 0;
	public var camDialogue:FlxCamera;
	public var bfDodging:Bool = false;
	public var dodginTime:Bool = false;
	public static var bfCanDodge:Bool = false;
	public var bfDodgeCooldown:Float = 0.1125; //0.1125 for single dodge events (most forgiving), reduce it if you want double dodge events
	public var bfDodgeTiming:Float = 0.425; //0.425 for single dodge events (most forgiving), reduce it if you want double dodge events
	public var dodgeCount:Int = 0;
	public var warningSign:FlxSprite;
	public var dsFilterOn:Bool = false;
	var extra:Array<String> = ['blah blah blah', 'coolswag'];
	var seenEndDialogue:Bool = false;
	var resultsShow:Bool = false;
	public var unlockNextWeek:Bool = true;
	public var leSongName:FlxText;
	public var leDiffName:FlxText;
	public var leComposer:FlxText;
	public var skipSongBlurb:Bool = false;
	public var opponentNoteVisible:Bool = true;
	public var forceMiddlescroll:Bool = false;
	public static var isMiddleScroll:Bool = false;
	private var floatTrash:Float = 0;
	public static var highestCombo:Int = 0;
	var curPlayer:Int = 1;
	public var bfFloating:Bool = false;
	public var gfFloating:Bool = false;
	public var dadFloating:Bool = false;
	public var healthDrain:Bool = false;
	public var healthDrainValue:Float = 0.025;
	public static var songAccuracy:Float;
	var usedPractice:Bool = (ClientPrefs.getGameplaySetting('practice', false) || ClientPrefs.getGameplaySetting('botplay', false));
	var songBlurbStuff:CoolSongBlurb = null;
	var blurbTimer:FlxTimer;
	public var customUnlock:String = '';
	var phillyGlowOn:Bool = false;
	public var phillyGlowFG:BGSprite;
	public var noteTexture:String = 'Default';
	public var splashTexture:String = 'Default';
	public var barSkin:String = 'Default';

	override public function create()
	{	
		bfCanDodge = false;
		highestCombo = 0;
		sicks = 0;
		goods = 0;
		bads = 0;
		trashes = 0;
		Paths.clearStoredMemory();

		startCallback = startCountdown;
		endCallback = endSong;

		// for lua
		instance = this;

		PauseSubState.songName = null; //Reset to default
		playbackRate = ClientPrefs.getGameplaySetting('songspeed');
		fullComboFunction = fullComboUpdate;

		keysArray = [
			'note_left',
			'note_down',
			'note_up',
			'note_right',
			'note_extra'
		];

		if (FlxG.sound.music != null)
			FlxG.sound.music.stop();

		// Gameplay settings
		healthGain = ClientPrefs.getGameplaySetting('healthgain');
		healthLoss = ClientPrefs.getGameplaySetting('healthloss');
		instakillOnMiss = ClientPrefs.getGameplaySetting('instakill');
		practiceMode = ClientPrefs.getGameplaySetting('practice');
		cpuControlled = ClientPrefs.getGameplaySetting('botplay');
		instaKillNotes = ClientPrefs.getGameplaySetting('hurtkills', true);
		curPlayer = ClientPrefs.data.playerChar;

		camGame = new FlxCamera();
		camHUD = new FlxCamera();
		camOther = new FlxCamera();
		camDialogue = new FlxCamera();
		camHUD.bgColor.alpha = 0;
		camOther.bgColor.alpha = 0;
		camDialogue.bgColor.alpha = 0;

		if (SONG == null)
			SONG = Song.loadFromJson('tutorial');

		switch (SONG.forceDSFilter)
		{
			case 'Off':
				dsFilterOn = false;
			case 'On':
				dsFilterOn = true;
			default:
				if (ClientPrefs.data.dsFilter)
					dsFilterOn = true;
				else
					dsFilterOn = false;
		}

		//Kinda cruddy but it works
		FlxG.cameras.reset(camGame);
		if (dsFilterOn)
			FlxG.cameras.add(camDialogue);
		FlxG.cameras.add(camHUD);
		if (!dsFilterOn)
			FlxG.cameras.add(camDialogue);
		FlxG.cameras.add(camOther);
		grpNoteSplashes = new FlxTypedGroup<NoteSplash>();

		// setDefaultDrawTarget doesn't make the camera scroll when I compile the game so I have to use defaultCameras instead.
		//FlxG.cameras.setDefaultDrawTarget(camGame, true);
		FlxCamera.defaultCameras = [camGame];
		CustomFadeTransition.nextCamera = camOther;

		persistentUpdate = true;
		persistentDraw = true;

		Conductor.mapBPMChanges(SONG);
		Conductor.bpm = SONG.bpm;

		if (dsFilterOn)
		{
			if (ClientPrefs.data.downScroll)
			{
				camGame.setScale(0.485, 0.485);
				camGame.setPosition(0, -195);
	
				camHUD.setScale(0.485, 0.485);
				camHUD.setPosition(0, 185);
	
				camDialogue.setScale(0.485, 0.485);
				camDialogue.setPosition(0, -178);
			}
			else
			{
				camGame.setScale(0.485, 0.485);
				camGame.setPosition(0, 185);
	
				camHUD.setScale(0.485, 0.485);
				camHUD.setPosition(0, -185);
	
				camDialogue.setScale(0.485, 0.485);
				camDialogue.setPosition(0, 185);
			}
		}

		#if desktop
		storyDifficultyText = Difficulty.getString();

		// String that contains the mode defined here so it isn't necessary to call changePresence for each mode
		if (isStoryMode)
			detailsText = "Story Mode: " + WeekData.getCurrentWeek().weekName;
		else
			detailsText = "Freeplay";

		// String for when the game is paused
		detailsPausedText = "Paused - " + detailsText;
		#end
		if (isStoryMode)
		{
			unlockNextWeek = true;
		}
		else
		{
			unlockNextWeek = false;
		}

		if (SONG.song.toLowerCase() == 'pizza time')
		{
			unlockNextWeek = true;
			customUnlock = 'hiddentec';
		}
		else
			customUnlock = WeekData.weeksList[storyWeek];

		GameOverSubstate.resetVariables();
		ResultsScreen.resetVariables();

		songName = Paths.formatToSongPath(SONG.song);
		if(SONG.stage == null || SONG.stage.length < 1) {
			SONG.stage = StageData.vanillaSongStage(songName);
		}
		curStage = SONG.stage;

		var stageData:StageFile = StageData.getStageFile(curStage);
		if(stageData == null) { //Stage couldn't be found, create a dummy stage for preventing a crash
			stageData = StageData.dummy();
		}

		defaultCamZoom = stageData.defaultZoom;
		stageZoomVal = stageData.defaultZoom;
		isPixelStage = stageData.isPixelStage;

		stageUI = ClientPrefs.data.comboHUDDir;
		if (stageData.stageUI != null && stageData.stageUI.trim().length > 0)
			stageUI = stageData.stageUI;
		
		BF_X = stageData.boyfriend[0];
		BF_Y = stageData.boyfriend[1];
		GF_X = stageData.girlfriend[0];
		GF_Y = stageData.girlfriend[1];
		DAD_X = stageData.opponent[0];
		DAD_Y = stageData.opponent[1];

		if(stageData.camera_speed != null)
			cameraSpeed = stageData.camera_speed;

		boyfriendCameraOffset = stageData.camera_boyfriend;
		if(boyfriendCameraOffset == null) //should have done it since the start :rolling_eyes:
			boyfriendCameraOffset = [0, 0];

		opponentCameraOffset = stageData.camera_opponent;
		if(opponentCameraOffset == null)
			opponentCameraOffset = [0, 0];

		girlfriendCameraOffset = stageData.camera_girlfriend;
		if(girlfriendCameraOffset == null)
			girlfriendCameraOffset = [0, 0];

		boyfriendGroup = new FlxSpriteGroup(BF_X, BF_Y);
		dadGroup = new FlxSpriteGroup(DAD_X, DAD_Y);
		gfGroup = new FlxSpriteGroup(GF_X, GF_Y);

		if (PlayState.SONG.arrowSkin != null && PlayState.SONG.arrowSkin.length > 0)	
			noteTexture = PlayState.SONG.arrowSkin;
		if (PlayState.SONG.splashSkin != null && PlayState.SONG.splashSkin.length > 0)	
			splashTexture = PlayState.SONG.splashSkin;
		else
			splashTexture = ClientPrefs.data.splashSkin;

		if (PlayState.SONG.barSkin != null && PlayState.SONG.barSkin.length > 0)	
			barSkin = PlayState.SONG.barSkin;
		else
			barSkin = ClientPrefs.data.healthAndTimeBars;

		var path:String = 'assets/images/bottomScreens/';
		if (dsFilterOn)
		{
			if (FileSystem.exists('assets/images/bottomScreens/' + curStage + '.png') || FileSystem.exists(Paths.modFolders('images/bottomScreens/' + curStage + '.png')))
			{
				var bottomScreen:FlxSprite = new FlxSprite(0, 0).loadGraphic(Paths.image('bottomScreens/' + curStage));
				bottomScreen.cameras = [camHUD];
				add(bottomScreen);
			}
			else
			{
				var bottomScreen:FlxSprite = new FlxSprite(0, 0).makeGraphic(FlxG.width, FlxG.height, FlxColor.BLACK);
				bottomScreen.cameras = [camHUD];
				add(bottomScreen);
			}
		}

		switch (curStage)
		{
			case 'stage': new states.stages.StageWeek1(); //Week 1
			case 'spooky': new states.stages.Spooky(); //Week 2
			case 'philly': new states.stages.Philly(); //Week 3
			case 'limo': new states.stages.Limo(); //Week 4
			case 'mall': new states.stages.Mall(); //Week 5 - Cocoa, Eggnog
			case 'mallEvil': new states.stages.MallEvil(); //Week 5 - Winter Horrorland
			case 'school': new states.stages.School(); //Week 6 - Senpai, Roses
			case 'schoolEvil': new states.stages.SchoolEvil(); //Week 6 - Thorns
			case 'tank': new states.stages.Tank(); //Week 7 - Ugh, Guns, Stress
			case 'DimensionalBorder': new states.stages.DimensionalBorder(); //Week Secret - Big Shot, Konga Conga Kappa, Laugh Track
			case 'pizza': new states.stages.Pizza(); //Extra Secret Song - Pizza Time
		}

		phillyLightsColors = [0xFF31A2FD, 0xFF31FD8C, 0xFFFB33F5, 0xFFFD4531, 0xFFFBA633];
		if (FileSystem.exists('assets/images/glowFGs/' + curStage + '.png') || FileSystem.exists(Paths.modFolders('images/glowFGs/' + curStage + '.png')))
		{
			phillyGlowFG = new BGSprite('glowFGs/' + curStage, -200, -200, 1, 1);
			phillyGlowFG.visible = false;
			if (curStage != 'limo')
				add(phillyGlowFG);
		}
		else
		{
			phillyGlowFG = new BGSprite('glowFGs/Blank', -200, -200, 1, 1);
			phillyGlowFG.visible = false;
			add(phillyGlowFG);
		}
		switch (curStage)
		{
			case 'stage':
				phillyGlowFG.x = -650;
				phillyGlowFG.y = 600;
				phillyGlowFG.scrollFactor.set(0.9, 0.9);
				phillyGlowFG.setGraphicSize(Std.int(phillyGlowFG.width * 1.1));
				phillyGlowFG.updateHitbox();
			case 'spooky':
				phillyGlowFG.x = -200;
				phillyGlowFG.y = -100;
			case 'philly':
				phillyGlowFG.x = -40;
				phillyGlowFG.y = 50;
			case 'limo':
				phillyGlowFG.x = -120;
				phillyGlowFG.y = 550;
			case 'mall':
				phillyGlowFG.x = -600;
				phillyGlowFG.y = 700;
			case 'mallEvil':
				phillyGlowFG.x = -200;
				phillyGlowFG.y = 700;
			case 'school':
				phillyGlowFG.x = -200;
				phillyGlowFG.y = 0;
				phillyGlowFG.scrollFactor.set(0.95, 0.95);
				phillyGlowFG.setGraphicSize(Std.int(phillyGlowFG.width * 6));
				phillyGlowFG.updateHitbox();
				phillyGlowFG.antialiasing = false;
			case 'schoolEvil':
				phillyGlowFG.x = -200;
				phillyGlowFG.y = 0;
				phillyGlowFG.scrollFactor.set(0.95, 0.95);
				phillyGlowFG.setGraphicSize(Std.int(phillyGlowFG.width * 6));
				phillyGlowFG.updateHitbox();
				phillyGlowFG.antialiasing = false;
			case 'tank':
				phillyGlowFG.x = -420;
				phillyGlowFG.y = -150;
				phillyGlowFG.setGraphicSize(Std.int(phillyGlowFG.width * 1.15));
				phillyGlowFG.updateHitbox();
			case 'DimensionalBorder':
				phillyGlowFG.x = -500;
				phillyGlowFG.y = 600;
				phillyGlowFG.setGraphicSize(Std.int(phillyGlowFG.width * 1.1));
				phillyGlowFG.updateHitbox();
			case 'pizza':
				phillyGlowFG.x = -250;
				phillyGlowFG.y = 30;
				phillyGlowFG.setGraphicSize(Std.int(phillyGlowFG.width * 2));
				phillyGlowFG.updateHitbox();
				phillyGlowFG.antialiasing = false;
		}

		if (dsFilterOn)
		{
			leSongName = new FlxText(0, 270, FlxG.width, '', 60);
			leSongName.scrollFactor.set();
			leSongName.cameras = [camHUD];
			leSongName.setFormat(Paths.font("vcr.ttf"), 35, FlxColor.WHITE, CENTER, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
			leSongName.borderSize = 2.05;
		
			leDiffName = new FlxText(0, 305, FlxG.width, '', 60);
			leDiffName.scrollFactor.set();
			leDiffName.cameras = [camHUD];
			leDiffName.setFormat(Paths.font("vcr.ttf"), 35, FlxColor.WHITE, CENTER, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
			leDiffName.borderSize = 2.05;
			
			leComposer = new FlxText(0, 338, FlxG.width, "", 60);
			leComposer.scrollFactor.set();
			leComposer.cameras = [camHUD];
			leComposer.setFormat(Paths.font("vcr.ttf"), 35, FlxColor.WHITE, CENTER, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
			leComposer.borderSize = 2.05;
		
			var songName:String = Paths.formatToSongPath(SONG.song);
			var compFile:String;
			var songTitle:String = SONG.song;
			#if MODS_ALLOWED
			if (FileSystem.exists(Paths.modFolders('data/' + songName + '/Composer.txt')))
				compFile = Paths.modFolders('data/' + songName + '/Composer.txt');
			else
				compFile = Paths.txt(songName + '/Composer');
			#else
			compFile = Paths.txt(songName + '/Composer');
			#end
			var compName:Array<String> = CoolUtil.coolTextFile(compFile);
			leSongName.text = songTitle;
			leDiffName.text = Difficulty.getString().toUpperCase();
			add(leSongName);
			add(leDiffName);
			add(leComposer);
		
			if (compName != null)
				leComposer.text = compName[0];
			else
				leComposer.text = '';
		}

		if(isPixelStage) {
			introSoundsSuffix = '-pixel';
		}
		if(curStage == 'pizza') {
			introSoundsSuffix = '-pt';
		}

		add(gfGroup);
		add(dadGroup);
		add(boyfriendGroup);

		#if LUA_ALLOWED
		luaDebugGroup = new FlxTypedGroup<DebugLuaText>();
		luaDebugGroup.cameras = [camOther];
		add(luaDebugGroup);
		#end

		// "GLOBAL" SCRIPTS
		// I have to use how lua scripts were executed before because in Psych 0.7+ the source code forced Global & Song scripts to run twice...
		#if LUA_ALLOWED
		var filesPushed:Array<String> = [];
		var foldersToCheck:Array<String> = Mods.directoriesWithFile(Paths.getPreloadPath(), 'scripts/');

		for (folder in foldersToCheck)
		{
			if(FileSystem.exists(folder))
			{
				for (file in FileSystem.readDirectory(folder))
				{
					if(file.endsWith('.lua') && !file.endsWith('mainmenu.lua') && !file.endsWith('freeplay.lua') && !filesPushed.contains(file))
					{
						new FunkinLua(folder + file);
						filesPushed.push(file);
					}
					if(file.toLowerCase().endsWith('.hx') && !file.endsWith('mainmenu.hx') && !file.endsWith('freeplay.hx') && !filesPushed.contains(file))
					{
						initHScript(folder + file);
						filesPushed.push(file);
					}
				}
			}
		}
		#end

		if (dsFilterOn)
		{
			var dsFiltSpr:FlxSprite;
			dsFiltSpr = new FlxSprite(0, 0).loadGraphic(Paths.image('DS-Filters/' + ClientPrefs.data.dsBorder));
			dsFiltSpr.cameras = [camOther];
			add(dsFiltSpr);
		}

		// STAGE SCRIPTS
		#if LUA_ALLOWED
		startLuasNamed('stages/' + curStage + '.lua');
		#end

		#if HSCRIPT_ALLOWED
		startHScriptsNamed('stages/' + curStage + '.hx');
		#end

		if (!stageData.hide_girlfriend)
		{
			if(SONG.gfVersion == null || SONG.gfVersion.length < 1) SONG.gfVersion = 'gf'; //Fix for the Chart Editor
			gf = new Character(0, 0, SONG.gfVersion);
			startCharacterPos(gf);
			gf.scrollFactor.set(0.95, 0.95);
			gfGroup.add(gf);
			startCharacterScripts(gf.curCharacter);
		}

		dad = new Character(0, 0, SONG.player2);
		startCharacterPos(dad, true);
		dadGroup.add(dad);
		startCharacterScripts(dad.curCharacter);

		boyfriend = new Character(0, 0, SONG.player1, true);
		startCharacterPos(boyfriend);
		boyfriendGroup.add(boyfriend);
		startCharacterScripts(boyfriend.curCharacter);
		if (dad.curCharacter == 'wendy-tutorial')
			GF_Y -= 86;

		if (dad.curCharacter == 'ds-tutorial')
		{
			GF_Y -= 200;
		}

		var camPos:FlxPoint = FlxPoint.get(girlfriendCameraOffset[0], girlfriendCameraOffset[1]);
		if(gf != null)
		{
			camPos.x += gf.getGraphicMidpoint().x + gf.cameraPosition[0];
			camPos.y += gf.getGraphicMidpoint().y + gf.cameraPosition[1];
		}

		if(dad.curCharacter.startsWith('gf') || dad.curCharacter.endsWith('speakers') || dad.curCharacter.endsWith('tutorial')) {
			dad.setPosition(GF_X, GF_Y);
			if(gf != null)
				gf.visible = false;
		}
		stagesFunc(function(stage:BaseStage) stage.createPost());

		Conductor.songPosition = -5000 / Conductor.songPosition;
		var showTime:Bool = (ClientPrefs.data.timeBarType != 'Disabled');
		timeTxt = new FlxText(STRUM_X + (FlxG.width / 2) - 248, 19, 400, "", 32);
		timeTxt.setFormat(Paths.font("vcr.ttf"), 32, FlxColor.WHITE, CENTER, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		timeTxt.scrollFactor.set();
		timeTxt.alpha = 0;
		timeTxt.borderSize = 2;
		timeTxt.visible = updateTime = showTime;
		if(ClientPrefs.data.downScroll) timeTxt.y = FlxG.height - 44;
		if(ClientPrefs.data.timeBarType == 'Song Name') timeTxt.text = SONG.song;

		timeBar = new HealthBar(0, timeTxt.y + (timeTxt.height / 4), 'timeBar-' + barSkin, function() return songPercent, 0, 1);
		timeBar.scrollFactor.set();
		timeBar.screenCenter(X);
		timeBar.alpha = 0;
		timeBar.visible = showTime;
		add(timeBar);
		add(timeTxt);

		strumLineNotes = new FlxTypedGroup<StrumNote>();
		add(strumLineNotes);
		add(grpNoteSplashes);

		if(ClientPrefs.data.timeBarType == 'Song Name')
		{
			timeTxt.size = 24;
			timeTxt.y += 3;
		}

		var splash:NoteSplash = new NoteSplash(100, 100);
		grpNoteSplashes.add(splash);
		splash.alpha = 0.000001; //cant make it invisible or it won't allow precaching

		opponentStrums = new FlxTypedGroup<StrumNote>();
		playerStrums = new FlxTypedGroup<StrumNote>();

		generateSong(SONG.song);

		camFollow = new FlxObject(0, 0, 1, 1);
		camFollow.setPosition(camPos.x, camPos.y);
		camPos.put();
				
		if (prevCamFollow != null)
		{
			camFollow = prevCamFollow;
			prevCamFollow = null;
		}
		add(camFollow);

		if (dsFilterOn)
		{
			defaultCamZoom -= 0.42;
		}

		FlxG.camera.follow(camFollow, LOCKON, 0);
		FlxG.camera.zoom = defaultCamZoom;
		FlxG.camera.snapToTarget();

		FlxG.worldBounds.set(0, 0, FlxG.width, FlxG.height);
		moveCameraSection();

		healthBar = new HealthBar(0, FlxG.height * (!ClientPrefs.data.downScroll ? 0.89 : 0.11), 'healthBar-' + barSkin, function() return health, 0, 2);
		healthBar.screenCenter(X);
		healthBar.leftToRight = false;
		healthBar.scrollFactor.set();
		healthBar.visible = !ClientPrefs.data.hideHud;
		healthBar.alpha = ClientPrefs.data.healthBarAlpha;
		reloadHealthBarColors();
		add(healthBar);

		iconP1 = new HealthIcon(boyfriend.healthIcon, true);
		iconP1.y = healthBar.y - 75;
		iconP1.visible = !ClientPrefs.data.hideHud;
		iconP1.alpha = ClientPrefs.data.healthBarAlpha;
		add(iconP1);

		iconP2 = new HealthIcon(dad.healthIcon, false);
		iconP2.y = healthBar.y - 75;
		iconP2.visible = !ClientPrefs.data.hideHud;
		iconP2.alpha = ClientPrefs.data.healthBarAlpha;
		if (songName == 'pizza-time')
			iconP2.alpha = 0;
		add(iconP2);

		scoreTxt = new FlxText(0, healthBar.y + 40, FlxG.width, "", 20);
		scoreTxt.setFormat(Paths.font("vcr.ttf"), 20, FlxColor.WHITE, CENTER, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		scoreTxt.scrollFactor.set();
		scoreTxt.borderSize = 1.25;
		scoreTxt.visible = !ClientPrefs.data.hideHud;
		add(scoreTxt);
		if (dsFilterOn)
		{
			scoreTxt.size = 30;
			scoreTxt.borderSize = 2.05;
		}

		botplaySpr = new FlxSprite(-31, 540).loadGraphic(Paths.image('botplay'));
		botplaySpr.scrollFactor.set();
		botplaySpr.scale.set(0.6, 0.6);
		botplaySpr.visible = cpuControlled;
		add(botplaySpr);
		if (ClientPrefs.data.downScroll)
		{
			botplaySpr.y = 12;
		}

		practiceSpr = new FlxSprite(900, 540).loadGraphic(Paths.image('practice'));
		practiceSpr.scrollFactor.set();
		practiceSpr.scale.set(0.6, 0.6);
		practiceSpr.visible = practiceMode;
		add(practiceSpr);
		if (ClientPrefs.data.downScroll)
		{
			practiceSpr.y = 12;
		}

		warningSign = new FlxSprite(500, 200);
		warningSign.frames = Paths.getSparrowAtlas('Warning_Thing');
		warningSign.animation.addByPrefix('alert', "Show", 45, false);
		warningSign.antialiasing = true;
		warningSign.setGraphicSize(Std.int(warningSign.width * 1));
		warningSign.updateHitbox();
		warningSign.cameras = [camHUD];
		add(warningSign);
		warningSign.visible = false;

		lyricText = new FlxText(0, 480, FlxG.width, "", 24);
		lyricText.setFormat(Paths.font("vcr.ttf"), 24, FlxColor.WHITE, CENTER, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		lyricText.scrollFactor.set();
		lyricText.borderSize = 1.25;
		lyricText.cameras = [camDialogue];
		add(lyricText);

		strumLineNotes.cameras = [camHUD];
		grpNoteSplashes.cameras = [camHUD];
		notes.cameras = [camHUD];

		healthBar.cameras = [camHUD];
		iconP1.cameras = [camHUD];
		iconP2.cameras = [camHUD];
		scoreTxt.cameras = [camHUD];

		botplaySpr.cameras = [camHUD];
		practiceSpr.cameras = [camHUD];
		timeBar.cameras = [camHUD];
		timeTxt.cameras = [camHUD];

		startingSong = true;

		if(PlayState.SONG.gameOverChar == null || PlayState.SONG.gameOverChar.trim().length < 1)
		{
			switch (boyfriend.curCharacter)
			{
				case 'bf' | 'bf-car' | 'bf-christmas':
					GameOverSubstate.deathSoundName = 'gameOvers/fnf_loss_sfx';
					GameOverSubstate.characterName = 'bf-dead';
					GameOverSubstate.loopSoundName = 'gameOvers/gameOver';
					GameOverSubstate.endSoundName = 'gameOvers/gameOverEnd';
				case 'jr' | 'jr-christmas':
					GameOverSubstate.deathSoundName = 'gameOvers/fnf_loss_sfx-jr';
					GameOverSubstate.characterName = 'jr-dead';
					GameOverSubstate.loopSoundName = 'gameOvers/gameOver';
					GameOverSubstate.endSoundName = 'gameOvers/gameOverEnd';
				case 'monika' | 'monika-christmas':
					GameOverSubstate.deathSoundName = 'gameOvers/fnf_loss_sfx-monika';
					GameOverSubstate.characterName = 'monika-dead';
					GameOverSubstate.loopSoundName = 'gameOvers/gameOver';
					GameOverSubstate.endSoundName = 'gameOvers/gameOverEnd';
				case 'bf-holding-gf':
					GameOverSubstate.deathSoundName = 'gameOvers/fnf_loss_sfx';
					GameOverSubstate.characterName = 'bf-holding-gf-dead';
					GameOverSubstate.loopSoundName = 'gameOvers/gameOver-angry';
					GameOverSubstate.endSoundName = 'gameOvers/gameOverEnd-angry';
				case 'jr-pirate' | 'jr-holding-wendy':
					GameOverSubstate.deathSoundName = 'gameOvers/fnf_loss_sfx-jr';
					GameOverSubstate.characterName = 'jr-dead';
					GameOverSubstate.loopSoundName = 'gameOvers/gameOver-angry';
					GameOverSubstate.endSoundName = 'gameOvers/gameOverEnd-angry';
				case 'monika-neo':
					GameOverSubstate.deathSoundName = 'gameOvers/fnf_loss_sfx-monika-angry';
					GameOverSubstate.characterName = 'monika-neo-dead';
					GameOverSubstate.loopSoundName = 'gameOvers/gameOver-angry';
					GameOverSubstate.endSoundName = 'gameOvers/gameOverEnd-angry';
				case 'moni-neo-and-ds':
					GameOverSubstate.deathSoundName = 'gameOvers/fnf_loss_sfx-monika-angry';
					GameOverSubstate.characterName = 'moni-neo-and-ds-dead';
					GameOverSubstate.loopSoundName = 'gameOvers/gameOver-angry';
					GameOverSubstate.endSoundName = 'gameOvers/gameOverEnd-angry';
				case 'bf-pixel':
					GameOverSubstate.deathSoundName = 'gameOvers/fnf_loss_sfx-pixel';
					GameOverSubstate.characterName = 'bf-pixel-dead';
					GameOverSubstate.loopSoundName = 'gameOvers/gameOver-pixel';
					GameOverSubstate.endSoundName = 'gameOvers/gameOverEnd-pixel';
				case 'jr-pixel':
					GameOverSubstate.deathSoundName = 'gameOvers/fnf_loss_sfx-jr-pixel';
					GameOverSubstate.characterName = 'jr-pixel-dead';
					GameOverSubstate.loopSoundName = 'gameOvers/gameOver-pixel';
					GameOverSubstate.endSoundName = 'gameOvers/gameOverEnd-pixel';
				case 'monika-pixel':
					GameOverSubstate.deathSoundName = 'gameOvers/fnf_loss_sfx-monika-pixel';
					GameOverSubstate.characterName = 'monika-pixel-dead';
					GameOverSubstate.loopSoundName = 'gameOvers/gameOver-pixel';
					GameOverSubstate.endSoundName = 'gameOvers/gameOverEnd-pixel';
			}
		}
		
		#if LUA_ALLOWED
		for (notetype in noteTypes)
			startLuasNamed('custom_notetypes/' + notetype + '.lua');

		for (event in eventsPushed)
			startLuasNamed('custom_events/' + event + '.lua');
		#end

		#if HSCRIPT_ALLOWED
		for (notetype in noteTypes)
			startHScriptsNamed('custom_notetypes/' + notetype + '.hx');

		for (event in eventsPushed)
			startHScriptsNamed('custom_events/' + event + '.hx');
		#end
		noteTypes = null;
		eventsPushed = null;

		if(eventNotes.length > 1)
		{
			for (event in eventNotes) event.strumTime -= eventEarlyTrigger(event);
			eventNotes.sort(sortByTime);
		}

		// SONG SPECIFIC SCRIPTS
		// I have to use how lua scripts were executed before because in Psych 0.7+ the source code forced Global & Song scripts to run twice...
		#if LUA_ALLOWED
		var filesPushed:Array<String> = [];
		var foldersToCheck:Array<String> = Mods.directoriesWithFile(Paths.getPreloadPath(), 'data/' + songName + '/');

		for (folder in foldersToCheck)
		{
			if(FileSystem.exists(folder))
			{
				for (file in FileSystem.readDirectory(folder))
				{
					if(file.endsWith('.lua') && !filesPushed.contains(file))
					{
						new FunkinLua(folder + file);
						filesPushed.push(file);
					}
					if(file.endsWith('.hx') && !filesPushed.contains(file))
					{
						initHScript(folder + file);
						filesPushed.push(file);
					}
				}
			}
		}
		#end

		if (songName == 'mild')
			dodginTime = true;

		startCallback();
		RecalculateRating();

		//PRECACHING MISS SOUNDS BECAUSE I THINK THEY CAN LAG PEOPLE AND SCREW THEM UP IDK HOW HAXE WORKS
		if(ClientPrefs.data.hitsoundVolume > 0) precacheList.set('hitsound', 'sound');
		if(ClientPrefs.data.misssoundVolume > 0)
		{
			precacheList.set('missnote1', 'sound');
			precacheList.set('missnote2', 'sound');
			precacheList.set('missnote3', 'sound');
		}

		if (PauseSubState.songName != null) {
			precacheList.set(PauseSubState.songName, 'music');
		} else if(ClientPrefs.data.pauseMusic != 'None') {
			precacheList.set(Paths.formatToSongPath(ClientPrefs.data.pauseMusic), 'music');
		}

		precacheList.set('alphabet', 'image');
		resetRPC();

		FlxG.stage.addEventListener(KeyboardEvent.KEY_DOWN, onKeyPress);
		FlxG.stage.addEventListener(KeyboardEvent.KEY_UP, onKeyRelease);
		callOnScripts('onCreatePost');

		cacheCountdown();
		cachePopUpScore();
		
		for (key => type in precacheList)
		{
			switch(type)
			{
				case 'image':
					Paths.image(key);
				case 'sound':
					Paths.sound(key);
				case 'music':
					Paths.music(key);
			}
		}

		super.create();
		Paths.clearUnusedMemory();
		
		CustomFadeTransition.nextCamera = camOther;
		if(eventNotes.length < 1) checkEventNote();
	}

	function set_songSpeed(value:Float):Float
	{
		if(generatedMusic)
		{
			var ratio:Float = value / songSpeed; //funny word huh
			if(ratio != 1)
			{
				for (note in notes.members) note.resizeByRatio(ratio);
				for (note in unspawnNotes) note.resizeByRatio(ratio);
			}
		}
		songSpeed = value;
		noteKillOffset = Math.max(Conductor.stepCrochet, 350 / songSpeed * playbackRate);
		return value;
	}

	function set_playbackRate(value:Float):Float
	{
		if(generatedMusic)
		{
			if(vocals != null) vocals.pitch = value;
			FlxG.sound.music.pitch = value;

			var ratio:Float = playbackRate / value; //funny word huh
			if(ratio != 1)
			{
				for (note in notes.members) note.resizeByRatio(ratio);
				for (note in unspawnNotes) note.resizeByRatio(ratio);
			}
		}
		playbackRate = value;
		FlxAnimationController.globalSpeed = value;
		Conductor.safeZoneOffset = (ClientPrefs.data.safeFrames / 60) * 1000 * value;
		setOnScripts('playbackRate', playbackRate);
		return value;
	}

	public function addTextToDebug(text:String, color:FlxColor) {
		#if LUA_ALLOWED
		var newText:DebugLuaText = luaDebugGroup.recycle(DebugLuaText);
		newText.text = text;
		newText.color = color;
		newText.disableTime = 6;
		newText.alpha = 1;
		newText.setPosition(10, 8 - newText.height);

		luaDebugGroup.forEachAlive(function(spr:DebugLuaText) {
			spr.y += newText.height + 2;
		});
		luaDebugGroup.add(newText);
		#end
	}

	public function reloadHealthBarColors() {
		healthBar.setColors(FlxColor.fromRGB(dad.healthColorArray[0], dad.healthColorArray[1], dad.healthColorArray[2]),
			FlxColor.fromRGB(boyfriend.healthColorArray[0], boyfriend.healthColorArray[1], boyfriend.healthColorArray[2]));
	}

	public function addCharacterToList(newCharacter:String, type:Int) {
		switch(type) {
			case 0:
				if(!boyfriendMap.exists(newCharacter)) {
					var newBoyfriend:Character = new Character(0, 0, newCharacter, true);
					boyfriendMap.set(newCharacter, newBoyfriend);
					boyfriendGroup.add(newBoyfriend);
					startCharacterPos(newBoyfriend);
					newBoyfriend.alpha = 0.00001;
					startCharacterScripts(newBoyfriend.curCharacter);
				}

			case 1:
				if(!dadMap.exists(newCharacter)) {
					var newDad:Character = new Character(0, 0, newCharacter);
					dadMap.set(newCharacter, newDad);
					dadGroup.add(newDad);
					startCharacterPos(newDad, true);
					newDad.alpha = 0.00001;
					startCharacterScripts(newDad.curCharacter);
				}

			case 2:
				if(gf != null && !gfMap.exists(newCharacter)) {
					var newGf:Character = new Character(0, 0, newCharacter);
					newGf.scrollFactor.set(0.95, 0.95);
					gfMap.set(newCharacter, newGf);
					gfGroup.add(newGf);
					startCharacterPos(newGf);
					newGf.alpha = 0.00001;
					startCharacterScripts(newGf.curCharacter);
				}
		}
	}

	function startCharacterScripts(name:String)
	{
		// Lua
		#if LUA_ALLOWED
		var doPush:Bool = false;
		var luaFile:String = 'characters/' + name + '.lua';
		#if MODS_ALLOWED
		var replacePath:String = Paths.modFolders(luaFile);
		if(FileSystem.exists(replacePath))
		{
			luaFile = replacePath;
			doPush = true;
		}
		else
		{
			luaFile = Paths.getPreloadPath(luaFile);
			if(FileSystem.exists(luaFile))
				doPush = true;
		}
		#else
		luaFile = Paths.getPreloadPath(luaFile);
		if(Assets.exists(luaFile)) doPush = true;
		#end

		if(doPush)
		{
			for (script in luaArray)
			{
				if(script.scriptName == luaFile)
				{
					doPush = false;
					break;
				}
			}
			if(doPush) new FunkinLua(luaFile);
		}
		#end

		// HScript
		#if HSCRIPT_ALLOWED
		var doPush:Bool = false;
		var scriptFile:String = 'characters/' + name + '.hx';
		var replacePath:String = Paths.modFolders(scriptFile);
		if(FileSystem.exists(replacePath))
		{
			scriptFile = replacePath;
			doPush = true;
		}
		else
		{
			scriptFile = Paths.getPreloadPath(scriptFile);
			if(FileSystem.exists(scriptFile))
				doPush = true;
		}
		
		if(doPush)
		{
			if(SScript.global.exists(scriptFile))
				doPush = false;

			if(doPush) initHScript(scriptFile);
		}
		#end
	}

	public function getLuaObject(tag:String, text:Bool=true):FlxSprite {
		#if LUA_ALLOWED
		#if VIDEOS_ALLOWED
		if(modchartVideos.exists(tag)) return modchartVideos.get(tag);
		#end
		if(modchartSprites.exists(tag)) return modchartSprites.get(tag);
		if(modchartBackdrops.exists(tag)) return modchartBackdrops.get(tag);
		if(text && modchartTexts.exists(tag)) return modchartTexts.get(tag);
		if(variables.exists(tag)) return variables.get(tag);
		#end
		return null;
	}

	function startCharacterPos(char:Character, ?gfCheck:Bool = false) {
		if(gfCheck && (char.curCharacter.startsWith('gf') || char.curCharacter.endsWith('speakers') || char.curCharacter.endsWith('tutorial'))) { //IF DAD IS GIRLFRIEND, HE GOES TO HER POSITION
			char.setPosition(GF_X, GF_Y);
			char.scrollFactor.set(0.95, 0.95);
			char.danceEveryNumBeats = 2;
		}
		char.x += char.positionArray[0];
		char.y += char.positionArray[1];
	}

	public function prepareVideo(name:String) {
		var filepath:String = Paths.video(name);
		#if sys
		if(!FileSystem.exists(filepath))
		#else
		if(!OpenFlAssets.exists(filepath))
		#end
		{
			FlxG.log.warn('Couldnt find video file: ' + name);
			startAndEnd();
			return;
		}
		startVideo(name);
	}

	public function startVideo(name:String)
	{
		if (!usedPractice)
		{
			#if VIDEOS_ALLOWED
			inCutscene = true;
			seenCutscene = true;

			var filepath:String = Paths.video(name);
			#if sys
			if(!FileSystem.exists(filepath))
			#else
			if(!OpenFlAssets.exists(filepath))
			#end
			{
				FlxG.log.warn('Couldnt find video file: ' + name);
				startAndEnd();
				return;
			}
			var bg = new FlxSprite(-FlxG.width, -FlxG.height).makeGraphic(FlxG.width * 3, FlxG.height * 3, FlxColor.BLACK);
			bg.scrollFactor.set();
			bg.cameras = [camDialogue];
			add(bg);

			var video:VideoSprite = new VideoSprite();
			video.scrollFactor.set();
			video.setGraphicSize(Std.int(video.width / 1));
			video.updateHitbox();
			video.antialiasing = ClientPrefs.data.antialiasing;
			video.cameras = [camDialogue];
			video.bitmap.canSkip = false;
			video.playVideo(filepath, false);
			video.finishCallback = function()
			{
				remove(bg);
				remove(video);
				if (SONG.song.toLowerCase() == 'stress' && !endingSong) stressDialogue();
				else startAndEnd();
				return;
			}
			add(video);
			#else
			FlxG.log.warn('Platform not supported!');
			startAndEnd();
			return;
			#end
		}
		else
		{
			startAndEnd();
			return;
		}
	}

	function startAndEnd()
	{
		if(endingSong) {
			if (!isStoryMode)
				showResults()
			else
				endSong();
		} else {
			startCountdown();
		}
	}

	// I have to do this in order for the dialogue to play after the video cutscene in Stress
	function stressDialogue()
	{
		if (curPlayer == 1) FlxG.sound.playMusic(Paths.music('KlaskiiRomper_Short'), 0);
		else if (curPlayer == 2) FlxG.sound.playMusic(Paths.music('PirateTime'), 0);
		else FlxG.sound.playMusic(Paths.music('MurderDronesNEO'), 0);
		FlxG.sound.music.fadeIn(2, 0, 0.7);

		new FlxTimer().start(1, function(tmr:FlxTimer) {
			switch (curPlayer) {
				case 1:
					PlayState.instance.startDialogue(DialogueBoxPsych.parseDialogue(Paths.json(songName + '/dialogueBF')));
				case 2:
					PlayState.instance.startDialogue(DialogueBoxPsych.parseDialogue(Paths.json(songName + '/dialogueJR')));
				case 3:
					PlayState.instance.startDialogue(DialogueBoxPsych.parseDialogue(Paths.json(songName + '/dialogueMONI')));
			}
		});
	}

	// I'm only keeping the Default Psych Engine Dialogue for backwards compatability.
	// And because of the Week 7 dialogue...

	var dialogueCount:Int = 0;
	public var psychDialogue:DialogueBoxPsych;
	//You don't have to add a song, just saying. You can just do "startDialogue(DialogueBoxPsych.parseDialogue(Paths.json(songName + '/dialogue')))" and it should load dialogue.json
	public function startDialogue(dialogueFile:DialogueFile, ?song:String = null):Void
	{
		if (!usedPractice)
		{
			// TO DO: Make this more flexible, maybe?
			if(psychDialogue != null) return;

			if(dialogueFile.dialogue.length > 0) {
				seenCutscene = true;
				inCutscene = true;
				dialogueCount = 0;
				precacheList.set('dialogue', 'sound');
				precacheList.set('dialogueClose', 'sound');
				psychDialogue = new DialogueBoxPsych(dialogueFile, song);
				psychDialogue.scrollFactor.set();
				if(endingSong) {
					psychDialogue.finishThing = function() {
						psychDialogue = null;
						if (!isStoryMode)
							showResults()
						else
							endSong();
					}
				} else {
					psychDialogue.finishThing = function() {
						psychDialogue = null;
						startCountdown();
					}
				}
				psychDialogue.nextDialogueThing = startNextDialogue;
				psychDialogue.skipDialogueThing = skipDialogue;
				psychDialogue.cameras = [camDialogue];
				add(psychDialogue);
			} else {
				FlxG.log.warn('Your dialogue file is badly formatted!');
				startAndEnd();
			}
		}
		else
		{
			startAndEnd();
			return;
		}
	}

	public var dsDialogue:DialogueBoxDS;
	//You don't have to add a song, just saying. You can just do "startDSDialogue(dialogueJson);" and it should work
	public function startDSDialogue(dialogueFile:DialogueFileDS, ?song:String = null):Void
	{
		if (!usedPractice)
		{
			// TO DO: Make this more flexible, maybe?
			if(dsDialogue != null) return;

			if(dialogueFile.dialogue.length > 0) {
				inCutscene = true;
				seenCutscene = true;
				dialogueCount = 0;
				precacheList.set('dialogue', 'sound');
				precacheList.set('dialogueClose', 'sound');
				dsDialogue = new DialogueBoxDS(dialogueFile, song);
				dsDialogue.scrollFactor.set();
				if(endingSong) {
					dsDialogue.finishThing = function() {
						dsDialogue = null;
						if (!isStoryMode)
							showResults()
						else
							endSong();
					}
				} else {
					dsDialogue.finishThing = function() {
						dsDialogue = null;
						startCountdown();
					}
				}
				dsDialogue.nextDialogueThing = startNextDialogue;
				dsDialogue.skipDialogueThing = skipDialogue;
				dsDialogue.cameras = [camDialogue];
				add(dsDialogue);
			} else {
				FlxG.log.warn('Your dialogue file is badly formatted!');
				startAndEnd();
			}
		}
		else
		{
			startAndEnd();
			return;
		}
	}

	var startTimer:FlxTimer;
	var finishTimer:FlxTimer = null;

	// For being able to mess with the sprites on Lua
	public var countdownReady:FlxSprite;
	public var countdownSet:FlxSprite;
	public var countdownGo:FlxSprite;
	public static var startOnTime:Float = 0;

	public function showResults():Void
	{
		resultsShow = true;
		endSong();
	}

	function leCoolSongName()
	{
		var name:String = SONG.song;

		var songName:String = Paths.formatToSongPath(SONG.song);
		var compFile:String = Paths.txt(songName + '/Composer');
		
		var compName:Array<String> = CoolUtil.coolTextFile(compFile);

		var composer:String = compName[0];

		songBlurbStuff = new CoolSongBlurb(name, composer);
		add(songBlurbStuff);
		songBlurbStuff.cameras = [camOther];
		songBlurbStuff.tweenIn();

		blurbTimer = new FlxTimer().start(5, function(tmr:FlxTimer)
		{
			songBlurbStuff.tweenOut();
		});
	}

	function cacheCountdown()
	{
		var introAssets:Map<String, Array<String>> = new Map<String, Array<String>>();
		var introImagesArray:Array<String> = switch(isPixelStage) {
			case true: ['pixelUI/hudFolders/${stageUI}UI/ready-pixel', 'pixelUI/hudFolders/${stageUI}UI/set-pixel', 'pixelUI/hudFolders/${stageUI}UI/go-pixel'];
			default: ['hudFolders/${stageUI}UI/ready', 'hudFolders/${stageUI}UI/set', 'hudFolders/${stageUI}UI/go'];
		}
		introAssets.set(stageUI, introImagesArray);
		var introAlts:Array<String> = introAssets.get(stageUI);
		for (asset in introAlts) Paths.image(asset);
		
		Paths.sound('intro3' + introSoundsSuffix);
		Paths.sound('intro2' + introSoundsSuffix);
		Paths.sound('intro1' + introSoundsSuffix);
		Paths.sound('introGo' + introSoundsSuffix);
	}

	public function startCountdown()
	{
		if(startedCountdown) {
			callOnScripts('onStartCountdown');
			return false;
		}

		if (ClientPrefs.data.middleScroll || forceMiddlescroll)
		{
			isMiddleScroll = true;
		}
		else
		{
			isMiddleScroll = false;
		}

		inCutscene = false;
		var ret:Dynamic = callOnScripts('onStartCountdown');
		if(ret != FunkinLua.Function_Stop) {
			if (skipCountdown || startOnTime > 0) skipArrowStartTween = true;

			generateStaticArrows(0);
			generateStaticArrows(1);
			for (i in 0...unspawnNotes.length) {
				if (unspawnNotes[i].noteType == "Extra Note" && unspawnNotes[i].mustPress) {
					unspawnNotes[i].noteData = 4;
					hasExtraNote = true;
				}
			}
			if (hasExtraNote) generateExtraArrow();
			for (i in 0...playerStrums.length) {
				setOnScripts('defaultPlayerStrumX' + i, playerStrums.members[i].x);
				setOnScripts('defaultPlayerStrumY' + i, playerStrums.members[i].y);
			}
			for (i in 0...opponentStrums.length) {
				setOnScripts('defaultOpponentStrumX' + i, opponentStrums.members[i].x);
				setOnScripts('defaultOpponentStrumY' + i, opponentStrums.members[i].y);
			}
			if (hasExtraNote) {
				setOnScripts('defaultExtraStrumX', spacebarNote.x);
				setOnScripts('defaultExtraStrumY', spacebarNote.y);
			}

			startedCountdown = true;
			Conductor.songPosition = -Conductor.crochet * 5;
			setOnScripts('startedCountdown', true);
			callOnScripts('onCountdownStarted', null);

			var swagCounter:Int = 0;
			if (startOnTime > 0) {
				clearNotesBefore(startOnTime);
				setSongTime(startOnTime - 350);
				return true;
			}
			else if (skipCountdown)
			{
				setSongTime(0);
				return true;
			}
			moveCameraSection();

			startTimer = new FlxTimer().start(Conductor.crochet / 1000 / playbackRate, function(tmr:FlxTimer)
			{
				if (gf != null && tmr.loopsLeft % Math.round(gfSpeed * gf.danceEveryNumBeats) == 0 && gf.animation.curAnim != null && !gf.animation.curAnim.name.startsWith("sing") && !gf.stunned)
					gf.dance();
				if (tmr.loopsLeft % boyfriend.danceEveryNumBeats == 0 && boyfriend.animation.curAnim != null && !boyfriend.animation.curAnim.name.startsWith('sing') && !boyfriend.stunned && !bfDodging)
					boyfriend.dance();
				if (tmr.loopsLeft % dad.danceEveryNumBeats == 0 && dad.animation.curAnim != null && !dad.animation.curAnim.name.startsWith('sing') && !dad.stunned)
					dad.dance();

				var introAssets:Map<String, Array<String>> = new Map<String, Array<String>>();
				var introImagesArray:Array<String> = switch(isPixelStage) {
					case true: ['pixelUI/hudFolders/${stageUI}UI/ready-pixel', 'pixelUI/hudFolders/${stageUI}UI/set-pixel', 'pixelUI/hudFolders/${stageUI}UI/go-pixel'];
					default: ['hudFolders/${stageUI}UI/ready', 'hudFolders/${stageUI}UI/set', 'hudFolders/${stageUI}UI/go'];
				}
				introAssets.set(stageUI, introImagesArray);

				var introAlts:Array<String> = introAssets.get(stageUI);
				var antialias:Bool = (ClientPrefs.data.antialiasing && !isPixelStage);
				var tick:Countdown = THREE;

				switch (swagCounter)
				{
					case 0:
						FlxG.sound.play(Paths.sound('intro3' + introSoundsSuffix), 0.6);
						tick = THREE;
					case 1:
						countdownReady = createCountdownSprite(introAlts[0], antialias);
						FlxG.sound.play(Paths.sound('intro2' + introSoundsSuffix), 0.6);
						tick = TWO;
						if (ClientPrefs.data.songBlurb && !skipSongBlurb)
						{
							if (!dsFilterOn)
								leCoolSongName();
						}
					case 2:
						countdownSet = createCountdownSprite(introAlts[1], antialias);
						FlxG.sound.play(Paths.sound('intro1' + introSoundsSuffix), 0.6);
						tick = ONE;
					case 3:
						countdownGo = createCountdownSprite(introAlts[2], antialias);
						FlxG.sound.play(Paths.sound('introGo' + introSoundsSuffix), 0.6);
						tick = GO;
					case 4:
						tick = START;
				}

				notes.forEachAlive(function(note:Note) {
					if((ClientPrefs.data.opponentStrums && opponentNoteVisible) || note.mustPress)
					{
						note.copyAlpha = false;
						note.alpha = note.multAlpha;
						if(ClientPrefs.data.middleScroll && !note.mustPress)
							note.alpha *= 0.35;
					}
				});

				stagesFunc(function(stage:BaseStage) stage.countdownTick(tick, swagCounter));
				callOnLuas('onCountdownTick', [swagCounter]);
				callOnHScript('onCountdownTick', [tick, swagCounter]);

				swagCounter += 1;
			}, 5);
		}
		return true;
	}

	inline private function createCountdownSprite(image:String, antialias:Bool):FlxSprite
	{
		var spr:FlxSprite = new FlxSprite().loadGraphic(Paths.image(image));
		if (dsFilterOn)
			spr.cameras = [camDialogue];
		else
			spr.cameras = [camHUD];
		spr.scrollFactor.set();
		spr.updateHitbox();

		if (PlayState.isPixelStage)
		{
			spr.setGraphicSize(Std.int(spr.width * daPixelZoom));
		}

		spr.screenCenter();
		spr.antialiasing = antialias;
		insert(members.indexOf(notes), spr);
		FlxTween.tween(spr, {alpha: 0}, Conductor.crochet / 1000, {
			ease: FlxEase.cubeInOut,
			onComplete: function(twn:FlxTween)
			{
				remove(spr);
				spr.destroy();
			}
		});
		return spr;
	}

	public function addBehindGF(obj:FlxBasic)
	{
		insert(members.indexOf(gfGroup), obj);
	}
	public function addBehindBF(obj:FlxBasic)
	{
		insert(members.indexOf(boyfriendGroup), obj);
	}
	public function addBehindDad(obj:FlxBasic)
	{
		insert(members.indexOf(dadGroup), obj);
	}

	public function clearNotesBefore(time:Float)
	{
		var i:Int = unspawnNotes.length - 1;
		while (i >= 0) {
			var daNote:Note = unspawnNotes[i];
			if(daNote.strumTime - 350 < time)
			{
				daNote.active = false;
				daNote.visible = false;
				daNote.ignoreNote = true;

				daNote.kill();
				unspawnNotes.remove(daNote);
				daNote.destroy();
			}
			--i;
		}

		i = notes.length - 1;
		while (i >= 0) {
			var daNote:Note = notes.members[i];
			if(daNote.strumTime - 350 < time)
			{
				daNote.active = false;
				daNote.visible = false;
				daNote.ignoreNote = true;

				daNote.kill();
				notes.remove(daNote, true);
				daNote.destroy();
			}
			--i;
		}
	}

	public function updateScore(miss:Bool = false)
	{
		if (isStoryMode)
		{
			scoreTxt.text = 'Score: ' + songScore
			+ ' | Misses: ' + songMisses
			+ ' | Rank: ' + ratingName
			+ (ratingName != '?' ? ' (${CoolUtil.floorDecimal(ratingPercent * 100, 2)}%) - $ratingFC' : '');
		}
		else
		{
			scoreTxt.text = 'Score: ' + songScore
			+ ' | Misses: ' + songMisses
			+ ' | Accuracy: ' + (ratingName != '?' ? '${CoolUtil.floorDecimal(ratingPercent * 100, 2)}% - $ratingFC' : '?');
		}

		if(ClientPrefs.data.scoreZoom && !miss && !cpuControlled)
		{
			if(scoreTxtTween != null) {
				scoreTxtTween.cancel();
			}
			scoreTxt.scale.x = 1.075;
			scoreTxt.scale.y = 1.075;
			scoreTxtTween = FlxTween.tween(scoreTxt.scale, {x: 1, y: 1}, 0.2, {
				onComplete: function(twn:FlxTween) {
					scoreTxtTween = null;
				}
			});
		}
		callOnScripts('onUpdateScore', [miss]);
	}

	public function setSongTime(time:Float)
	{
		if(time < 0) time = 0;

		FlxG.sound.music.pause();
		vocals.pause();

		FlxG.sound.music.time = time;
		FlxG.sound.music.pitch = playbackRate;
		FlxG.sound.music.play();

		if (Conductor.songPosition <= vocals.length)
		{
			vocals.time = time;
			vocals.pitch = playbackRate;
		}
		vocals.play();
		Conductor.songPosition = time;
	}

	public function startNextDialogue() {
		dialogueCount++;
		callOnScripts('onNextDialogue', [dialogueCount]);
	}

	public function skipDialogue() {
		callOnScripts('onSkipDialogue', [dialogueCount]);
	}

	function startSong():Void
	{
		startingSong = false;

		if (dodginTime && !ClientPrefs.getGameplaySetting('botplay', false))
			bfCanDodge = true;
		else
			bfCanDodge = false;

		@:privateAccess
		FlxG.sound.playMusic(inst._sound, 1, false);
		FlxG.sound.music.pitch = playbackRate;
		FlxG.sound.music.onComplete = finishSong.bind();
		vocals.play();

		if(startOnTime > 0) setSongTime(startOnTime - 500);
		startOnTime = 0;

		if(paused) {
			FlxG.sound.music.pause();
			vocals.pause();
		}

		// Song duration in a float, useful for the time left feature
		songLength = FlxG.sound.music.length;
		FlxTween.tween(timeBar, {alpha: 1}, 0.5, {ease: FlxEase.circOut});
		FlxTween.tween(timeTxt, {alpha: 1}, 0.5, {ease: FlxEase.circOut});

		#if desktop
		// Updating Discord Rich Presence (with Time Left)
		DiscordClient.changePresence(detailsText, SONG.song + " (" + storyDifficultyText + ")", iconP2.getCharacter(), true, songLength);
		#end
		setOnScripts('songLength', songLength);
		callOnScripts('onSongStart');
	}

	var debugNum:Int = 0;
	private var noteTypes:Array<String> = [];
	private var eventsPushed:Array<String> = [];
	private function generateSong(dataPath:String):Void
	{
		songSpeed = PlayState.SONG.speed;
		songSpeedType = ClientPrefs.getGameplaySetting('scrolltype');
		switch(songSpeedType)
		{
			case "multiplicative":
				songSpeed = SONG.speed * ClientPrefs.getGameplaySetting('scrollspeed');
			case "constant":
				songSpeed = ClientPrefs.getGameplaySetting('scrollspeed');
		}

		var songData = SONG;
		Conductor.bpm = songData.bpm;

		curSong = songData.song;

		vocals = new FlxSound();
		if (songData.needsVoices) vocals.loadEmbedded(Paths.voices(songData.song));

		vocals.pitch = playbackRate;
		FlxG.sound.list.add(vocals);

		inst = new FlxSound().loadEmbedded(Paths.inst(songData.song));
		FlxG.sound.list.add(inst);

		notes = new FlxTypedGroup<Note>();
		add(notes);

		var noteData:Array<SwagSection>;

		// NEW JUNK
		noteData = songData.notes;

		var file:String = Paths.json(songName + '/events');
		#if MODS_ALLOWED
		if (FileSystem.exists(Paths.modsJson(songName + '/events')) || FileSystem.exists(file))
		#else
		if (OpenFlAssets.exists(file))
		#end
		{
			var eventsData:Array<Dynamic> = Song.loadFromJson('events', songName).events;
			for (event in eventsData) //Event Notes
				for (i in 0...event[1].length)
					makeEvent(event, i);
		}

		for (section in noteData)
		{
			for (songNotes in section.sectionNotes)
			{
				var daStrumTime:Float = songNotes[0];
				var daNoteData:Int = Std.int(songNotes[1] % 4);
				var gottaHitNote:Bool = section.mustHitSection;

				if (songNotes[1] > 3)
				{
					gottaHitNote = !section.mustHitSection;
				}

				var oldNote:Note;
				if (unspawnNotes.length > 0)
					oldNote = unspawnNotes[Std.int(unspawnNotes.length - 1)];
				else
					oldNote = null;

				var swagNote:Note = new Note(daStrumTime, daNoteData, oldNote);
				swagNote.mustPress = gottaHitNote;
				swagNote.sustainLength = songNotes[2];
				swagNote.gfNote = (section.gfSection && (songNotes[1]<4));
				swagNote.noteType = songNotes[3];
				if(!Std.isOfType(songNotes[3], String)) swagNote.noteType = ChartingState.noteTypeList[songNotes[3]]; //Backward compatibility + compatibility with Week 7 charts

				swagNote.scrollFactor.set();

				var susLength:Float = swagNote.sustainLength;

				susLength = susLength / Conductor.stepCrochet;
				unspawnNotes.push(swagNote);

				var floorSus:Int = Math.floor(susLength);
				if(floorSus > 0) {
					for (susNote in 0...floorSus+1)
					{
						oldNote = unspawnNotes[Std.int(unspawnNotes.length - 1)];

						var sustainNote:Note = new Note(daStrumTime + (Conductor.stepCrochet * susNote), daNoteData, oldNote, true);
						sustainNote.mustPress = gottaHitNote;
						sustainNote.gfNote = (section.gfSection && (songNotes[1]<4));
						sustainNote.noteType = swagNote.noteType;
						sustainNote.scrollFactor.set();
						swagNote.tail.push(sustainNote);
						sustainNote.parent = swagNote;
						unspawnNotes.push(sustainNote);
						
						sustainNote.correctionOffset = swagNote.height / 2;
						if(!PlayState.isPixelStage)
						{
							if(oldNote.isSustainNote)
							{
								oldNote.scale.y *= Note.SUSTAIN_SIZE / oldNote.frameHeight;
								oldNote.scale.y /= playbackRate;
								oldNote.updateHitbox();
							}

							if(ClientPrefs.data.downScroll)
								sustainNote.correctionOffset = 0;
						}
						else if(oldNote.isSustainNote)
						{
							oldNote.scale.y /= playbackRate;
							oldNote.updateHitbox();
						}

						if (sustainNote.mustPress) sustainNote.x += FlxG.width / 2; // general offset
						else if(ClientPrefs.data.middleScroll)
						{
							sustainNote.x += 310;
							if(daNoteData > 1) //Up and Right
							{
								sustainNote.x += FlxG.width / 2 + 25;
							}
						}
					}
				}

				if (swagNote.mustPress)
				{
					swagNote.x += FlxG.width / 2; // general offset
				}
				else if(ClientPrefs.data.middleScroll)
				{
					swagNote.x += 310;
					if(daNoteData > 1) //Up and Right
					{
						swagNote.x += FlxG.width / 2 + 25;
					}
				}

				if(!noteTypes.contains(swagNote.noteType)) {
					noteTypes.push(swagNote.noteType);
				}
			}
		}
		for (event in songData.events) //Event Notes
			for (i in 0...event[1].length)
				makeEvent(event, i);

		unspawnNotes.sort(sortByTime);
		generatedMusic = true;
	}

	// called only once per different event (Used for precaching)
	function eventPushed(event:EventNote) {
		eventPushedUnique(event);
		if(eventsPushed.contains(event.event)) {
			return;
		}

		stagesFunc(function(stage:BaseStage) stage.eventPushed(event));
		eventsPushed.push(event.event);
	}

	// called by every event with the same name
	function eventPushedUnique(event:EventNote) {
		switch(event.event) {
			case "Change Character":
				var charType:Int = 0;
				switch(event.value1.toLowerCase()) {
					case 'gf' | 'girlfriend' | '1':
						charType = 2;
					case 'dad' | 'opponent' | '0':
						charType = 1;
					default:
						var val1:Int = Std.parseInt(event.value1);
						if(Math.isNaN(val1)) val1 = 0;
						charType = val1;
				}

				var newCharacter:String = event.value2;
				addCharacterToList(newCharacter, charType);
			
			case 'Play Sound':
				precacheList.set(event.value1, 'sound');
				Paths.sound(event.value1);

			case "Dadbattle Spotlight":
				dadbattleBlack = new BGSprite(null, -800, -400, 0, 0);
				dadbattleBlack.makeGraphic(Std.int(FlxG.width * 2), Std.int(FlxG.height * 2), FlxColor.BLACK);
				dadbattleBlack.alpha = 0.25;
				dadbattleBlack.visible = false;
				add(dadbattleBlack);

				dadbattleLight = new BGSprite('stages/stage/spotlight', 400, -400);
				dadbattleLight.alpha = 0.375;
				dadbattleLight.blend = ADD;
				dadbattleLight.visible = false;
				add(dadbattleLight);

				dadbattleFog = new DadBattleFog();
				dadbattleFog.visible = false;
				add(dadbattleFog);

			case "Philly Glow":
				blammedLightsBlack = new FlxSprite(FlxG.width * -0.5, FlxG.height * -0.5).makeGraphic(Std.int(FlxG.width * 2), Std.int(FlxG.height * 2), FlxColor.BLACK);
				blammedLightsBlack.visible = false;
				insert(members.indexOf(phillyGlowFG), blammedLightsBlack);

				if (curStage == 'philly')
				{
					phillyWindowEvent = new BGSprite('stages/philly/window', -10, 0, 0.3, 0.3);
					phillyWindowEvent.setGraphicSize(Std.int(phillyWindowEvent.width * 0.85));
					phillyWindowEvent.updateHitbox();
					phillyWindowEvent.visible = false;
					insert(members.indexOf(blammedLightsBlack) + 1, phillyWindowEvent);
				}


				phillyGlowGradient = new PhillyGlowGradient(-400, 225); //This crud was refusing to properly load FlxGradient so screw it
				phillyGlowGradient.visible = false;
				insert(members.indexOf(blammedLightsBlack) + 1, phillyGlowGradient);
				if(!ClientPrefs.data.flashing) phillyGlowGradient.intendedAlpha = 0.7;

				precacheList.set('stages/philly/particle', 'image'); //precache philly glow particle image
				phillyGlowParticles = new FlxTypedGroup<PhillyGlowParticle>();
				phillyGlowParticles.visible = false;
				insert(members.indexOf(phillyGlowGradient) + 1, phillyGlowParticles);
		}
		stagesFunc(function(stage:BaseStage) stage.eventPushedUnique(event));
	}

	function eventEarlyTrigger(event:EventNote):Float {
		var returnedValue:Null<Float> = callOnScripts('eventEarlyTrigger', [event.event, event.value1, event.value2, event.strumTime], true, [], [0]);
		if(returnedValue != null && returnedValue != 0 && returnedValue != FunkinLua.Function_Continue) {
			return returnedValue;
		}

		switch(event.event) {
			case 'Kill Henchmen': //Better timing so that the kill sound matches the beat intended
				return 280; //Plays 280ms before the actual position
		}
		return 0;
	}

	public static function sortByTime(Obj1:Dynamic, Obj2:Dynamic):Int
		return FlxSort.byValues(FlxSort.ASCENDING, Obj1.strumTime, Obj2.strumTime);

	function makeEvent(event:Array<Dynamic>, i:Int)
	{
		var subEvent:EventNote = {
			strumTime: event[0] + ClientPrefs.data.noteOffset,
			event: event[1][i][0],
			value1: event[1][i][1],
			value2: event[1][i][2]
		};
		eventNotes.push(subEvent);
		eventPushed(subEvent);
		callOnScripts('onEventPushed', [subEvent.event, subEvent.value1 != null ? subEvent.value1 : '', subEvent.value2 != null ? subEvent.value2 : '', subEvent.strumTime]);
	}

	public var skipArrowStartTween:Bool = false; //for lua
	private function generateStaticArrows(player:Int):Void
	{
		var strumLineX:Float = isMiddleScroll ? STRUM_X_MIDDLESCROLL : STRUM_X;
		var strumLineY:Float = ClientPrefs.data.downScroll ? (FlxG.height - 150) : 50;
		for (i in 0...4)
		{
			var targetAlpha:Float = 1;
			if (player < 1)
			{
				if(!ClientPrefs.data.opponentStrums || !opponentNoteVisible) targetAlpha = 0;
				else if(isMiddleScroll) targetAlpha = 0.35;
			}

			var babyArrow:StrumNote = new StrumNote(strumLineX, strumLineY, i, player);
			babyArrow.downScroll = ClientPrefs.data.downScroll;
			if (!isStoryMode && !skipArrowStartTween)
			{
				babyArrow.alpha = 0;
				FlxTween.tween(babyArrow, {alpha: targetAlpha}, 1, {ease: FlxEase.circOut, startDelay: 0.5 + (0.2 * i)});
			}
			else
				babyArrow.alpha = targetAlpha;

			if (player == 1)
				playerStrums.add(babyArrow);
			else
			{
				if(isMiddleScroll)
				{
					babyArrow.x += 310;
					if(i > 1) { //Up and Right
						babyArrow.x += FlxG.width / 2 + 25;
					}
				}
				opponentStrums.add(babyArrow);
			}

			strumLineNotes.add(babyArrow);
			babyArrow.postAddedToGroup();
		}
	}

	private function generateExtraArrow():Void
	{	
		var posX:Int = 0;
		var posY:Int = 0;
		if (isMiddleScroll) posX = 577;
		else posX = 897;
		if (ClientPrefs.data.downScroll) posY = FlxG.height - 150;
		else posY = 50;
		playerStrums.members[0].x -= 56;
		playerStrums.members[1].x -= 56;
		playerStrums.members[2].x += 56;
		playerStrums.members[3].x += 56;

		var targetAlpha:Float = 1;
		spacebarNote = new StrumNote(posX, posY, 4, 1, true);
		spacebarNote.downScroll = ClientPrefs.data.downScroll;
		if (!isStoryMode && !skipArrowStartTween)
		{
			spacebarNote.alpha = 0;
			FlxTween.tween(spacebarNote, {alpha: targetAlpha}, 1, {ease: FlxEase.circOut, startDelay: 0.5 + (0.2 * 1.5)});
		}
		else
			spacebarNote.alpha = targetAlpha;
		playerStrums.add(spacebarNote);
		spacebarNote.playAnim('static');
		strumLineNotes.add(spacebarNote);
	}

	override function openSubState(SubState:FlxSubState)
	{
		stagesFunc(function(stage:BaseStage) stage.openSubState(SubState));
		if (paused)
		{
			if (FlxG.sound.music != null)
			{
				FlxG.sound.music.pause();
				vocals.pause();
			}

			if (startTimer != null && !startTimer.finished) startTimer.active = false;
			if (finishTimer != null && !finishTimer.finished) finishTimer.active = false;
			if (songSpeedTween != null) songSpeedTween.active = false;
			if (blurbTimer != null && !blurbTimer.finished) blurbTimer.active = false;

			var chars:Array<Character> = [boyfriend, gf, dad];
			for (char in chars)
				if(char != null && char.colorTween != null)
					char.colorTween.active = false;

			#if LUA_ALLOWED
			for (tween in modchartTweens) tween.active = false;
			for (timer in modchartTimers) timer.active = false;
			#if VIDEOS_ALLOWED
			for (video in modchartVideos) video.bitmap.pause();
			#end
			#end
		}

		super.openSubState(SubState);
	}

	override function closeSubState()
	{
		stagesFunc(function(stage:BaseStage) stage.closeSubState());
		if (paused)
		{
			if (FlxG.sound.music != null && !startingSong)
			{
				resyncVocals();
			}

			if (startTimer != null && !startTimer.finished) startTimer.active = true;
			if (finishTimer != null && !finishTimer.finished) finishTimer.active = true;
			if (songSpeedTween != null) songSpeedTween.active = true;
			if (blurbTimer != null && !blurbTimer.finished) blurbTimer.active = true;

			var chars:Array<Character> = [boyfriend, gf, dad];
			for (char in chars)
				if(char != null && char.colorTween != null)
					char.colorTween.active = true;

			#if LUA_ALLOWED
			for (tween in modchartTweens) tween.active = true;
			for (timer in modchartTimers) timer.active = true;
			#if VIDEOS_ALLOWED
			for (video in modchartVideos) video.bitmap.resume();
			#end
			#end

			paused = false;
			callOnScripts('onResume');
			resetRPC(startTimer != null && startTimer.finished);
		}

		super.closeSubState();
	}

	override public function onFocus():Void
	{
		if (health > 0 && !paused) resetRPC(Conductor.songPosition > 0.0);
		super.onFocus();
		#if LUA_ALLOWED
		#if VIDEOS_ALLOWED
		if (paused) {
			for (video in modchartVideos) video.bitmap.pause();
		}
		#end
		#end
	}

	override public function onFocusLost():Void
	{
		#if desktop
		if (health > 0 && !paused) DiscordClient.changePresence(detailsPausedText, SONG.song + " (" + storyDifficultyText + ")", iconP2.getCharacter());
		#end
	}

	// Updating Discord Rich Presence.
	function resetRPC(?cond:Bool = false)
	{
		#if desktop
		if (cond)
			DiscordClient.changePresence(detailsText, SONG.song + " (" + storyDifficultyText + ")", iconP2.getCharacter(), true, songLength - Conductor.songPosition - ClientPrefs.data.noteOffset);
		else
			DiscordClient.changePresence(detailsText, SONG.song + " (" + storyDifficultyText + ")", iconP2.getCharacter());
		#end
	}

	function resyncVocals():Void
	{
		if(finishTimer != null) return;

		vocals.pause();

		FlxG.sound.music.play();
		FlxG.sound.music.pitch = playbackRate;
		Conductor.songPosition = FlxG.sound.music.time;
		if (Conductor.songPosition <= vocals.length)
		{
			vocals.time = Conductor.songPosition;
			vocals.pitch = playbackRate;
		}
		vocals.play();
	}

	public var paused:Bool = false;
	public var canReset:Bool = true;
	var startedCountdown:Bool = false;
	var canPause:Bool = true;

	override public function update(elapsed:Float)
	{
		callOnScripts('onUpdate', [elapsed]);
		floatTrash += 0.1;

		if(phillyGlowParticles != null)
		{
			var i:Int = phillyGlowParticles.members.length-1;
			while (i > 0)
			{
				var particle = phillyGlowParticles.members[i];
				if(particle.alpha <= 0)
				{
					particle.kill();
					phillyGlowParticles.remove(particle, true);
					particle.destroy();
				}
				--i;
			}
		}

		FlxG.camera.followLerp = 0;
		if(!inCutscene && !paused) {
			FlxG.camera.followLerp = FlxMath.bound(elapsed * 2.4 * cameraSpeed * playbackRate / (FlxG.updateFramerate / 60), 0, 1);
			if(!startingSong && !endingSong && boyfriend.animation.curAnim != null && boyfriend.animation.curAnim.name.startsWith('idle')) {
				boyfriendIdleTime += elapsed;
				if(boyfriendIdleTime >= 0.15) { // Kind of a mercy thing for making the achievement easier to get as it's apparently frustrating to some playerss
					boyfriendIdled = true;
				}
			} else {
				boyfriendIdleTime = 0;
			}
		}

		super.update(elapsed);

		setOnScripts('curDecStep', curDecStep);
		setOnScripts('curDecBeat', curDecBeat);

		if(botplaySpr.visible) {
			botplaySine += 180 * elapsed;
			botplaySpr.alpha = 1 - Math.sin((Math.PI * botplaySine) / 180);
		}

		if(practiceSpr.visible) {
			practiceSine += 180 * elapsed;
			practiceSpr.alpha = 1 - Math.sin((Math.PI * practiceSine) / 180);
		}

		if (controls.PAUSE && startedCountdown && canPause)
		{
			var ret:Dynamic = callOnScripts('onPause', null, true);
			if(ret != FunkinLua.Function_Stop) {
				openPauseMenu();
			}
		}

		if (controls.justPressed('debug_1') && !endingSong && !inCutscene)
			openChartEditor();

		if (bfFloating && !endingSong)
		{
			boyfriend.y += Math.sin(floatTrash);
		}

		if (gfFloating && !endingSong)
		{
			gf.y += Math.sin(floatTrash);
		}
	
		if (dadFloating && !endingSong)
		{
			dad.y += Math.sin(floatTrash);
		}

		var mult:Float = FlxMath.lerp(1, iconP1.scale.x, FlxMath.bound(1 - (elapsed * 9 * playbackRate), 0, 1));
		iconP1.scale.set(mult, mult);
		iconP1.updateHitbox();

		var mult:Float = FlxMath.lerp(1, iconP2.scale.x, FlxMath.bound(1 - (elapsed * 9 * playbackRate), 0, 1));
		iconP2.scale.set(mult, mult);
		iconP2.updateHitbox();

		var iconOffset:Int = 26;

		iconP1.x = healthBar.x + (healthBar.width * (FlxMath.remapToRange(healthBar.percent, 0, 100, 100, 0) * 0.01)) + (150 * iconP1.scale.x - 150) / 2 - iconOffset;
		iconP2.x = healthBar.x + (healthBar.width * (FlxMath.remapToRange(healthBar.percent, 0, 100, 100, 0) * 0.01)) - (150 * iconP2.scale.x) / 2 - iconOffset * 2;

		if (health > 2)
			health = 2;

		if (healthBar.percent < 20)
		{
			iconP1.animation.curAnim.curFrame = 1;
			iconP2.animation.curAnim.curFrame = 2;
		}
		else if (healthBar.percent >= 20 && healthBar.percent <= 80)
		{
			iconP1.animation.curAnim.curFrame = 0;
			iconP2.animation.curAnim.curFrame = 0;
		}
		else if (healthBar.percent > 80)
		{
			iconP2.animation.curAnim.curFrame = 1;
			iconP1.animation.curAnim.curFrame = 2;
		}

		if (controls.justPressed('debug_2') && !endingSong && !inCutscene)
			openCharacterEditor();
		
		if (startedCountdown && !paused)
			Conductor.songPosition += FlxG.elapsed * 1000 * playbackRate;

		if (startingSong)
		{
			if (startedCountdown && Conductor.songPosition >= 0)
				startSong();
			else if(!startedCountdown)
				Conductor.songPosition = -Conductor.crochet * 5;
		}
		else if (!paused && updateTime)
		{
			var curTime:Float = Math.max(0, Conductor.songPosition - ClientPrefs.data.noteOffset);
			songPercent = (curTime / songLength);

			var songCalc:Float = (songLength - curTime);
			if(ClientPrefs.data.timeBarType == 'Time Elapsed') songCalc = curTime;

			var secondsTotal:Int = Math.floor(songCalc / 1000);
			if(secondsTotal < 0) secondsTotal = 0;

			if(ClientPrefs.data.timeBarType != 'Song Name')
				timeTxt.text = FlxStringUtil.formatTime(secondsTotal, false);
		}

		if (camZooming)
		{
			FlxG.camera.zoom = FlxMath.lerp(defaultCamZoom, FlxG.camera.zoom, FlxMath.bound(1 - (elapsed * 3.125 * camZoomingDecay * playbackRate), 0, 1));
			if (!dsFilterOn)
				camHUD.zoom = FlxMath.lerp(1, camHUD.zoom, FlxMath.bound(1 - (elapsed * 3.125 * camZoomingDecay * playbackRate), 0, 1));
		}

		FlxG.watch.addQuick("curSec", curSection);
		FlxG.watch.addQuick("curBeat", curBeat);
		FlxG.watch.addQuick("curStep", curStep);

		// RESET = Quick Game Over Screen
		if (!ClientPrefs.data.noReset && controls.RESET && canReset && !inCutscene && startedCountdown && !endingSong)
		{
			health = 0;
			trace("RESET = True");
		}
		doDeathCheck();

		if (unspawnNotes[0] != null)
		{
			var time:Float = spawnTime * playbackRate;
			if(songSpeed < 1) time /= songSpeed;
			if(unspawnNotes[0].multSpeed < 1) time /= unspawnNotes[0].multSpeed;

			while (unspawnNotes.length > 0 && unspawnNotes[0].strumTime - Conductor.songPosition < time)
			{
				var dunceNote:Note = unspawnNotes[0];
				notes.insert(0, dunceNote);
				dunceNote.spawned = true;

				callOnLuas('onSpawnNote', [notes.members.indexOf(dunceNote), dunceNote.noteData, dunceNote.noteType, dunceNote.isSustainNote, dunceNote.strumTime]);
				callOnHScript('onSpawnNote', [dunceNote]);

				var index:Int = unspawnNotes.indexOf(dunceNote);
				unspawnNotes.splice(index, 1);
			}
		}

		if (generatedMusic)
		{
			if(!inCutscene)
			{
				if(!cpuControlled) {
					keysCheck();
				} else if(boyfriend.animation.curAnim != null && boyfriend.holdTimer > Conductor.stepCrochet * (0.0011 / FlxG.sound.music.pitch) * boyfriend.singDuration && boyfriend.animation.curAnim.name.startsWith('sing') && !boyfriend.animation.curAnim.name.endsWith('miss')) {
					boyfriend.dance();
				}

				if(notes.length > 0)
				{
					if(startedCountdown)
					{
						var fakeCrochet:Float = (60 / SONG.bpm) * 1000;
						notes.forEachAlive(function(daNote:Note)
						{
							var strumGroup:FlxTypedGroup<StrumNote> = playerStrums;
							if(!daNote.mustPress) strumGroup = opponentStrums;

							var strum:StrumNote = strumGroup.members[daNote.noteData];
							daNote.followStrumNote(strum, fakeCrochet, songSpeed / playbackRate);

							if(daNote.mustPress)
							{
								if(cpuControlled && !daNote.blockHit && daNote.canBeHit && (daNote.isSustainNote || daNote.strumTime <= Conductor.songPosition))
									goodNoteHit(daNote);
							}
							else if (daNote.wasGoodHit && !daNote.hitByOpponent && !daNote.ignoreNote)
								opponentNoteHit(daNote);

							if(daNote.isSustainNote && strum.sustainReduce) daNote.clipToStrumNote(strum);

							// Kill extremely late notes and cause misses
							if (Conductor.songPosition - daNote.strumTime > noteKillOffset)
							{
								if (daNote.mustPress && !cpuControlled &&!daNote.ignoreNote && !endingSong && (daNote.tooLate || !daNote.wasGoodHit))
									noteMiss(daNote);

								daNote.active = false;
								daNote.visible = false;

								daNote.kill();
								notes.remove(daNote, true);
								daNote.destroy();
							}
						});
					}
					else
					{
						notes.forEachAlive(function(daNote:Note)
						{
							daNote.canBeHit = false;
							daNote.wasGoodHit = false;
						});
					}
				}
			}
			checkEventNote();
		}

		#if debug
		if(!endingSong && !startingSong) {
			if (FlxG.keys.justPressed.ONE) {
				KillNotes();
				FlxG.sound.music.onComplete();
			}
			if(FlxG.keys.justPressed.TWO) { //Go 10 seconds into the future :O
				setSongTime(Conductor.songPosition + 10000);
				clearNotesBefore(Conductor.songPosition);
			}
		}
		#end

		setOnScripts('cameraX', camFollow.x);
		setOnScripts('cameraY', camFollow.y);
		setOnScripts('botPlay', cpuControlled);
		callOnScripts('onUpdatePost', [elapsed]);
	}

	function openPauseMenu()
	{
		FlxG.camera.followLerp = 0;
		persistentUpdate = false;
		persistentDraw = true;
		paused = true;

		//gitaroo is gone

		if(FlxG.sound.music != null) {
			FlxG.sound.music.pause();
			vocals.pause();
		}
		if(!cpuControlled)
		{
			for (note in playerStrums)
				if(note.animation.curAnim != null && note.animation.curAnim.name != 'static')
				{
					note.playAnim('static');
					note.resetAnim = 0;
				}
		}
		openSubState(new PauseSubState(boyfriend.getScreenPosition().x, boyfriend.getScreenPosition().y));

		#if desktop
		DiscordClient.changePresence(detailsPausedText, SONG.song + " (" + storyDifficultyText + ")", iconP2.getCharacter());
		#end
	}

	function openChartEditor()
	{
		FlxG.camera.followLerp = 0;
		persistentUpdate = false;
		paused = true;
		cancelMusicFadeTween();
		chartingMode = true;

		#if desktop
		DiscordClient.changePresence("Chart Editor", null, null, true);
		DiscordClient.resetClientID();
		#end
		
		MusicBeatState.switchState(new ChartingState());
	}

	function openCharacterEditor()
	{
		FlxG.camera.followLerp = 0;
		persistentUpdate = false;
		paused = true;
		cancelMusicFadeTween();
		#if desktop DiscordClient.resetClientID(); #end
		MusicBeatState.switchState(new CharacterEditorState(SONG.player2));
	}

	public var isDead:Bool = false; //Don't mess with this on Lua!!!
	public var isOnResults:Bool = false; //PLEASE don't mess with this on Lua!!!
	function doDeathCheck(?skipHealthCheck:Bool = false) {
		if (((skipHealthCheck && instakillOnMiss) || health <= 0) && !practiceMode && !isDead)
		{
			var ret:Dynamic = callOnScripts('onGameOver', null, true);
			if(ret != FunkinLua.Function_Stop) {
				boyfriend.stunned = true;
				deathCounter++;

				paused = true;

				vocals.stop();
				FlxG.sound.music.stop();

				persistentUpdate = false;
				persistentDraw = false;
				#if LUA_ALLOWED
				for (tween in modchartTweens) {
					tween.active = true;
				}
				for (timer in modchartTimers) {
					timer.active = true;
				}
				#end
				openSubState(new GameOverSubstate(boyfriend.getScreenPosition().x - boyfriend.positionArray[0], boyfriend.getScreenPosition().y - boyfriend.positionArray[1], camFollow.x, camFollow.y));

				#if desktop
				// Game Over doesn't get his own variable because it's only used here
				DiscordClient.changePresence("Game Over - " + detailsText, SONG.song + " (" + storyDifficultyText + ")", iconP2.getCharacter());
				#end
				isDead = true;
				return true;
			}
		}
		return false;
	}

	public function checkEventNote() {
		while(eventNotes.length > 0) {
			var leStrumTime:Float = eventNotes[0].strumTime;
			if(Conductor.songPosition < leStrumTime) {
				return;
			}

			var value1:String = '';
			if(eventNotes[0].value1 != null)
				value1 = eventNotes[0].value1;

			var value2:String = '';
			if(eventNotes[0].value2 != null)
				value2 = eventNotes[0].value2;

			triggerEvent(eventNotes[0].event, value1, value2, leStrumTime);
			eventNotes.shift();
		}
	}

	public function triggerEvent(eventName:String, value1:String, value2:String, strumTime:Float) {
		var flValue1:Null<Float> = Std.parseFloat(value1);
		var flValue2:Null<Float> = Std.parseFloat(value2);
		if(Math.isNaN(flValue1)) flValue1 = null;
		if(Math.isNaN(flValue2)) flValue2 = null;

		switch(eventName) {
			case "Dadbattle Spotlight": //Dadbattle Spotlight is now a global event that'll apply to all stages
				if(flValue1 == null) flValue1 = 0;
				var val:Int = Math.round(flValue1);

				switch(val)
				{
					case 1, 2, 3: //enable and target dad
						if(val == 1) //enable
						{
							dadbattleBlack.visible = true;
							dadbattleLight.visible = true;
							dadbattleFog.visible = true;
							defaultCamZoom += 0.12;
						}

						var who:Character = dad;
						if(val > 2) who = boyfriend;
						//2 only targets dad
						dadbattleLight.alpha = 0;
						new FlxTimer().start(0.12, function(tmr:FlxTimer) {
							dadbattleLight.alpha = 0.375;
						});
						dadbattleLight.setPosition(who.getGraphicMidpoint().x - dadbattleLight.width / 2, who.y + who.height - dadbattleLight.height + 50);
						FlxTween.tween(dadbattleFog, {alpha: 0.7}, 1.5, {ease: FlxEase.quadInOut});

					default:
						dadbattleBlack.visible = false;
						dadbattleLight.visible = false;
						defaultCamZoom -= 0.12;
						FlxTween.tween(dadbattleFog, {alpha: 0}, 0.7, {onComplete: function(twn:FlxTween) dadbattleFog.visible = false});
				}
			case "Philly Glow": // Same with Philly Glow. It applies to all stages. GET WRECKED SHADOW MARIO!!
				if(flValue1 == null || flValue1 <= 0) flValue1 = 0;
				var lightId:Int = Math.round(flValue1);

				var doFlash:Void->Void = function() {
					var color:FlxColor = FlxColor.WHITE;
					if(!ClientPrefs.data.flashing) color.alphaFloat = 0.5;

					FlxG.camera.flash(color, 0.15, null, true);
				};

				var chars:Array<Character> = [boyfriend, gf, dad];
				switch(lightId)
				{
					case 0:
						if(phillyGlowGradient.visible)
						{
							phillyGlowOn = false;
							doFlash();
							if(ClientPrefs.data.camZooms)
							{
								FlxG.camera.zoom += 0.5;
								if (!dsFilterOn)
									camHUD.zoom += 0.1;
							}

							blammedLightsBlack.visible = false;
							phillyGlowFG.visible = false;
							if (curStage == 'philly')
								phillyWindowEvent.visible = false;
							phillyGlowGradient.visible = false;
							phillyGlowParticles.visible = false;
							curLightEvent = -1;

							for (who in chars)
							{
								who.color = FlxColor.WHITE;
							}
							phillyGlowFG.color = FlxColor.WHITE;
						}

					case 1: //turn on
						curLightEvent = FlxG.random.int(0, phillyLightsColors.length-1, [curLightEvent]);
						var color:FlxColor = phillyLightsColors[curLightEvent];

						if(!phillyGlowGradient.visible)
						{
							phillyGlowOn = true;
							doFlash();
							if(ClientPrefs.data.camZooms)
							{
								FlxG.camera.zoom += 0.5;
								if (!dsFilterOn)
									camHUD.zoom += 0.1;
							}

							blammedLightsBlack.visible = true;
							blammedLightsBlack.alpha = 1;
							phillyGlowFG.visible = true;
							if (curStage == 'philly')
								phillyWindowEvent.visible = true;
							phillyGlowGradient.visible = true;
							phillyGlowParticles.visible = true;
						}
						else if(ClientPrefs.data.flashing)
						{
							var colorButLower:FlxColor = color;
							colorButLower.alphaFloat = 0.25;
							FlxG.camera.flash(colorButLower, 0.5, null, true);
						}

						var charColor:FlxColor = color;
						if(!ClientPrefs.data.flashing) charColor.saturation *= 0.5;
						else charColor.saturation *= 0.75;

						for (who in chars)
						{
							who.color = charColor;
						}
						phillyGlowParticles.forEachAlive(function(particle:PhillyGlowParticle)
						{
							particle.color = color;
						});
						phillyGlowGradient.color = color;
						if (curStage == 'philly')
							phillyWindowEvent.color = color;

						color.brightness *= 0.5;
						phillyGlowFG.color = color;

					case 2: // spawn particles
						if(!ClientPrefs.data.lowQuality)
						{
							var particlesNum:Int = FlxG.random.int(8, 12);
							var width:Float = (2000 / particlesNum);
							var color:FlxColor = phillyLightsColors[curLightEvent];
							for (j in 0...3)
							{
								for (i in 0...particlesNum)
								{
									var particle:PhillyGlowParticle = new PhillyGlowParticle(-400 + width * i + FlxG.random.float(-width / 5, width / 5), phillyGlowGradient.originalY + 200 + (FlxG.random.float(0, 125) + j * 40), color);
									phillyGlowParticles.add(particle);
								}
							}
						}
						phillyGlowGradient.bop();
				}
			case 'Hey!':
				var value:Int = 2;
				switch(value1.toLowerCase().trim()) {
					case 'bf' | 'boyfriend' | '0':
						value = 0;
					case 'gf' | 'girlfriend' | '1':
						value = 1;
				}

				if(flValue2 == null || flValue2 <= 0) flValue2 = 0.6;

				if(value != 0) {
					if(dad.curCharacter.startsWith('gf') || dad.curCharacter.endsWith('speakers') || dad.curCharacter.endsWith('tutorial')) { //Tutorial GF is actually Dad! The GF is an imposter!! AmongusAmongusAmongusAmongus
						dad.playAnim('cheer', true);
						dad.specialAnim = true;
						dad.heyTimer = flValue2;
					} else if (gf != null) {
						gf.playAnim('cheer', true);
						gf.specialAnim = true;
						gf.heyTimer = flValue2;
					}
				}
				if(value != 1) {
					boyfriend.playAnim('hey', true);
					boyfriend.specialAnim = true;
					boyfriend.heyTimer = flValue2;
				}

			case 'Set GF Speed':
				if(flValue1 == null || flValue1 < 1) flValue1 = 1;
				gfSpeed = Math.round(flValue1);

			case 'Add Camera Zoom':
				if(ClientPrefs.data.camZooms && FlxG.camera.zoom < 1.35) {
					if(flValue1 == null) flValue1 = 0.015;
					if(flValue2 == null) flValue2 = 0.03;

					FlxG.camera.zoom += flValue1;
					if (!dsFilterOn)
						camHUD.zoom += flValue2;
				}

			case 'Play Animation':
				var char:Character = dad;
				switch(value2.toLowerCase().trim()) {
					case 'bf' | 'boyfriend':
						char = boyfriend;
					case 'gf' | 'girlfriend':
						char = gf;
					default:
						if(flValue2 == null) flValue2 = 0;
						switch(Math.round(flValue2)) {
							case 1: char = boyfriend;
							case 2: char = gf;
						}
				}

				if (char != null)
				{
					char.playAnim(value1, true);
					char.specialAnim = true;
				}

			case 'Camera Follow Pos':
				if(camFollow != null)
				{
					isCameraOnForcedPos = false;
					if(flValue1 != null || flValue2 != null)
					{
						isCameraOnForcedPos = true;
						if(flValue1 == null) flValue1 = 0;
						if(flValue2 == null) flValue2 = 0;
						camFollow.x = flValue1;
						camFollow.y = flValue2;
					}
				}

			case 'Alt Idle Animation':
				var char:Character = dad;
				switch(value1.toLowerCase().trim()) {
					case 'gf' | 'girlfriend':
						char = gf;
					case 'boyfriend' | 'bf':
						char = boyfriend;
					default:
						var val:Int = Std.parseInt(value1);
						if(Math.isNaN(val)) val = 0;

						switch(val) {
							case 1: char = boyfriend;
							case 2: char = gf;
						}
				}

				if (char != null)
				{
					char.idleSuffix = value2;
					char.recalculateDanceIdle();
				}

			case 'Screen Shake':
				var valuesArray:Array<String> = [value1, value2];
				var targetsArray:Array<FlxCamera> = [camGame, camHUD];
				for (i in 0...targetsArray.length) {
					var split:Array<String> = valuesArray[i].split(',');
					var duration:Float = 0;
					var intensity:Float = 0;
					if(split[0] != null) duration = Std.parseFloat(split[0].trim());
					if(split[1] != null) intensity = Std.parseFloat(split[1].trim());
					if(Math.isNaN(duration)) duration = 0;
					if(Math.isNaN(intensity)) intensity = 0;

					if(duration > 0 && intensity != 0) {
						targetsArray[i].shake(intensity, duration);
					}
				}


			case 'Change Character':
				var charType:Int = 0;
				switch(value1.toLowerCase().trim()) {
					case 'gf' | 'girlfriend':
						charType = 2;
					case 'dad' | 'opponent':
						charType = 1;
					default:
						charType = Std.parseInt(value1);
						if(Math.isNaN(charType)) charType = 0;
				}

				switch(charType) {
					case 0:
						if(boyfriend.curCharacter != value2) {
							if(!boyfriendMap.exists(value2)) {
								addCharacterToList(value2, charType);
							}

							var lastAlpha:Float = boyfriend.alpha;
							boyfriend.alpha = 0.00001;
							boyfriend = boyfriendMap.get(value2);
							boyfriend.alpha = lastAlpha;
							iconP1.changeIcon(boyfriend.healthIcon);
						}
						setOnScripts('boyfriendName', boyfriend.curCharacter);

					case 1:
						if(dad.curCharacter != value2) {
							if(!dadMap.exists(value2)) {
								addCharacterToList(value2, charType);
							}

							var wasGf:Bool = dad.curCharacter.startsWith('gf-') || dad.curCharacter == 'gf' || dad.curCharacter.endsWith('speakers') || dad.curCharacter.endsWith('tutorial');
							var lastAlpha:Float = dad.alpha;
							dad.alpha = 0.00001;
							dad = dadMap.get(value2);
							if(!dad.curCharacter.startsWith('gf-') && dad.curCharacter != 'gf' && !dad.curCharacter.endsWith('speakers') || !dad.curCharacter.endsWith('tutorial')) {
								if(wasGf && gf != null) {
									gf.visible = true;
								}
							} else if(gf != null) {
								gf.visible = false;
							}
							dad.alpha = lastAlpha;
							iconP2.changeIcon(dad.healthIcon);
						}
						setOnScripts('dadName', dad.curCharacter);

					case 2:
						if(gf != null)
						{
							if(gf.curCharacter != value2)
							{
								if(!gfMap.exists(value2)) {
									addCharacterToList(value2, charType);
								}

								var lastAlpha:Float = gf.alpha;
								gf.alpha = 0.00001;
								gf = gfMap.get(value2);
								gf.alpha = lastAlpha;
							}
							setOnScripts('gfName', gf.curCharacter);
						}
				}
				reloadHealthBarColors();

			case 'Change Scroll Speed':
				if (songSpeedType != "constant")
				{
					if(flValue1 == null) flValue1 = 1;
					if(flValue2 == null) flValue2 = 0;

					var newValue:Float = SONG.speed * ClientPrefs.getGameplaySetting('scrollspeed') * flValue1;
					if(flValue2 <= 0)
						songSpeed = newValue;
					else
						songSpeedTween = FlxTween.tween(this, {songSpeed: newValue}, flValue2 / playbackRate, {ease: FlxEase.linear, onComplete:
							function (twn:FlxTween)
							{
								songSpeedTween = null;
							}
						});
				}

			case 'Set Property':
				try
				{
					var split:Array<String> = value1.split('.');
					if(split.length > 1) {
						LuaUtils.setVarInArray(LuaUtils.getPropertyLoop(split), split[split.length-1], value2);
					} else {
						LuaUtils.setVarInArray(this, value1, value2);
					}
				}
				catch(e:Dynamic)
				{
					addTextToDebug('ERROR ("Set Property" Event) - ' + e.message.substr(0, e.message.indexOf('\n')), FlxColor.RED);
				}
			
			case 'Play Sound':
				if(flValue2 == null) flValue2 = 1;
				FlxG.sound.play(Paths.sound(value1), flValue2);

			case 'Warning':
				warningSign.visible = true;
				warningSign.animation.play('alert');
				FlxG.sound.play(Paths.sound('Warning'), 1);

			case 'Dodge Event':
				if(flValue1 == null || flValue1 >= 1) flValue1 = 0.17;
				if(flValue2 == null || flValue2 >= 2) flValue2 = 2;
				warningSign.visible = false;
				if (cpuControlled)
				{
					boyfriend.playAnim('dodge');
					bfDodging = true;
					new FlxTimer().start(0.425, function(tmr:FlxTimer)
					{
						bfDodging=false;
						boyfriend.dance();
					});
				}
				new FlxTimer().start(flValue1, function(tmr:FlxTimer)
				{
					if(!bfDodging && !ClientPrefs.getGameplaySetting('practice', false) && !cpuControlled)
					{
						boyfriend.playAnim('hurt');
						health -= flValue2;
					}
				});

			case 'Lyric Text Event':
				var val2:FlxColor = 0xFFFFFFFF;
				if (value2 != '' && value2 != null)
					val2 = FlxColor.fromString(value2);
				lyricText.text = value1;
				lyricText.color = val2;

			case 'Change Note Skin':
				var val1:String = value1;
				var val2:String = value2;

				if (val1 == null || val1 == "")
				{
					if (PlayState.SONG.arrowSkin != null && PlayState.SONG.arrowSkin != '')
						val1 = PlayState.SONG.arrowSkin;
					else
						val1 = ClientPrefs.data.noteSkin;
				}
				noteTexture = val1;

				var strumGroup:FlxTypedGroup<StrumNote> = playerStrums;
				switch (val2.toLowerCase())
				{
					case 'dad':
						strumGroup = opponentStrums;
					case 'bf':
						strumGroup = playerStrums;
					default:
						strumGroup = strumLineNotes;
				}

				for (strum in strumGroup)
				{
					strum.texture = 'noteSkins/' + val1;
					strum.reloadNote();
				}

				if(generatedMusic)
				{
					for (note in notes)
					{
						switch (val2.toLowerCase())
						{
							case 'dad':
								if (!note.mustPress)
								{
									note.texture = val1;
									note.reloadNote(val1);
								}
							case 'bf':
								if (note.mustPress)
								{
									note.texture = val1;
									note.reloadNote(val1);
								}
							default:
								note.texture = val1;
								note.reloadNote(val1);	
						}
					}
					for (note in unspawnNotes)
					{
						switch (val2.toLowerCase())
						{
							case 'dad':
								if (!note.mustPress)
								{
									note.texture = val1;
									note.reloadNote(val1);
								}
							case 'bf':
								if (note.mustPress)
								{
									note.texture = val1;
									note.reloadNote(val1);
								}
							default:
								note.texture = val1;
								note.reloadNote(val1);	
						}
					}
				}

			case 'Change Splash Skin':
				var val1:String = value1;
				if (val1 == null || val1 == '') 
				{
					if (PlayState.SONG.splashSkin != null && PlayState.SONG.splashSkin != '')
						val1 = PlayState.SONG.splashSkin;
					else
						val1 = ClientPrefs.data.splashSkin;
				}
				splashTexture = val1;

			case 'Camera Zoom':
				if(camZooming)
				{
					if(flValue1 != null && flValue1 > 0)
					{
						if (dsFilterOn) defaultCamZoom = flValue1 - 0.42;
						else defaultCamZoom = flValue1;
					}
					else
					{
						if (dsFilterOn) defaultCamZoom = stageZoomVal - 0.42;
						else defaultCamZoom = stageZoomVal;
					}
				}
		}
		
		stagesFunc(function(stage:BaseStage) stage.eventCalled(eventName, value1, value2, flValue1, flValue2, strumTime));
		callOnScripts('onEvent', [eventName, value1, value2, strumTime]);
	}

	function moveCameraSection(?sec:Null<Int>):Void {
		if(sec == null) sec = curSection;
		if(sec < 0) sec = 0;

		if(SONG.notes[sec] == null) return;

		if (gf != null && SONG.notes[sec].gfSection)
		{
			camFollow.setPosition(gf.getMidpoint().x, gf.getMidpoint().y);
			camFollow.x += gf.cameraPosition[0] + girlfriendCameraOffset[0];
			camFollow.y += gf.cameraPosition[1] + girlfriendCameraOffset[1];
			tweenCamIn();
			callOnScripts('onMoveCamera', ['gf']);
			return;
		}

		var isDad:Bool = (SONG.notes[sec].mustHitSection != true);
		moveCamera(isDad);
		callOnScripts('onMoveCamera', [isDad ? 'dad' : 'boyfriend']);
	}

	var cameraTwn:FlxTween;
	public function moveCamera(isDad:Bool)
	{
		if(isDad)
		{
			camFollow.setPosition(dad.getMidpoint().x + 150, dad.getMidpoint().y - 100);
			camFollow.x += dad.cameraPosition[0] + opponentCameraOffset[0];
			camFollow.y += dad.cameraPosition[1] + opponentCameraOffset[1];
			tweenCamIn();
		}
		else
		{
			camFollow.setPosition(boyfriend.getMidpoint().x - 100, boyfriend.getMidpoint().y - 100);
			camFollow.x -= boyfriend.cameraPosition[0] - boyfriendCameraOffset[0];
			camFollow.y += boyfriend.cameraPosition[1] + boyfriendCameraOffset[1];

			if (!dsFilterOn)
			{
				if (Paths.formatToSongPath(SONG.song) == 'tutorial' && cameraTwn == null && FlxG.camera.zoom != 1)
				{
					cameraTwn = FlxTween.tween(FlxG.camera, {zoom: 1}, (Conductor.stepCrochet * 4 / 1000), {ease: FlxEase.elasticInOut, onComplete:
						function (twn:FlxTween)
						{
							cameraTwn = null;
						}
					});
				}
			}
		}
	}

	public function tweenCamIn() {
		if (!dsFilterOn)
		{
			if (Paths.formatToSongPath(SONG.song) == 'tutorial' && cameraTwn == null && FlxG.camera.zoom != 1.3) {
				cameraTwn = FlxTween.tween(FlxG.camera, {zoom: 1.3}, (Conductor.stepCrochet * 4 / 1000), {ease: FlxEase.elasticInOut, onComplete:
					function (twn:FlxTween) {
						cameraTwn = null;
					}
				});
			}
		}
	}

	public function finishSong(?ignoreNoteOffset:Bool = false):Void
	{
		if (!endingSong)
		{
			updateTime = false;
			endingSong = true;
			camZooming = false;
			FlxG.sound.music.volume = 0;
			vocals.volume = 0;
			vocals.pause();
			canPause = false;
			if(ClientPrefs.data.noteOffset <= 0 || ignoreNoteOffset) {
				endCallback();
			} else {
				finishTimer = new FlxTimer().start(ClientPrefs.data.noteOffset / 1000, function(tmr:FlxTimer) {
					endCallback();
				});
			}
		}
	}


	public var transitioning = false;
	public function endSong()
	{
		songAccuracy = CoolUtil.floorDecimal(ratingPercent * 100, 2);
		//Should kill you if you tried to cheat
		if(!startingSong) {
			notes.forEach(function(daNote:Note) {
				if(daNote.strumTime < songLength - Conductor.safeZoneOffset) {
					health -= 0.05 * healthLoss;
				}
			});
			for (daNote in unspawnNotes) {
				if(daNote.strumTime < songLength - Conductor.safeZoneOffset) {
					health -= 0.05 * healthLoss;
				}
			}

			if(doDeathCheck()) {
				return false;
			}
		}

		timeBar.visible = false;
		timeTxt.visible = false;
		canPause = false;
		endingSong = true;
		camZooming = false;
		inCutscene = false;
		updateTime = false;

		seenCutscene = false;

		#if ACHIEVEMENTS_ALLOWED
		var weekNoMiss:String = WeekData.getWeekFileName() + '_nomiss';
		checkForAchievement([weekNoMiss, 'ur_bad', 'ur_good', 'hype', 'two_keys', 'toastie', 'debugger', 'showoff', 'pizza_clear']);
		#end

		var ret:Dynamic = callOnScripts('onEndSong', null, true);
		if(ret != FunkinLua.Function_Stop && !transitioning)
		{
			#if !switch
			var percent:Float = ratingPercent;
			if(Math.isNaN(percent)) percent = 0;
			Highscore.saveScore(SONG.song, songScore, storyDifficulty, percent);
			#end
			playbackRate = 1;

			if (chartingMode)
			{
				openChartEditor();
				return false;
			}

			if (isStoryMode)
			{
				deathCounter = 0;
				campaignScore += songScore;
				campaignMisses += songMisses;

				storyPlaylist.remove(storyPlaylist[0]);

				if (extraSong != '' && storyPlaylist.length <= 0)
				{
					storyPlaylist[0] = extraSong;
				}

				if (storyPlaylist.length <= 0)
				{
					// Doing this crud for the Bowser Jr & Monika game clear achievements (Made it so it'll only detect the base game weeks)
					var baseWeeks:Array<String> = ['tutorial', 'week1', 'week2', 'week3', 'week4', 'week5', 'week6', 'week7', 'weeksecret'];
					for (i in baseWeeks) {
						if (i == WeekData.getWeekFileName()) {
							if (ClientPrefs.data.playerChar == 2) {
								if (!jrWeeksCleared.exists(i)) {
									jrWeeksCleared.set(i, true);
									FlxG.save.data.jrWeeksCleared = jrWeeksCleared;
									#if ACHIEVEMENTS_ALLOWED
									Achievements.addScore("jr_gameclear");
									#end
									FlxG.save.flush();
								}
							}
							if (ClientPrefs.data.playerChar == 3) {
								if (!moniWeeksCleared.exists(i)) {
									moniWeeksCleared.set(i, true);
									FlxG.save.data.moniWeeksCleared = moniWeeksCleared;
									#if ACHIEVEMENTS_ALLOWED
									Achievements.addScore("moni_gameclear");
									#end
									FlxG.save.flush();
								}
							}
						}
					}

					Mods.loadTopMod();
					FlxG.sound.playMusic(Paths.music('freakyMenu'));
					#if desktop DiscordClient.resetClientID(); #end

					cancelMusicFadeTween();
					if(FlxTransitionableState.skipNextTransIn) {
						CustomFadeTransition.nextCamera = null;
					}
					MusicBeatState.switchState(new StoryMenuState());

					// if ()
					if(!ClientPrefs.getGameplaySetting('practice') && !ClientPrefs.getGameplaySetting('botplay')) {
						if (unlockNextWeek == true) {
							StoryMenuState.weekCompleted.set(customUnlock, true);
						}
						Highscore.saveWeekScore(WeekData.getWeekFileName(), campaignScore, storyDifficulty);
						if (unlockNextWeek == true) {
							FlxG.save.data.weekCompleted = StoryMenuState.weekCompleted;
						}
						FlxG.save.flush();
					}
					changedDifficulty = false;
				}
				else
				{
					var difficulty:String = Difficulty.getFilePath();

					trace('LOADING NEXT SONG');
					trace(Paths.formatToSongPath(PlayState.storyPlaylist[0]) + difficulty);

					FlxTransitionableState.skipNextTransIn = true;
					FlxTransitionableState.skipNextTransOut = true;
					prevCamFollow = camFollow;

					PlayState.SONG = Song.loadFromJson(PlayState.storyPlaylist[0] + difficulty, PlayState.storyPlaylist[0]);
					FlxG.sound.music.stop();

					cancelMusicFadeTween();
					LoadingState.loadAndSwitchState(new PlayState());
				}
			}
			else
			{
				trace('WENT BACK TO FREEPLAY??');
				Mods.loadTopMod();
				#if desktop DiscordClient.resetClientID(); #end

				cancelMusicFadeTween();
				if(FlxTransitionableState.skipNextTransIn) {
					CustomFadeTransition.nextCamera = null;
				}
				if (unlockNextWeek == true)
				{
					if (!ClientPrefs.getGameplaySetting('botplay', false) && !ClientPrefs.getGameplaySetting('practice', false))
					{
						StoryMenuState.weekCompleted.set(customUnlock, true);
						FlxG.save.data.weekCompleted = StoryMenuState.weekCompleted;
						FlxG.save.flush();
					}
				}
	
				if (!ClientPrefs.data.freeplayCutscenes)
					resultsShow = true;
	
				if (resultsShow)
				{
					if (ClientPrefs.data.resultsScreen && !ClientPrefs.getGameplaySetting('botplay', false) && !ClientPrefs.getGameplaySetting('practice', false) && !isOnResults)
					{
						isOnResults = true;
						openSubState(new ResultsScreen());
					}
					else
					{
						deathCounter = 0;
						MusicBeatState.switchState(new FreeplayState());
						FlxG.sound.playMusic(Paths.music('freakyMenu'));
					}
				}
				changedDifficulty = false;
			}
			transitioning = true;
		}
		return true;
	}

	public function KillNotes() {
		while(notes.length > 0) {
			var daNote:Note = notes.members[0];
			daNote.active = false;
			daNote.visible = false;

			daNote.kill();
			notes.remove(daNote, true);
			daNote.destroy();
		}
		unspawnNotes = [];
		eventNotes = [];
	}

	public var totalPlayed:Int = 0;
	public var totalNotesHit:Float = 0.0;

	public var showCombo:Bool = true;
	public var showComboNum:Bool = true;
	public var showRating:Bool = true;

	// stores the last judgement object
	var lastRating:FlxSprite;
	// stores the last combo sprite object
	var lastCombo:FlxSprite;
	// stores the last combo score objects in an array
	var lastScore:Array<FlxSprite> = [];

	private function cachePopUpScore()
	{
		var uiPrefix:String = '';
		var uiSuffix:String = '';
		
		uiPrefix = 'hudFolders/${stageUI}UI/';
		if (PlayState.isPixelStage){
			uiPrefix = 'pixelUI/hudFolders/${stageUI}UI/';
			uiSuffix = '-pixel';
		}

		for (rating in ratingsData)
			Paths.image(uiPrefix + rating.image + uiSuffix);
		for (i in 0...10)
			Paths.image(uiPrefix + 'num' + i + uiSuffix);
	}

	private function popUpScore(note:Note = null):Void
	{
		var noteDiff:Float = Math.abs(note.strumTime - Conductor.songPosition + ClientPrefs.data.ratingOffset);
		vocals.volume = 1;

		var placement:Float =  FlxG.width * 0.35;
		var rating:FlxSprite = new FlxSprite();
		var score:Int = 350;

		//tryna do MS based judgment due to popular demand
		var daRating:Rating = Conductor.judgeNote(ratingsData, noteDiff / playbackRate);

		if (!note.comboDisabled) totalNotesHit += daRating.ratingMod;
		note.ratingMod = daRating.ratingMod;
		if(!note.ratingDisabled && !note.comboDisabled) daRating.hits++;
		note.rating = daRating.name;
		score = daRating.score;

		if (note.noteType == 'Extra Note') score = note.fifthNoteJSON.hitScore;

		if(daRating.noteSplash && !note.noteSplashData.disabled)
			spawnNoteSplashOnNote(note);

		if(!practiceMode && !cpuControlled) {
			songScore += score;
			if(!note.ratingDisabled && !note.comboDisabled)
			{
				songHits++;
				totalPlayed++;
				RecalculateRating(false);
			}
		}

		if (!note.comboDisabled)
		{
			var uiPrefix:String = "";
			var uiSuffix:String = '';
			var antialias:Bool = ClientPrefs.data.antialiasing;

				uiPrefix = 'hudFolders/${stageUI}UI/';
				if (PlayState.isPixelStage) {
					uiPrefix = 'pixelUI/hudFolders/${stageUI}UI/';
					uiSuffix = '-pixel';
				}
				antialias = !isPixelStage;

			rating.loadGraphic(Paths.image(uiPrefix + daRating.image + uiSuffix));
			rating.cameras = [camHUD];
			rating.screenCenter();
			rating.x = placement - 40;
			rating.y -= 60;
			rating.visible = (!ClientPrefs.data.hideHud && showRating);
			rating.x += ClientPrefs.data.comboOffset[0];
			rating.y -= ClientPrefs.data.comboOffset[1];
			rating.antialiasing = antialias;

			var comboSpr:FlxSprite = new FlxSprite().loadGraphic(Paths.image(uiPrefix + 'combo' + uiSuffix));
			comboSpr.cameras = [camHUD];
			comboSpr.screenCenter();
			comboSpr.x = placement;
			comboSpr.visible = (!ClientPrefs.data.hideHud && showCombo);
			comboSpr.antialiasing = antialias;
			comboSpr.y += 60;

			insert(members.indexOf(strumLineNotes), rating);
		
			if (!ClientPrefs.data.comboStacking)
			{
				if (lastRating != null) lastRating.kill();
				lastRating = rating;
			}

			if (!PlayState.isPixelStage)
			{
				rating.setGraphicSize(Std.int(rating.width * 0.7));
				comboSpr.setGraphicSize(Std.int(comboSpr.width * 0.5));
			}
			else
			{
				if (stageUI == 'Pizza Tower' || stageUI == 'Mario')
				{
					rating.setGraphicSize(Std.int(rating.width * daPixelZoom * 0.35));
					comboSpr.setGraphicSize(Std.int(comboSpr.width * daPixelZoom * 0.25));
				}
				else
				{
					rating.setGraphicSize(Std.int(rating.width * daPixelZoom * 0.85));
					comboSpr.setGraphicSize(Std.int(comboSpr.width * daPixelZoom * 0.65));
				}
			}

			comboSpr.updateHitbox();
			rating.updateHitbox();

			var seperatedScore:Array<Int> = [];

			if(combo >= 1000) {
				seperatedScore.push(Math.floor(combo / 1000) % 10);
			}
			seperatedScore.push(Math.floor(combo / 100) % 10);
			seperatedScore.push(Math.floor(combo / 10) % 10);
			seperatedScore.push(combo % 10);

			if (combo > highestCombo)
				highestCombo = combo;

			var daLoop:Int = 0;
			var xThing:Float = 0;
			var yThing:Float = 0;
			if (showCombo)
			{
				insert(members.indexOf(strumLineNotes), comboSpr);
			}
			if (!ClientPrefs.data.comboStacking)
			{
				if (lastCombo != null) lastCombo.kill();
				lastCombo = comboSpr;
			}
			if (lastScore != null)
			{
				while (lastScore.length > 0)
				{
					lastScore[0].kill();
					lastScore.remove(lastScore[0]);
				}
			}
			for (i in seperatedScore)
			{
				var numScore:FlxSprite = new FlxSprite().loadGraphic(Paths.image(uiPrefix + 'num' + Std.int(i) + uiSuffix));
				numScore.cameras = [camHUD];
				numScore.screenCenter();
				numScore.x = placement + (43 * daLoop) - 90 + ClientPrefs.data.comboOffset[2];
				numScore.y += 80 - ClientPrefs.data.comboOffset[3];
			
				if (!ClientPrefs.data.comboStacking)
					lastScore.push(numScore);

				if (!PlayState.isPixelStage) numScore.setGraphicSize(Std.int(numScore.width * 0.5));
				else {
					if (stageUI == 'Pizza Tower' || stageUI == 'Mario')
						numScore.setGraphicSize(Std.int(numScore.width * 1.5));
					else
						numScore.setGraphicSize(Std.int(numScore.width * daPixelZoom));
				}
				numScore.updateHitbox();

				numScore.visible = !ClientPrefs.data.hideHud;
				numScore.antialiasing = antialias;

				if(showComboNum)
					insert(members.indexOf(strumLineNotes), numScore);

				FlxTween.tween(numScore, {alpha: 0}, 0.2 / playbackRate, {
					onComplete: function(tween:FlxTween)
					{
						numScore.destroy();
					},
					startDelay: Conductor.crochet * 0.001 / playbackRate
				});

				daLoop++;
				xThing = numScore.x;
				yThing = numScore.y;

				numScore.scale.x *= 1.2;
				numScore.scale.y *= 1.2;
				FlxTween.tween(numScore.scale, {x: numScore.scale.x / 1.2, y: numScore.scale.y / 1.2}, 0.2, {
					onComplete: function(twn:FlxTween) {
					}
				});
			}
			comboSpr.x = xThing + 50;
			comboSpr.y = yThing - 11;

			rating.scale.x *= 1.2;
			rating.scale.y *= 1.2;
			FlxTween.tween(rating.scale, {x: rating.scale.x / 1.2, y: rating.scale.y / 1.2}, 0.2, {
				onComplete: function(twn:FlxTween) {
				}
			});
			comboSpr.scale.x *= 1.2;
			comboSpr.scale.y *= 1.2;
			FlxTween.tween(comboSpr.scale, {x: comboSpr.scale.x / 1.2, y: comboSpr.scale.y / 1.2}, 0.2, {
				onComplete: function(twn:FlxTween) {
				}
			});

			FlxTween.tween(rating, {alpha: 0}, 0.2 / playbackRate, {
				startDelay: Conductor.crochet * 0.001 / playbackRate
			});

			FlxTween.tween(comboSpr, {alpha: 0}, 0.2 / playbackRate, {
				onComplete: function(tween:FlxTween)
				{
					comboSpr.destroy();
					rating.destroy();
				},
				startDelay: Conductor.crochet * 0.001 / playbackRate
			});
		}
	}

	public var strumsBlocked:Array<Bool> = [];
	private function onKeyPress(event:KeyboardEvent):Void
	{
		var eventKey:FlxKey = event.keyCode;
		var key:Int = getKeyFromEvent(keysArray, eventKey);
		if (!controls.controllerMode && FlxG.keys.checkStatus(eventKey, JUST_PRESSED)) keyPressed(key);
	}

	private function keyPressed(key:Int)
	{
		if (!cpuControlled && startedCountdown && !paused && key > -1)
		{
			if(notes.length > 0 && !boyfriend.stunned && generatedMusic && !endingSong)
			{
				//more accurate hit time for the ratings?
				var lastTime:Float = Conductor.songPosition;
				if(Conductor.songPosition >= 0) Conductor.songPosition = FlxG.sound.music.time;

				var canMiss:Bool = !ClientPrefs.data.ghostTapping;

				// heavily based on my own code LOL if it aint broke dont fix it
				var pressNotes:Array<Note> = [];
				var notesStopped:Bool = false;
				var sortedNotesList:Array<Note> = [];
				notes.forEachAlive(function(daNote:Note)
				{
					if (strumsBlocked[daNote.noteData] != true && daNote.canBeHit && daNote.mustPress &&
						!daNote.tooLate && !daNote.wasGoodHit && !daNote.isSustainNote && !daNote.blockHit)
					{
						if(daNote.noteData == key) sortedNotesList.push(daNote);
						canMiss = true;
					}
				});
				sortedNotesList.sort(sortHitNotes);

				if (sortedNotesList.length > 0) {
					for (epicNote in sortedNotesList)
					{
						for (doubleNote in pressNotes) {
							if (Math.abs(doubleNote.strumTime - epicNote.strumTime) < 1) {
								doubleNote.kill();
								notes.remove(doubleNote, true);
								doubleNote.destroy();
							} else
								notesStopped = true;
						}

						// eee dum detection before was not super good
						if (!notesStopped) {
							goodNoteHit(epicNote);
							pressNotes.push(epicNote);
						}

					}
				}
				else {
					callOnScripts('onGhostTap', [key]);
					if (canMiss && !boyfriend.stunned) noteMissPress(key);
				}

				// I think this is for the "Just The Two Of Us" Achievement
				if(!keysPressed.contains(key)) keysPressed.push(key);

				//more accurate hit time for the ratings? part 2 (Now that the calculations are done, go back to the time it was before for not causing a note stutter)
				Conductor.songPosition = lastTime;
			}

			var spr:StrumNote = playerStrums.members[key];
			if(strumsBlocked[key] != true && spr != null && spr.animation.curAnim.name != 'confirm')
			{
				spr.playAnim('pressed');
				spr.resetAnim = 0;
			}
			callOnScripts('onKeyPress', [key]);
		}
	}

	public static function sortHitNotes(a:Note, b:Note):Int
	{
		if (a.lowPriority && !b.lowPriority)
			return 1;
		else if (!a.lowPriority && b.lowPriority)
			return -1;

		return FlxSort.byValues(FlxSort.ASCENDING, a.strumTime, b.strumTime);
	}

	private function onKeyRelease(event:KeyboardEvent):Void
	{
		var eventKey:FlxKey = event.keyCode;
		var key:Int = getKeyFromEvent(keysArray, eventKey);

		if(!controls.controllerMode && key > -1) keyReleased(key);
	}

	private function keyReleased(key:Int)
	{
		if(!cpuControlled && startedCountdown && !paused)
		{
			var spr:StrumNote = playerStrums.members[key];
			if(spr != null)
			{
				spr.playAnim('static');
				spr.resetAnim = 0;
			}
			callOnScripts('onKeyRelease', [key]);
		}
	}

	public static function getKeyFromEvent(arr:Array<String>, key:FlxKey):Int
	{
		if(key != NONE)
		{
			for (i in 0...arr.length)
			{
				var note:Array<FlxKey> = Controls.instance.keyboardBinds[arr[i]];
				for (noteKey in note)
					if(key == noteKey)
						return i;
			}
		}
		return -1;
	}

	// Hold notes
	private function keysCheck():Void
	{
		var hitFifthNote:Bool = false;
		if (controls.justPressed('note_extra') && !bfDodging && bfCanDodge)
		{
			bfDodging = true;
			bfCanDodge = false;
			dodgeCount++;
			boyfriend.playAnim('dodge');
		
			//Wait, then set bfDodging back to false.
			new FlxTimer().start(bfDodgeTiming, function(tmr:FlxTimer)
			{
				bfDodging=false;
				boyfriend.dance();
				//Cooldown timer so you can't keep spamming it.
				new FlxTimer().start(bfDodgeCooldown, function(tmr:FlxTimer)
				{
					bfCanDodge=true;
				});
			});
		}

		// HOLDING
		var holdArray:Array<Bool> = [];
		var pressArray:Array<Bool> = [];
		var releaseArray:Array<Bool> = [];
		for (key in keysArray)
		{
			holdArray.push(controls.pressed(key));
			pressArray.push(controls.justPressed(key));
			releaseArray.push(controls.justReleased(key));
		}

		// TO DO: Find a better way to handle controller inputs, this should work for now
		if (controls.controllerMode && pressArray.contains(true))
			for (i in 0...pressArray.length)
				if(pressArray[i] && strumsBlocked[i] != true)
					keyPressed(i);

		if (startedCountdown && !boyfriend.stunned && generatedMusic)
		{
			// rewritten inputs???
			if(notes.length > 0)
			{
				notes.forEachAlive(function(daNote:Note)
				{
					// hold note functions
					if (strumsBlocked[daNote.noteData] != true && daNote.isSustainNote && holdArray[daNote.noteData] && daNote.canBeHit
					&& daNote.mustPress && !daNote.tooLate && !daNote.wasGoodHit && !daNote.blockHit) {
						goodNoteHit(daNote);
					}
				});
			}

			if (holdArray.contains(true) && !endingSong) {
				#if ACHIEVEMENTS_ALLOWED
				checkForAchievement(['oversinging']);
				#end
			}
			else if (boyfriend.animation.curAnim != null && boyfriend.holdTimer > Conductor.stepCrochet * (0.0011 / FlxG.sound.music.pitch) * boyfriend.singDuration && boyfriend.animation.curAnim.name.startsWith('sing') && !boyfriend.animation.curAnim.name.endsWith('miss') && !bfDodging)
			{
				boyfriend.dance();
			}
		}

		// TO DO: Find a better way to handle controller inputs, this should work for now
		if((controls.controllerMode || strumsBlocked.contains(true)) && releaseArray.contains(true))
			for (i in 0...releaseArray.length)
				if(releaseArray[i] || strumsBlocked[i] == true)
					keyReleased(i);
	}

	function noteMiss(daNote:Note):Void { //You didn't hit the key and let it go offscreen, also used by Hurt Notes
		//Dupe note remove
		notes.forEachAlive(function(note:Note) {
			if (daNote != note && daNote.mustPress && daNote.noteData == note.noteData && daNote.isSustainNote == note.isSustainNote && Math.abs(daNote.strumTime - note.strumTime) < 1) {
				note.kill();
				notes.remove(note, true);
				note.destroy();
			}
		});
		
		noteMissCommon(daNote.noteData, daNote);
		var result:Dynamic = callOnLuas('noteMiss', [notes.members.indexOf(daNote), daNote.noteData, daNote.noteType, daNote.isSustainNote]);
		if(result != FunkinLua.Function_Stop && result != FunkinLua.Function_StopHScript && result != FunkinLua.Function_StopAll) callOnHScript('noteMiss', [daNote]);
	}

	function noteMissPress(direction:Int = 1):Void //You pressed a key when there was no notes to press for this key
	{
		if(ClientPrefs.data.ghostTapping || direction == 4) return; //screw it

		noteMissCommon(direction);
		FlxG.sound.play(Paths.soundRandom('missnote', 1, 3), ClientPrefs.data.misssoundVolume);
		callOnScripts('noteMissPress', [direction]);
	}

	function noteMissCommon(direction:Int, note:Note = null)
	{
		// score and data
		var subtract:Float = 0.05;
		if(note != null) subtract = note.missHealth;
		health -= subtract * healthLoss;

		if(instakillOnMiss)
		{
			vocals.volume = 0;
			doDeathCheck(true);
		}
		combo = 0;

		if(!endingSong) songMisses++;
		if(!practiceMode && direction != 4) songScore -= 10;
		if (direction == 4) songScore -= note.fifthNoteJSON.missScore;
		totalPlayed++;
		RecalculateRating(true);

		// play character anims
		var char:Character = boyfriend;
		if((note != null && note.gfNote) || (SONG.notes[curSection] != null && SONG.notes[curSection].gfSection)) char = gf;
		
		if(char != null && char.hasMissAnimations)
		{
			var suffix:String = '';
			if(note != null) suffix = note.animSuffix;

			var animToPlay:String = singAnimations[Std.int(Math.abs(Math.min(singAnimations.length-1, direction)))] + 'miss' + suffix;
			char.playAnim(animToPlay, true);
			
			if(char != gf && combo > 5 && gf != null && gf.animOffsets.exists('sad'))
			{
				gf.playAnim('sad');
				gf.specialAnim = true;
			}
		}
		vocals.volume = 0;
	}

	function opponentNoteHit(note:Note):Void
	{
		if (Paths.formatToSongPath(SONG.song) != 'tutorial')
			camZooming = true;

		if(note.noteType == 'Hey!' && dad.animOffsets.exists('hey')) {
			dad.playAnim('hey', true);
			dad.specialAnim = true;
			dad.heyTimer = 0.6;
		} else if(!note.noAnimation) {
			var altAnim:String = note.animSuffix;

			if (SONG.notes[curSection] != null)
			{
				if (SONG.notes[curSection].altAnim && !SONG.notes[curSection].gfSection) {
					altAnim = '-alt';
				}
			}

			var char:Character = dad;
			var animToPlay:String = singAnimations[Std.int(Math.abs(Math.min(singAnimations.length-1, note.noteData)))] + altAnim;
			if(note.gfNote) {
				char = gf;
			}

			if(char != null)
			{
				char.playAnim(animToPlay, true);
				char.holdTimer = 0;
			}
		}
		if (curSong.toLowerCase() == 'big shot' || curSong.toLowerCase() == 'laugh track') healthDrain = true;

		if (healthDrain)
		{
			if (healthDrainValue < 0) healthDrainValue *= -1;
			health -= healthDrainValue;
			if (health <= 0.04)
				health = 0.04;
		}

		if (SONG.needsVoices)
			vocals.volume = 1;

		strumPlayAnim(true, Std.int(Math.abs(note.noteData)), Conductor.stepCrochet * 1.25 / 1000 / playbackRate);
		note.hitByOpponent = true;

		var result:Dynamic = callOnLuas('opponentNoteHit', [notes.members.indexOf(note), Math.abs(note.noteData), note.noteType, note.isSustainNote]);
		if(result != FunkinLua.Function_Stop && result != FunkinLua.Function_StopHScript && result != FunkinLua.Function_StopAll) callOnHScript('opponentNoteHit', [note]);

		if (!note.isSustainNote)
		{
			note.kill();
			notes.remove(note, true);
			note.destroy();
		}
	}

	function goodNoteHit(note:Note):Void
	{
		if (!note.wasGoodHit)
		{
			if(cpuControlled && (note.ignoreNote || note.hitCausesMiss)) return;

			note.wasGoodHit = true;
			if (ClientPrefs.data.hitsoundVolume > 0 && !note.hitsoundDisabled && note.noteType != 'Extra Note')
				FlxG.sound.play(Paths.sound(note.hitsound), ClientPrefs.data.hitsoundVolume);

			if (note.noteType == 'Extra Note' && note.fifthNoteJSON.hitSoundEnabled)
				FlxG.sound.play(Paths.sound(note.hitsound), 0.7);

			if(note.hitCausesMiss) {
				noteMiss(note);
				if(!note.noteSplashData.disabled && !note.isSustainNote)
					spawnNoteSplashOnNote(note);

				if(!note.noMissAnimation)
				{
					switch(note.noteType) {
						case 'Hurt Note': //Hurt note
							if(boyfriend.animation.getByName('hurt') != null) {
								boyfriend.playAnim('hurt', true);
								boyfriend.specialAnim = true;
							}
					}
				}

				if (!note.isSustainNote)
				{
					note.kill();
					notes.remove(note, true);
					note.destroy();
				}
				return;
			}

			if (!note.isSustainNote)
			{
				combo++;
				if(combo > 9999) combo = 9999;
				popUpScore(note);
			}
			health += note.hitHealth * healthGain;

			if(!note.noAnimation) {
				var animToPlay:String = singAnimations[Std.int(Math.abs(Math.min(singAnimations.length-1, note.noteData)))];

				var char:Character = boyfriend;
				var animCheck:String = 'hey';
				if(note.gfNote)
				{
					char = gf;
					animCheck = 'cheer';
				}
				
				if(char != null)
				{
					if (note.noteType == 'Extra Note') {
						if (note.fifthNoteJSON.playAnim) {
							if(char.animOffsets.exists(note.fifthNoteJSON.charAnimation)) {
								char.playAnim(note.fifthNoteJSON.charAnimation, true);
								char.specialAnim = true;
								char.heyTimer = 0.6;
							}
						}
					}
					else {
						char.playAnim(animToPlay + note.animSuffix, true);
						char.holdTimer = 0;
					
						if(note.noteType == 'Hey!') {
							if(char.animOffsets.exists(animCheck)) {
								char.playAnim(animCheck, true);
								char.specialAnim = true;
								char.heyTimer = 0.6;
							}
						}
					}
				}
			}

			if(!cpuControlled)
			{
				var spr = playerStrums.members[note.noteData];
				if(spr != null) spr.playAnim('confirm', true);
			}
			else strumPlayAnim(false, Std.int(Math.abs(note.noteData)), Conductor.stepCrochet * 1.25 / 1000 / playbackRate);
			vocals.volume = 1;

			var isSus:Bool = note.isSustainNote; //HAHAHAHA AMONGUS AMONGUS AMONGUS AMONGUS
			var leData:Int = Math.round(Math.abs(note.noteData));
			var leType:String = note.noteType;

			if (!note.isSustainNote)
			{
				note.kill();
				notes.remove(note, true);
				note.destroy();
			}
			var result:Dynamic = callOnLuas('goodNoteHit', [notes.members.indexOf(note), leData, leType, isSus]);
			if(result != FunkinLua.Function_Stop && result != FunkinLua.Function_StopHScript && result != FunkinLua.Function_StopAll) callOnHScript('goodNoteHit', [note]);
		}
	}

	public function spawnNoteSplashOnNote(note:Note) {
		if(note != null) {
			var strum:StrumNote = playerStrums.members[note.noteData];
			if(strum != null)
				spawnNoteSplash(strum.x, strum.y, note.noteData, note);
		}
	}

	public function spawnNoteSplash(x:Float, y:Float, data:Int, ?note:Note = null) {
		var skin:String = SONG.splashSkin;
		if(splashTexture != null && splashTexture.length > 0) skin = splashTexture;

		var splash:NoteSplash = grpNoteSplashes.recycle(NoteSplash);
		splash.setupNoteSplash(x, y, data, note, skin);
		grpNoteSplashes.add(splash);
	}

	override function destroy() {
		#if LUA_ALLOWED
		for (i in 0...luaArray.length) {
			var lua:FunkinLua = luaArray[0];
			lua.call('onDestroy', []);
			lua.stop();
		}
		luaArray = [];
		FunkinLua.customFunctions.clear();
		#end

		#if HSCRIPT_ALLOWED
		for (script in hscriptArray)
			if(script != null)
			{
				script.call('onDestroy');
				script.destroy();
			}

		while (hscriptArray.length > 0)
			hscriptArray.pop();
		#end

		FlxG.stage.removeEventListener(KeyboardEvent.KEY_DOWN, onKeyPress);
		FlxG.stage.removeEventListener(KeyboardEvent.KEY_UP, onKeyRelease);
		FlxAnimationController.globalSpeed = 1;
		FlxG.sound.music.pitch = 1;
		Note.globalRgbShaders = [];
		backend.NoteTypesConfig.clearNoteTypesData();
		instance = null;
		super.destroy();
	}

	public static function cancelMusicFadeTween() {
		if(FlxG.sound.music.fadeTween != null) {
			FlxG.sound.music.fadeTween.cancel();
		}
		FlxG.sound.music.fadeTween = null;
	}

	var lastStepHit:Int = -1;
	override function stepHit()
	{
		if(FlxG.sound.music.time >= -ClientPrefs.data.noteOffset)
		{
			if (Math.abs(FlxG.sound.music.time - (Conductor.songPosition - Conductor.offset)) > (20 * playbackRate)
				|| (SONG.needsVoices && Math.abs(vocals.time - (Conductor.songPosition - Conductor.offset)) > (20 * playbackRate)))
			{
				resyncVocals();
			}
		}

		super.stepHit();

		if(curStep == lastStepHit) {
			return;
		}

		lastStepHit = curStep;
		setOnScripts('curStep', curStep);
		callOnScripts('onStepHit');
	}

	var lastBeatHit:Int = -1;

	override function beatHit()
	{
		if(lastBeatHit >= curBeat) {
			return;
		}

		if (generatedMusic)
			notes.sort(FlxSort.byY, ClientPrefs.data.downScroll ? FlxSort.ASCENDING : FlxSort.DESCENDING);

		iconP1.scale.set(1.2, 1.2);
		iconP2.scale.set(1.2, 1.2);

		iconP1.updateHitbox();
		iconP2.updateHitbox();

		if (gf != null && curBeat % Math.round(gfSpeed * gf.danceEveryNumBeats) == 0 && gf.animation.curAnim != null && !gf.animation.curAnim.name.startsWith("sing") && !gf.stunned)
			gf.dance();
		if (curBeat % boyfriend.danceEveryNumBeats == 0 && boyfriend.animation.curAnim != null && !boyfriend.animation.curAnim.name.startsWith('sing') && !boyfriend.stunned && !bfDodging)
			boyfriend.dance();
		if (curBeat % dad.danceEveryNumBeats == 0 && dad.animation.curAnim != null && !dad.animation.curAnim.name.startsWith('sing') && !dad.stunned)
			dad.dance();

		super.beatHit();

		if (phillyGlowOn)
		{
			if(ClientPrefs.data.camZooms && FlxG.camera.zoom < 1.35)
			{
				FlxG.camera.zoom += 0.03;
				if (!dsFilterOn)
					camHUD.zoom += 0.06;
			}
			var color:FlxColor = phillyLightsColors[curLightEvent];
			var chars:Array<Character> = [boyfriend, gf, dad];
			if (curBeat % 4 == 0)
			{
				curLightEvent = FlxG.random.int(0, phillyLightsColors.length-1, [curLightEvent]);
				color = phillyLightsColors[curLightEvent];
				if(ClientPrefs.data.flashing)
				{
					var colorButLower:FlxColor = color;
					colorButLower.alphaFloat = 0.25;
					FlxG.camera.flash(colorButLower, 0.5, null, true);
				}
				var charColor:FlxColor = color;
				if(!ClientPrefs.data.flashing) charColor.saturation *= 0.5;
				else charColor.saturation *= 0.75;

				for (who in chars)
				{
					who.color = charColor;
				}
				phillyGlowParticles.forEachAlive(function(particle:PhillyGlowParticle)
				{
					particle.color = color;
				});
				phillyGlowGradient.color = color;
				if (curStage == 'philly')
					phillyWindowEvent.color = color;

				color.brightness *= 0.5;
				phillyGlowFG.color = color;
			}

			if(!ClientPrefs.data.lowQuality)
			{
				var particlesNum:Int = FlxG.random.int(8, 12);
				var width:Float = (2000 / particlesNum);
				var color:FlxColor = phillyLightsColors[curLightEvent];
				for (j in 0...3)
				{
					for (i in 0...particlesNum)
					{
						var particle:PhillyGlowParticle = new PhillyGlowParticle(-400 + width * i + FlxG.random.float(-width / 5, width / 5), phillyGlowGradient.originalY + 200 + (FlxG.random.float(0, 125) + j * 40), color);
						phillyGlowParticles.add(particle);
					}
				}
			}
			phillyGlowGradient.bop();
		}

		lastBeatHit = curBeat;

		setOnScripts('curBeat', curBeat);
		callOnScripts('onBeatHit');
	}

	override function sectionHit()
	{
		if (SONG.notes[curSection] != null)
		{
			if (generatedMusic && !endingSong && !isCameraOnForcedPos)
				moveCameraSection();

			if (camZooming && FlxG.camera.zoom < 1.35 && ClientPrefs.data.camZooms)
			{
				FlxG.camera.zoom += 0.015 * camZoomingMult;
				if (!dsFilterOn)
					camHUD.zoom += 0.03 * camZoomingMult;
			}

			if (SONG.notes[curSection].changeBPM)
			{
				Conductor.bpm = SONG.notes[curSection].bpm;
				setOnScripts('curBpm', Conductor.bpm);
				setOnScripts('crochet', Conductor.crochet);
				setOnScripts('stepCrochet', Conductor.stepCrochet);
			}
			setOnScripts('mustHitSection', SONG.notes[curSection].mustHitSection);
			setOnScripts('altAnim', SONG.notes[curSection].altAnim);
			setOnScripts('gfSection', SONG.notes[curSection].gfSection);
		}
		super.sectionHit();
		
		setOnScripts('curSection', curSection);
		callOnScripts('onSectionHit');
	}

	#if LUA_ALLOWED
	public function startLuasNamed(luaFile:String)
	{
		#if MODS_ALLOWED
		var luaToLoad:String = Paths.modFolders(luaFile);
		if(!FileSystem.exists(luaToLoad))
			luaToLoad = Paths.getPreloadPath(luaFile);
		
		if(FileSystem.exists(luaToLoad))
		#elseif sys
		var luaToLoad:String = Paths.getPreloadPath(luaFile);
		if(OpenFlAssets.exists(luaToLoad))
		#end
		{
			for (script in luaArray)
				if(script.scriptName == luaToLoad) return false;
	
			new FunkinLua(luaToLoad);
			return true;
		}
		return false;
	}
	#end
	
	#if HSCRIPT_ALLOWED
	public function startHScriptsNamed(scriptFile:String)
	{
		var scriptToLoad:String = Paths.modFolders(scriptFile);
		if(!FileSystem.exists(scriptToLoad))
			scriptToLoad = Paths.getPreloadPath(scriptFile);
		
		if(FileSystem.exists(scriptToLoad))
		{
			if (SScript.global.exists(scriptToLoad)) return false;
	
			initHScript(scriptToLoad);
			return true;
		}
		return false;
	}

	public function initHScript(file:String)
	{
		try
		{
			var newScript:HScript = new HScript(null, file);
			@:privateAccess
			if(newScript.parsingExceptions != null && newScript.parsingExceptions.length > 0)
			{
				@:privateAccess
				for (e in newScript.parsingExceptions)
					if(e != null)
						addTextToDebug('ERROR ON LOADING ($file): ${e.message.substr(0, e.message.indexOf('\n'))}', FlxColor.RED);
				newScript.destroy();
				return;
			}

			hscriptArray.push(newScript);
			if(newScript.exists('onCreate'))
			{
				var callValue = newScript.call('onCreate');
				if(!callValue.succeeded)
				{
					for (e in callValue.exceptions)
						if (e != null)
							addTextToDebug('ERROR ($file: onCreate) - ${e.message.substr(0, e.message.indexOf('\n'))}', FlxColor.RED);

					newScript.destroy();
					hscriptArray.remove(newScript);
					trace('failed to initialize sscript interp!!! ($file)');
				}
				else trace('initialized sscript interp successfully: $file');
			}
			
		}
		catch(e)
		{
			addTextToDebug('ERROR ($file) - ' + e.message.substr(0, e.message.indexOf('\n')), FlxColor.RED);
			var newScript:HScript = cast (SScript.global.get(file), HScript);
			if(newScript != null)
			{
				newScript.destroy();
				hscriptArray.remove(newScript);
			}
		}
	}
	#end

	public function callOnScripts(funcToCall:String, args:Array<Dynamic> = null, ignoreStops = false, exclusions:Array<String> = null, excludeValues:Array<Dynamic> = null):Dynamic {
		var returnVal:Dynamic = psychlua.FunkinLua.Function_Continue;
		if(args == null) args = [];
		if(exclusions == null) exclusions = [];
		if(excludeValues == null) excludeValues = [psychlua.FunkinLua.Function_Continue];

		var result:Dynamic = callOnLuas(funcToCall, args, ignoreStops, exclusions, excludeValues);
		if(result == null || excludeValues.contains(result)) result = callOnHScript(funcToCall, args, ignoreStops, exclusions, excludeValues);
		return result;
	}

	public function callOnLuas(funcToCall:String, args:Array<Dynamic> = null, ignoreStops = false, exclusions:Array<String> = null, excludeValues:Array<Dynamic> = null):Dynamic {
		var returnVal:Dynamic = FunkinLua.Function_Continue;
		#if LUA_ALLOWED
		if(args == null) args = [];
		if(exclusions == null) exclusions = [];
		if(excludeValues == null) excludeValues = [FunkinLua.Function_Continue];

		var len:Int = luaArray.length;
		var i:Int = 0;
		while(i < len)
		{
			var script:FunkinLua = luaArray[i];
			if(exclusions.contains(script.scriptName))
			{
				i++;
				continue;
			}

			var myValue:Dynamic = script.call(funcToCall, args);
			if((myValue == FunkinLua.Function_StopLua || myValue == FunkinLua.Function_StopAll) && !excludeValues.contains(myValue) && !ignoreStops)
			{
				returnVal = myValue;
				break;
			}
			
			if(myValue != null && !excludeValues.contains(myValue))
				returnVal = myValue;

			if(!script.closed) i++;
			else len--;
		}
		#end
		return returnVal;
	}
	
	public function callOnHScript(funcToCall:String, args:Array<Dynamic> = null, ?ignoreStops:Bool = false, exclusions:Array<String> = null, excludeValues:Array<Dynamic> = null):Dynamic {
		var returnVal:Dynamic = psychlua.FunkinLua.Function_Continue;

		#if HSCRIPT_ALLOWED
		if(exclusions == null) exclusions = new Array();
		if(excludeValues == null) excludeValues = new Array();
		excludeValues.push(psychlua.FunkinLua.Function_Continue);

		var len:Int = hscriptArray.length;
		if (len < 1)
			return returnVal;
		for(i in 0...len)
		{
			var script:HScript = hscriptArray[i];
			if(script == null || !script.exists(funcToCall) || exclusions.contains(script.origin))
				continue;

			var myValue:Dynamic = null;
			try
			{
				var callValue = script.call(funcToCall, args);
				if(!callValue.succeeded)
				{
					var e = callValue.exceptions[0];
					if(e != null)
						FunkinLua.luaTrace('ERROR (${script.origin}: ${callValue.calledFunction}) - ' + e.message.substr(0, e.message.indexOf('\n')), true, false, FlxColor.RED);
				}
				else
				{
					myValue = callValue.returnValue;
					if((myValue == FunkinLua.Function_StopHScript || myValue == FunkinLua.Function_StopAll) && !excludeValues.contains(myValue) && !ignoreStops)
					{
						returnVal = myValue;
						break;
					}
					
					if(myValue != null && !excludeValues.contains(myValue))
						returnVal = myValue;
				}
			}
		}
		#end

		return returnVal;
	}

	public function setOnScripts(variable:String, arg:Dynamic, exclusions:Array<String> = null) {
		if(exclusions == null) exclusions = [];
		setOnLuas(variable, arg, exclusions);
		setOnHScript(variable, arg, exclusions);
	}

	public function setOnLuas(variable:String, arg:Dynamic, exclusions:Array<String> = null) {
		#if LUA_ALLOWED
		if(exclusions == null) exclusions = [];
		for (script in luaArray) {
			if(exclusions.contains(script.scriptName))
				continue;

			script.set(variable, arg);
		}
		#end
	}

	public function setOnHScript(variable:String, arg:Dynamic, exclusions:Array<String> = null) {
		#if HSCRIPT_ALLOWED
		if(exclusions == null) exclusions = [];
		for (script in hscriptArray) {
			if(exclusions.contains(script.origin))
				continue;

			script.set(variable, arg);
		}
		#end
	}

	function strumPlayAnim(isDad:Bool, id:Int, time:Float) {
		var spr:StrumNote = null;
		if(isDad) {
			spr = opponentStrums.members[id];
		} else {
			spr = playerStrums.members[id];
		}

		if(spr != null) {
			spr.playAnim('confirm', true);
			spr.resetAnim = time;
		}
	}

	public var ratingName:String = '?';
	public var ratingPercent:Float;
	public var ratingFC:String;
	public function RecalculateRating(badHit:Bool = false) {
		setOnScripts('score', songScore);
		setOnScripts('misses', songMisses);
		setOnScripts('hits', songHits);
		setOnScripts('combo', combo);

		var ret:Dynamic = callOnScripts('onRecalculateRating', null, true);
		if(ret != FunkinLua.Function_Stop)
		{
			ratingName = '?';
			if(totalPlayed != 0) //Prevent divide by 0
			{
				// Rating Percent
				ratingPercent = Math.min(1, Math.max(0, totalNotesHit / totalPlayed));

				// Rating Name
				ratingName = ratingStuff[ratingStuff.length-1][0]; //Uses last string
				if(ratingPercent < 1)
					for (i in 0...ratingStuff.length-1)
						if(ratingPercent < ratingStuff[i][1])
						{
							ratingName = ratingStuff[i][0];
							break;
						}
			}
			fullComboFunction();
		}
		updateScore(badHit); // score will only update after rating is calculated, if it's a badHit, it shouldn't bounce -Ghost
		setOnScripts('rating', ratingPercent);
		setOnScripts('ratingName', ratingName);
		setOnScripts('ratingFC', ratingFC);
	}

	function fullComboUpdate()
	{
		sicks = ratingsData[0].hits;
		goods = ratingsData[1].hits;
		bads = ratingsData[2].hits;
		trashes = ratingsData[3].hits;

		ratingFC = 'Clear';
		if(songMisses < 1)
		{
			if (bads > 0 || trashes > 0) ratingFC = 'FC';
			else if (goods > 0) ratingFC = 'GFC';
			else if (sicks > 0) ratingFC = 'SFC';
		}
		else if (songMisses < 10)
			ratingFC = 'SDCB';
	}

	#if ACHIEVEMENTS_ALLOWED
	private function checkForAchievement(achievesToCheck:Array<String> = null)
	{
		if(chartingMode) return;

		var usedPractice:Bool = (ClientPrefs.getGameplaySetting('practice') || ClientPrefs.getGameplaySetting('botplay'));
		if(cpuControlled) return;

		for (name in achievesToCheck) {
			var unlock:Bool = false;
			if (name != WeekData.getWeekFileName() + '_nomiss' && Achievements.exists(name)) // common achievements
			{
				switch(name)
				{
					case 'ur_bad':
						unlock = (ratingPercent < 0.2 && !practiceMode);

					case 'ur_good':
						unlock = (ratingPercent >= 1 && !usedPractice);

					case 'oversinging':
						unlock = (boyfriend.holdTimer >= 10 && !usedPractice);

					case 'hype':
						unlock = (!boyfriendIdled && !usedPractice);

					case 'two_keys':
						unlock = (!usedPractice && keysPressed.length <= 2);

					case 'toastie':
						unlock = (!ClientPrefs.data.cacheOnGPU && !ClientPrefs.data.shaders && ClientPrefs.data.lowQuality && !ClientPrefs.data.antialiasing);

					case 'debugger':
						unlock = (Paths.formatToSongPath(SONG.song) == 'test' && !usedPractice);

					case 'showoff':
						unlock = (Paths.formatToSongPath(SONG.song) == "mild" && dodgeCount >= 60 && !usedPractice);

					case 'pizza_clear':
						unlock = (Paths.formatToSongPath(SONG.song) == 'pizza-time' && !usedPractice);
				}
			}
			// any FC achievements, name should be "weekFileName_nomiss", e.g: "week3_nomiss"
			else if (Achievements.exists(WeekData.getWeekFileName() + '_nomiss')) // Seriously Shadow Mario, HOW HARD IS IT TO GET THESE RIGHT?!?!?!
			{
				if(isStoryMode && campaignMisses + songMisses < 1 && Difficulty.getString().toUpperCase() == 'HARD'
					&& storyPlaylist.length <= 1 && !changedDifficulty && !usedPractice)
					unlock = true;
			}

			if(unlock) Achievements.unlock(name);
		}
	}
	#end

	#if (!flash && sys)
	public var runtimeShaders:Map<String, Array<String>> = new Map<String, Array<String>>();
	public function createRuntimeShader(name:String):FlxRuntimeShader
	{
		if(!ClientPrefs.data.shaders) return new FlxRuntimeShader();

		#if (!flash && MODS_ALLOWED && sys)
		if(!runtimeShaders.exists(name) && !initLuaShader(name))
		{
			FlxG.log.warn('Shader $name is missing!');
			return new FlxRuntimeShader();
		}

		var arr:Array<String> = runtimeShaders.get(name);
		return new FlxRuntimeShader(arr[0], arr[1]);
		#else
		FlxG.log.warn("Platform unsupported for Runtime Shaders!");
		return null;
		#end
	}

	public function initLuaShader(name:String, ?glslVersion:Int = 120)
	{
		if(!ClientPrefs.data.shaders) return false;

		#if (MODS_ALLOWED && !flash && sys)
		if(runtimeShaders.exists(name))
		{
			FlxG.log.warn('Shader $name was already initialized!');
			return true;
		}

		var foldersToCheck:Array<String> = [Paths.mods('shaders/')];
		if(Mods.currentModDirectory != null && Mods.currentModDirectory.length > 0)
			foldersToCheck.insert(0, Paths.mods(Mods.currentModDirectory + '/shaders/'));

		for(mod in Mods.getGlobalMods())
			foldersToCheck.insert(0, Paths.mods(mod + '/shaders/'));
		
		for (folder in foldersToCheck)
		{
			if(FileSystem.exists(folder))
			{
				var frag:String = folder + name + '.frag';
				var vert:String = folder + name + '.vert';
				var found:Bool = false;
				if(FileSystem.exists(frag))
				{
					frag = File.getContent(frag);
					found = true;
				}
				else frag = null;

				if(FileSystem.exists(vert))
				{
					vert = File.getContent(vert);
					found = true;
				}
				else vert = null;

				if(found)
				{
					runtimeShaders.set(name, [frag, vert]);
					return true;
				}
			}
		}
		FlxG.log.warn('Missing shader $name .frag AND .vert files!');
		#else
		FlxG.log.warn('This platform doesn\'t support Runtime Shaders!', false, false, FlxColor.RED);
		#end
		return false;
	}
	#end
}

/* Since you're down here, have a sussy impostor amongus

				/////////////////////////////
			///////////////////////////////////
		/////////////////////////////////////////
	  //						   ////////////////
	//                               ////////////////
  //                                   //////////////
  //                                   //////////////\
  //                                   //////////////\\
  //                				   //////////////\\\
  //								   //////////////\\\\
    //                               ////////////////\\\\\
	  //						   //////////////////\\\\\
	  	/////////////////////////////////////////////\\\\\
			/////////////////////////////////////////\\\\\
			/////////////////////////////////////////\\\\\
			/////////////////////////////////////////\\\\
			/////////////////////////////////////////\\\
			/////////////////////////////////////////\\
			/////////////////////////////////////////\
			/////////////////////////////////////////
			/////////////////////////////////////////
			/////////////////////////////////////////
			/////////////				/////////////
			/////////////				/////////////
			/////////////				/////////////
			/////////////				/////////////
			/////////////				/////////////
			/////////////				/////////////

	I will not apologize for art!
*/