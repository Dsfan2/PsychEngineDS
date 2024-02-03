package states;

import backend.WeekData;
import backend.Highscore;
import backend.Song;

import lime.utils.Assets;
import openfl.utils.Assets as OpenFlAssets;

import objects.HealthIcon;
import states.editors.ChartingState;
import flixel.util.FlxSave;
import flixel.effects.FlxFlicker;

import substates.GameplayChangersSubstate;
import substates.ResetScoreSubState;
import objects.MusicPlayer;
import objects.CoolScrollText;

#if MODS_ALLOWED
import sys.FileSystem;
#end
#if LUA_ALLOWED
import psychlua.*;
#else
import psychlua.FreeplayLua;
import psychlua.LuaUtilsFreeplay;
import psychlua.HScriptFreeplay;
#end

#if (SScript >= "3.0.0" && HSCRIPT_ALLOWED)
import tea.SScript;
#end

class FreeplayState extends MusicBeatState
{
	public var isFreeplayState:Bool = false;
	public var variables:Map<String, Dynamic> = new Map();
	#if HSCRIPT_ALLOWED
	public var hscriptArray:Array<HScriptFreeplay> = [];
	#end
	#if LUA_ALLOWED
	public var modchartTweens:Map<String, FlxTween> = new Map<String, FlxTween>();
	public var modchartSprites:Map<String, ModchartSprite> = new Map<String, ModchartSprite>();
	public var modchartTimers:Map<String, FlxTimer> = new Map<String, FlxTimer>();
	public var modchartSounds:Map<String, FlxSound> = new Map<String, FlxSound>();
	public var modchartTexts:Map<String, FlxText> = new Map<String, FlxText>();
	public var modchartSaves:Map<String, FlxSave> = new Map<String, FlxSave>();
	public var modchartBackdrops:Map<String, ModchartBackdrop> = new Map<String, ModchartBackdrop>();
	#if VIDEOS_ALLOWED
	public var modchartVideos:Map<String, ModchartVideo> = new Map<String, ModchartVideo>();
	#end
	#end

	public var paused:Bool = false;
	var songs:Array<SongMetadata> = [];

	var selector:FlxText;
	private static var curSelected:Int = 0;
	var lerpSelected:Float = 0;
	var curDifficulty:Int = -1;
	private static var lastDifficultyName:String = Difficulty.getDefault();

	public static var selectedItem:String = '';
	public static var selectedDifficulty:String = '';
	public static var curAlbum:String = '';

	var scoreBG:FlxSprite;
	var scoreText:FlxText;
	var diffText:FlxText;
	var lerpScore:Int = 0;
	var lerpRating:Float = 0;
	var intendedScore:Int = 0;
	var intendedRating:Float = 0;

	private var grpSongs:FlxTypedGroup<CoolScrollText>;
	private var curPlaying:Bool = false;

	private var iconArray:Array<HealthIcon> = [];

	public static var instance:FreeplayState;
	public var luaArray:Array<FreeplayLua> = [];
	private var luaDebugGroup:FlxTypedGroup<DebugLuaText>;

	public var bg:FlxSprite;

	public var songList:Array<String> = [];
	public var iconList:Array<String> = [];

	public var camMain:FlxCamera;
	public var camText:FlxCamera;

	var missingTextBG:FlxSprite;
	var missingText:FlxText;

	var player:MusicPlayer;
	var bottomText:FlxText;
	var bottomString:String;
	var bottomTextBG:FlxSprite;

	var albumCover:FlxSprite;
	var discThing:FlxSprite;

	override function create()
	{
		// for lua
		instance = this;
		
		persistentUpdate = true;
		PlayState.isStoryMode = false;
		WeekData.reloadWeekFiles(false);

		camMain = new FlxCamera();
		camText = new FlxCamera();
		camText.bgColor.alpha = 0;

		FlxG.cameras.reset(camMain);
		FlxG.cameras.add(camText, false);
		FlxG.cameras.setDefaultDrawTarget(camMain, true);

		CustomFadeTransition.nextCamera = camText;

		#if desktop
		// Updating Discord Rich Presence
		DiscordClient.changePresence("In the Menus", null);
		#end

		for (i in 0...WeekData.weeksList.length) {
			if(weekIsLocked(WeekData.weeksList[i])) continue;

			var leWeek:WeekData = WeekData.weeksLoaded.get(WeekData.weeksList[i]);
			var leSongs:Array<String> = [];
			var leAlbums:Array<String> = [];

			for (j in 0...leWeek.songs.length)
			{
				leSongs.push(leWeek.songs[j][0]);
				leAlbums.push(leWeek.songs[j][1]);
			}

			WeekData.setDirectoryFromWeek(leWeek);
			for (song in leWeek.songs)
			{
				addSong(song[0], i, song[1]);
			}
		}
		Mods.loadTopMod();

		#if LUA_ALLOWED
		luaDebugGroup = new FlxTypedGroup<DebugLuaText>();
		luaDebugGroup.cameras = [camText];
		add(luaDebugGroup);
		#end

		#if LUA_ALLOWED
		var filesPushed:Array<String> = [];
		var foldersToCheck:Array<String> = [Paths.getPreloadPath('scripts/')];

		#if MODS_ALLOWED
		foldersToCheck.insert(0, Paths.mods('scripts/'));
		if(Mods.currentModDirectory != null && Mods.currentModDirectory.length > 0)
			foldersToCheck.insert(0, Paths.mods(Mods.currentModDirectory + '/scripts/'));

		for(mod in Mods.getGlobalMods())
			foldersToCheck.insert(0, Paths.mods(mod + '/scripts/'));
		#end

		for (folder in foldersToCheck)
		{
			if(FileSystem.exists(folder))
			{
				for (file in FileSystem.readDirectory(folder))
				{
					if(file.endsWith('freeplay.lua') && !filesPushed.contains(file))
					{
						luaArray.push(new FreeplayLua(folder + file));
						filesPushed.push(file);
					}
				}
			}
		}
		#end

		bg = new FlxSprite().loadGraphic(Paths.image('menuFreeplay'));
		bg.antialiasing = ClientPrefs.data.antialiasing;
		add(bg);
		bg.screenCenter();

		grpSongs = new FlxTypedGroup<CoolScrollText>();
		add(grpSongs);

		for (i in 0...songs.length)
		{
			var songText:CoolScrollText = new CoolScrollText(30, (100 * i) + 400, 0, songs[i].songName, true, 46);
			songText.targetY = i;
			songText.antialiasing = true;
			songText.ID = i;
			grpSongs.add(songText);

			Mods.currentModDirectory = songs[i].folder;
			songList.push(songs[i].songName);
		}
		WeekData.setDirectoryFromWeek();

		setOnLuas('songList', songList);
		setOnScripts('songList', songList);

		discThing = new FlxSprite(700, 240).loadGraphic(Paths.image('albums/album-disc'));
		discThing.setGraphicSize(Std.int(discThing.width * 0.5));
		discThing.updateHitbox();
		discThing.angle = 0;
		add(discThing);

		albumCover = new FlxSprite(565, 240);
		if (songs[curSelected].album == '' || songs[curSelected].album == null)
			albumCover.loadGraphic(Paths.image('albums/blank'));
		else
		{
			#if MODS_ALLOWED
			if (FileSystem.exists('assets/images/albums/' + songs[curSelected].album + '.png') || FileSystem.exists(Paths.modFolders('images/albums/' + songs[curSelected].album + '.png')))
				albumCover.loadGraphic(Paths.image('albums/' + songs[curSelected].album));
			else
				albumCover.loadGraphic(Paths.image('albums/blank'));
			#else
			if (OpenFlAssets.exists(Paths.image('albums/' + songs[curSelected].album)))
				albumCover.loadGraphic(Paths.image('albums/' + songs[curSelected].album));
			else
				albumCover.loadGraphic(Paths.image('albums/blank'));
			#end
		}
		albumCover.setGraphicSize(Std.int(albumCover.width * 0.5));
		albumCover.updateHitbox();
		add(albumCover);

		scoreText = new FlxText(FlxG.width * 0.7, 5, 0, "", 32);
		scoreText.setFormat(Paths.font("vcr.ttf"), 32, FlxColor.WHITE, RIGHT);
		scoreText.cameras = [camText];

		scoreBG = new FlxSprite(scoreText.x - 6, 0).makeGraphic(1, 66, 0xFF000000);
		scoreBG.alpha = 0.6;
		scoreBG.cameras = [camText];
		add(scoreBG);

		diffText = new FlxText(scoreText.x, scoreText.y + 36, 0, "", 24);
		diffText.font = scoreText.font;
		diffText.cameras = [camText];diffText.cameras = [camText];
		add(diffText);

		add(scoreText);

		missingTextBG = new FlxSprite().makeGraphic(FlxG.width, FlxG.height, FlxColor.BLACK);
		missingTextBG.alpha = 0.6;
		missingTextBG.visible = false;
		add(missingTextBG);
		
		missingText = new FlxText(50, 0, FlxG.width - 100, '', 24);
		missingText.setFormat(Paths.font("vcr.ttf"), 24, FlxColor.WHITE, CENTER, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		missingText.scrollFactor.set();
		missingText.visible = false;
		add(missingText);

		if(curSelected >= songs.length) curSelected = 0;
		lerpSelected = curSelected;

		curDifficulty = Math.round(Math.max(0, Difficulty.defaultList.indexOf(lastDifficultyName)));

		var swag:Alphabet = new Alphabet(1, 0, "swag");

		bottomTextBG = new FlxSprite(0, FlxG.height - 26).makeGraphic(FlxG.width, 26, 0xFF000000);
		bottomTextBG.alpha = 0.6;
		bottomTextBG.cameras = [camText];
		add(bottomTextBG);

		#if PRELOAD_ALL
		var leText:String = "Press SPACE to listen to the Song / Press CTRL to open the Gameplay Changers Menu / Press RESET to Reset your Score and Accuracy.";
		var size:Int = 16;
		#else
		var leText:String = "Press CTRL to open the Gameplay Changers Menu / Press RESET to Reset your Score and Accuracy.";
		var size:Int = 18;
		#end
		bottomString = leText;
		bottomText = new FlxText(bottomTextBG.x, bottomTextBG.y + 4, FlxG.width, bottomString, size);
		bottomText.setFormat(Paths.font("vcr.ttf"), size, FlxColor.WHITE, CENTER);
		bottomText.scrollFactor.set();
		bottomText.cameras = [camText];
		add(bottomText);

		player = new MusicPlayer(this);
		player.cameras = [camText];
		add(player);
		
		changeSelection();
		reloadAlbumCover();
		super.create();
		callOnLuas('onCreatePost', []);
		callOnScripts('onCreatePost', []);
	}

	override function closeSubState() {
		changeSelection(0, false);
		persistentUpdate = true;
		super.closeSubState();
	}

	public function addSong(songName:String, weekNum:Int, album:String)
	{
		songs.push(new SongMetadata(songName, weekNum, album));
	}

	function weekIsLocked(name:String):Bool {
		var leWeek:WeekData = WeekData.weeksLoaded.get(name);
		return (!leWeek.startUnlocked && leWeek.weekBefore.length > 0 && (!StoryMenuState.weekCompleted.exists(leWeek.weekBefore) || !StoryMenuState.weekCompleted.get(leWeek.weekBefore)));
	}

	var instPlaying:Int = -1;
	public static var vocals:FlxSound = null;
	var holdTime:Float = 0;
	override function update(elapsed:Float)
	{
		callOnLuas('onUpdate', [elapsed]);
		callOnScripts('onUpdate', [elapsed]);
		if (FlxG.sound.music.volume < 0.7)
		{
			FlxG.sound.music.volume += 0.5 * FlxG.elapsed;
		}
		lerpScore = Math.floor(FlxMath.lerp(lerpScore, intendedScore, FlxMath.bound(elapsed * 24, 0, 1)));
		lerpRating = FlxMath.lerp(lerpRating, intendedRating, FlxMath.bound(elapsed * 12, 0, 1));

		if (Math.abs(lerpScore - intendedScore) <= 10)
			lerpScore = intendedScore;
		if (Math.abs(lerpRating - intendedRating) <= 0.01)
			lerpRating = intendedRating;

		var ratingSplit:Array<String> = Std.string(CoolUtil.floorDecimal(lerpRating * 100, 2)).split('.');
		if(ratingSplit.length < 2) { //No decimals, add an empty space
			ratingSplit.push('');
		}
		
		while(ratingSplit[1].length < 2) { //Less than 2 decimals in it, add decimals then
			ratingSplit[1] += '0';
		}

		if (!player.playingMusic)
		{
			scoreText.text = 'PERSONAL BEST: ' + lerpScore + ' (' + ratingSplit.join('.') + '%)';
			positionHighscore();

			var shiftMult:Int = 1;
			if(FlxG.keys.pressed.SHIFT) shiftMult = 3;

			if(songs.length > 1)
			{
				if(FlxG.keys.justPressed.HOME)
				{
					curSelected = 0;
					changeSelection();
					holdTime = 0;	
				}
				else if(FlxG.keys.justPressed.END)
				{
					curSelected = songs.length - 1;
					changeSelection();
					holdTime = 0;	
				}
				if (controls.UI_UP_P)
				{
					changeSelection(-shiftMult);
					holdTime = 0;
				}
				if (controls.UI_DOWN_P)
				{
					changeSelection(shiftMult);
					holdTime = 0;
				}

				if(controls.UI_DOWN || controls.UI_UP)
				{
					var checkLastHold:Int = Math.floor((holdTime - 0.5) * 10);
					holdTime += elapsed;
					var checkNewHold:Int = Math.floor((holdTime - 0.5) * 10);

					if(holdTime > 0.5 && checkNewHold - checkLastHold > 0)
						changeSelection((checkNewHold - checkLastHold) * (controls.UI_UP ? -shiftMult : shiftMult));
				}

				if(FlxG.mouse.wheel != 0)
				{
					FlxG.sound.play(Paths.sound('scrollMenu'), 0.2);
					changeSelection(-shiftMult * FlxG.mouse.wheel, false);
				}
			}

			if (controls.UI_LEFT_P)
			{
				changeDiff(-1);
				_updateSongLastDifficulty();
			}
			else if (controls.UI_RIGHT_P)
			{
				changeDiff(1);
				_updateSongLastDifficulty();
			}
		}

		if (controls.BACK)
		{
			if (player.playingMusic)
			{
				FlxG.sound.music.stop();
				destroyFreeplayVocals();
				FlxG.sound.music.volume = 0;
				instPlaying = -1;
	
				player.playingMusic = false;
				player.switchPlayMusic();
	
				FlxG.sound.playMusic(Paths.music('freakyMenu'), 0);
				FlxTween.tween(FlxG.sound, {volume: 1}, 2);
				discThing.angle = 0;
			}
			else
			{
				persistentUpdate = false;
				CustomFadeTransition.nextCamera = camText;
				FlxG.sound.play(Paths.sound('cancelMenu'));
				MusicBeatState.switchState(new MainMenuState());
			}
		}

		if(FlxG.keys.justPressed.CONTROL && !player.playingMusic)
		{
			persistentUpdate = false;
			openSubState(new GameplayChangersSubstate());
		}
		else if(FlxG.keys.justPressed.SPACE)
		{
			if(instPlaying != curSelected && !player.playingMusic)
			{
				destroyFreeplayVocals();
				FlxG.sound.music.volume = 0;

				Mods.currentModDirectory = songs[curSelected].folder;
				var poop:String = Highscore.formatSong(songs[curSelected].songName.toLowerCase(), curDifficulty);
				PlayState.SONG = Song.loadFromJson(poop, songs[curSelected].songName.toLowerCase());
				if (PlayState.SONG.needsVoices)
				{
					vocals = new FlxSound().loadEmbedded(Paths.voices(PlayState.SONG.song));
					FlxG.sound.list.add(vocals);
					vocals.persist = true;
					vocals.looped = true;
				}
				else if (vocals != null)
				{
					vocals.stop();
					vocals.destroy();
					vocals = null;
				}

				FlxG.sound.playMusic(Paths.inst(PlayState.SONG.song), 0.8);
				if(vocals != null) //Sync vocals to Inst
				{
					vocals.play();
					vocals.volume = 0.8;
				}
				instPlaying = curSelected;

				player.playingMusic = true;
				player.curTime = 0;
				player.switchPlayMusic();
			}
			else if (instPlaying == curSelected && player.playingMusic)
			{
				player.pauseOrResume(player.paused);
			}
		}

		else if (controls.ACCEPT && !player.playingMusic)
		{
			callOnLuas('onSongSelected', [selectedItem]);
			callOnScripts('onSongSelected', [selectedItem]);

			FlxG.sound.play(Paths.sound('confirmMenu'));
			persistentUpdate = false;
			var songLowercase:String = Paths.formatToSongPath(songs[curSelected].songName);
			var pipebomb:String = Highscore.formatSong(songLowercase, curDifficulty);
			trace(pipebomb);

			try
			{
				PlayState.SONG = Song.loadFromJson(pipebomb, songLowercase);
				PlayState.isStoryMode = false;
				PlayState.storyDifficulty = curDifficulty;

				trace('CURRENT WEEK: ' + WeekData.getWeekFileName());
			}
			catch(e:Dynamic)
			{
				trace('ERROR! $e');

				var errorStr:String = e.toString();
				if(errorStr.startsWith('[file_contents,assets/data/')) errorStr = 'Missing file: ' + errorStr.substring(27, errorStr.length-1); //Missing chart
				missingText.text = 'ERROR WHILE LOADING CHART:\n$errorStr';
				missingText.screenCenter(Y);
				missingText.visible = true;
				missingTextBG.visible = true;
				FlxG.sound.play(Paths.sound('cancelMenu'));

				super.update(elapsed);
				return;
			}
			CustomFadeTransition.nextCamera = camText;
			grpSongs.forEach(function(spr:FlxText)
			{
				if (curSelected != spr.ID)
				{
					FlxTween.tween(spr, {alpha: 0}, 0.4, {
						ease: FlxEase.quadOut,
						onComplete: function(twn:FlxTween)
						{
							spr.kill();
						}
					});
				}
				else
				{
					FlxFlicker.flicker(spr, 1, 0.06, false, false, function(flick:FlxFlicker)
					{
						LoadingState.loadAndSwitchState(new PlayState());
						FlxG.sound.music.stop();
						FlxG.sound.music.volume = 0;						
						destroyFreeplayVocals();
						#if MODS_ALLOWED
						DiscordClient.loadModRPC();
						#end
					});
				}
			});
		}
		else if(controls.RESET && !player.playingMusic)
		{
			persistentUpdate = false;
			openSubState(new ResetScoreSubState(songs[curSelected].songName, curDifficulty, 'bf'));
			FlxG.sound.play(Paths.sound('scrollMenu'));
		}

		grpSongs.forEach(function(txt:CoolScrollText)
		{
			if (txt.ID == curSelected)
				txt.isSelected = true;
			else
				txt.isSelected = false;
		});

		if (player.playingMusic && !player.paused)
			discThing.angle += 0.2;

		super.update(elapsed);
		callOnLuas('onUpdatePost', [elapsed]);
		callOnScripts('onUpdatePost', [elapsed]);
	}

	public static function destroyFreeplayVocals() {
		if(vocals != null) {
			vocals.stop();
			vocals.destroy();
		}
		vocals = null;
	}

	function changeDiff(change:Int = 0)
	{
		if (player.playingMusic)
			return;

		curDifficulty += change;

		if (curDifficulty < 0)
			curDifficulty = Difficulty.list.length-1;
		if (curDifficulty >= Difficulty.list.length)
			curDifficulty = 0;

		#if !switch
		intendedScore = Highscore.getScore(songs[curSelected].songName, curDifficulty);
		intendedRating = Highscore.getRating(songs[curSelected].songName, curDifficulty);
		#end

		lastDifficultyName = Difficulty.getString(curDifficulty);
		if (Difficulty.list.length > 1)
			diffText.text = '< ' + lastDifficultyName.toUpperCase() + ' >';
		else
			diffText.text = lastDifficultyName.toUpperCase();

		positionHighscore();
		missingText.visible = false;
		missingTextBG.visible = false;
		setOnLuas('curDifficulty', selectedDifficulty);
		callOnLuas('onDifficultyChange', [selectedDifficulty]);

		setOnScripts('curDifficulty', selectedDifficulty);
		callOnScripts('onDifficultyChange', [selectedDifficulty]);
	}

	function changeSelection(change:Int = 0, playSound:Bool = true)
	{
		if (player.playingMusic)
			return;

		_updateSongLastDifficulty();
		if(playSound) FlxG.sound.play(Paths.sound('scrollMenu'), 0.4);

		var lastList:Array<String> = Difficulty.list;
		curSelected += change;

		if (curSelected < 0)
			curSelected = songs.length - 1;
		if (curSelected >= songs.length)
			curSelected = 0;

		var bulltrash:Int = 0;

		for (item in grpSongs.members)
		{
			item.targetY = bulltrash - curSelected;
			bulltrash++;
	
			item.alpha = 0.5;
			if (item.targetY == 0)
			{
				item.alpha = 1;
			}
		}
		
		Mods.currentModDirectory = songs[curSelected].folder;
		PlayState.storyWeek = songs[curSelected].week;
		Difficulty.loadFromWeek();
		
		var savedDiff:String = songs[curSelected].lastDifficulty;
		var lastDiff:Int = Difficulty.list.indexOf(lastDifficultyName);
		if(savedDiff != null && !lastList.contains(savedDiff) && Difficulty.list.contains(savedDiff))
			curDifficulty = Math.round(Math.max(0, Difficulty.list.indexOf(savedDiff)));
		else if(lastDiff > -1)
			curDifficulty = lastDiff;
		else if(Difficulty.list.contains(Difficulty.getDefault()))
			curDifficulty = Math.round(Math.max(0, Difficulty.defaultList.indexOf(Difficulty.getDefault())));
		else
			curDifficulty = 0;

		changeDiff();
		_updateSongLastDifficulty();
		reloadAlbumCover();
		selectedItem = songs[curSelected].songName;
		curAlbum = songs[curSelected].album;
		selectedDifficulty = Difficulty.getString(curDifficulty);
		setOnLuas('curSong', selectedItem);
		setOnLuas('curDifficulty', selectedDifficulty);
		callOnLuas('onSelectionChange', [selectedItem, curAlbum]);

		setOnScripts('curSong', selectedItem);
		setOnScripts('curDifficulty', selectedDifficulty);
		callOnScripts('onSelectionChange', [selectedItem, curAlbum]);
	}

	inline private function _updateSongLastDifficulty()
	{
		songs[curSelected].lastDifficulty = Difficulty.getString(curDifficulty);
	}

	private function positionHighscore() {
		scoreText.x = FlxG.width - scoreText.width - 6;
		scoreBG.scale.x = FlxG.width - scoreText.x + 6;
		scoreBG.x = FlxG.width - (scoreBG.scale.x / 2);
		diffText.x = Std.int(scoreBG.x + (scoreBG.width / 2));
		diffText.x -= diffText.width / 2;
	}

	function reloadAlbumCover() {
		if (songs[curSelected].album == '' || songs[curSelected].album == null)
			albumCover.loadGraphic(Paths.image('albums/blank'));
		else
		{
			#if MODS_ALLOWED
			if (FileSystem.exists('assets/images/albums/' + songs[curSelected].album + '.png') || FileSystem.exists(Paths.modFolders('images/albums/' + songs[curSelected].album + '.png')))
				albumCover.loadGraphic(Paths.image('albums/' + songs[curSelected].album));
			else
				albumCover.loadGraphic(Paths.image('albums/blank'));
			#else
			if (OpenFlAssets.exists(Paths.image('albums/' + songs[curSelected].album)))
				albumCover.loadGraphic(Paths.image('albums/' + songs[curSelected].album));
			else
				albumCover.loadGraphic(Paths.image('albums/blank'));
			#end
		}
		albumCover.setGraphicSize(350);
		albumCover.updateHitbox();
	}

	var _drawDistance:Int = 4;
	var _lastVisibles:Array<Int> = [];

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

	public function callOnLuas(event:String, args:Array<Dynamic>, ignoreStops = true, exclusions:Array<String> = null, excludeValues:Array<Dynamic> = null):Dynamic {
		var returnVal = FreeplayLua.Function_Continue;
		#if LUA_ALLOWED
		if(exclusions == null) exclusions = [];
		if(excludeValues == null) excludeValues = [];

		for (script in luaArray) {
			if(exclusions.contains(script.scriptName))
				continue;

			var myValue = script.call(event, args);
			if(myValue == FreeplayLua.Function_Stop && !ignoreStops)
				break;
			
			if(myValue != null && myValue != FreeplayLua.Function_Continue) {
				returnVal = myValue;
			}
		}
		#end
		return returnVal;
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

	public function getControl(key:String) {
		var pressed:Bool = Reflect.getProperty(controls, key);
		return pressed;
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
			var newScript:HScriptFreeplay = new HScriptFreeplay(null, file);
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
			var newScript:HScriptFreeplay = cast (SScript.global.get(file), HScriptFreeplay);
			if(newScript != null)
			{
				newScript.destroy();
				hscriptArray.remove(newScript);
			}
		}
	}
	#end

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
	
			new FreeplayLua(luaToLoad);
			return true;
		}
		return false;
	}
	#end

	public function callOnScripts(funcToCall:String, args:Array<Dynamic> = null, ignoreStops = false, exclusions:Array<String> = null, excludeValues:Array<Dynamic> = null):Dynamic {
		var returnVal:Dynamic = psychlua.FreeplayLua.Function_Continue;
		if(args == null) args = [];
		if(exclusions == null) exclusions = [];
		if(excludeValues == null) excludeValues = [psychlua.FreeplayLua.Function_Continue];

		var result:Dynamic = callOnLuas(funcToCall, args, ignoreStops, exclusions, excludeValues);
		if(result == null || excludeValues.contains(result)) result = callOnHScript(funcToCall, args, ignoreStops, exclusions, excludeValues);
		return result;
	}

	public function callOnHScript(funcToCall:String, args:Array<Dynamic> = null, ?ignoreStops:Bool = false, exclusions:Array<String> = null, excludeValues:Array<Dynamic> = null):Dynamic {
		var returnVal:Dynamic = psychlua.FreeplayLua.Function_Continue;

		#if HSCRIPT_ALLOWED
		if(exclusions == null) exclusions = new Array();
		if(excludeValues == null) excludeValues = new Array();
		excludeValues.push(psychlua.FreeplayLua.Function_Continue);

		var len:Int = hscriptArray.length;
		if (len < 1)
			return returnVal;
		for(i in 0...len)
		{
			var script:HScriptFreeplay = hscriptArray[i];
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
						FreeplayLua.luaTrace('ERROR (${script.origin}: ${callValue.calledFunction}) - ' + e.message.substr(0, e.message.indexOf('\n')), true, false, FlxColor.RED);
				}
				else
				{
					myValue = callValue.returnValue;
					if((myValue == FreeplayLua.Function_StopHScript || myValue == FreeplayLua.Function_StopAll) && !excludeValues.contains(myValue) && !ignoreStops)
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

	override function destroy() {
		#if LUA_ALLOWED
		for (i in 0...luaArray.length) {
			var lua:FreeplayLua = luaArray[0];
			lua.call('onDestroy', []);
			lua.stop();
		}
		luaArray = [];
		FreeplayLua.customFunctions.clear();
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
		
		instance = null;
		super.destroy();
	}
}

class SongMetadata
{
	public var songName:String = "";
	public var week:Int = 0;
	public var album:String = "";
	public var folder:String = "";
	public var lastDifficulty:String = null;

	public function new(song:String, week:Int, album:String)
	{
		this.songName = song;
		this.week = week;
		this.album = album;
		this.folder = Mods.currentModDirectory;
		if(this.folder == null) this.folder = '';
	}
}