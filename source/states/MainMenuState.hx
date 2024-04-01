package states;

import backend.WeekData;
import backend.Achievements;

import flixel.FlxObject;
import flixel.addons.transition.FlxTransitionableState;
import flixel.effects.FlxFlicker;

import flixel.input.keyboard.FlxKey;
import lime.app.Application;
import flixel.util.FlxSave;

import objects.AchievementPopup;
import states.editors.MasterEditorMenu;
import options.OptionsState;

#if MODS_ALLOWED
import sys.FileSystem;
import sys.io.File;
#end
#if LUA_ALLOWED
import psychlua.*;
#else
import psychlua.MainMenuLua;
import psychlua.LuaUtilsMainMenu;
import psychlua.HScriptMainMenu;
#end

#if (SScript >= "3.0.0" && HSCRIPT_ALLOWED)
import tea.SScript;
#end

class MainMenuState extends MusicBeatState
{
	public var isMainMenuState:Bool = false;
	public var variables:Map<String, Dynamic> = new Map();
	#if HSCRIPT_ALLOWED
	public var hscriptArray:Array<HScriptMainMenu> = [];
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
	public static var psychEngineVersion:String = '2.0.2'; //This is also used for Discord RPC
	public static var curSelected:Int = 0;

	var menuItems:FlxTypedGroup<FlxSprite>;

	public static var instance:MainMenuState;
	public var luaArray:Array<MainMenuLua> = [];
	private var luaDebugGroup:FlxTypedGroup<DebugLuaText>;
	public var camMain:FlxCamera;
	public var camAchievement:FlxCamera;

	public var versionText:FlxText;
	public var funkText:FlxText;
	public var spritesCanTween:Bool = true;

	var charFile:Array<String> = [];
	
	public var itemList:Array<String> = [
		'Story Mode',
		'Freeplay',
		#if MODS_ALLOWED 'Mods', #end
		#if ACHIEVEMENTS_ALLOWED 'Awards', #end
		'Credits',
		'Options'
	];
	
	var optiontrash:Array<String> = [];

	var magenta:FlxSprite;
	public var bg:FlxSprite;

	override function create()
	{
		// for lua
		instance = this;

		#if MODS_ALLOWED
		if (FileSystem.exists(Paths.modFolders('data/playerChars.txt')))
			charFile = CoolUtil.coolTextFile(Paths.modFolders('data/playerChars.txt'));
		else
			charFile = CoolUtil.coolTextFile(Paths.txt('playerChars'));
		#else
		charFile = CoolUtil.coolTextFile(Paths.txt('playerChars'));
		#end

		if (charFile.length < 3 && ClientPrefs.data.playerChar != 1)
			ClientPrefs.data.playerChar = 1;

		#if MODS_ALLOWED
		Mods.pushGlobalMods();
		#end
		Mods.loadTopMod();

		#if desktop
		// Updating Discord Rich Presence
		DiscordClient.changePresence("In the Menus", null);
		#end

		camMain = new FlxCamera();
		camAchievement = new FlxCamera();
		camAchievement.bgColor.alpha = 0;

		FlxG.cameras.reset(camMain);
		FlxG.cameras.add(camAchievement, false);
		FlxG.cameras.setDefaultDrawTarget(camMain, true);

		transIn = FlxTransitionableState.defaultTransIn;
		transOut = FlxTransitionableState.defaultTransOut;
		CustomFadeTransition.nextCamera = camAchievement;

		persistentUpdate = persistentDraw = true;

		#if LUA_ALLOWED
		luaDebugGroup = new FlxTypedGroup<DebugLuaText>();
		luaDebugGroup.cameras = [camAchievement];
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
					if(file.endsWith('mainmenu.lua') && !filesPushed.contains(file))
					{
						luaArray.push(new MainMenuLua(folder + file));
						filesPushed.push(file);
					}
				}
			}
		}
		#end

		for (i in itemList)
			formatItemList(i);

		bg = new FlxSprite().loadGraphic(Paths.image('menuBG'));
		bg.antialiasing = ClientPrefs.data.antialiasing;
		bg.updateHitbox();
		bg.screenCenter();
		add(bg);

		magenta = new FlxSprite().loadGraphic(Paths.image('menuDesat'));
		magenta.antialiasing = ClientPrefs.data.antialiasing;
		magenta.updateHitbox();
		magenta.screenCenter();
		magenta.visible = false;
		magenta.color = 0xFFfd719b;
		add(magenta);

		menuItems = new FlxTypedGroup<FlxSprite>();
		add(menuItems);

		var logoBl:FlxSprite = new FlxSprite(700, -75);
		logoBl.frames = Paths.getSparrowAtlas('logoBumpin');
		logoBl.antialiasing = ClientPrefs.data.antialiasing;
		logoBl.animation.addByPrefix('bump', 'logo bumpin', 24, true);
		logoBl.animation.play('bump');
		logoBl.setGraphicSize(Std.int(logoBl.width * 0.7));
		logoBl.updateHitbox();
		add(logoBl);

		var scale:Float = 0.6;

		for (i in 0...optiontrash.length)
		{
			var tweentime:Float = 0.2 * (i + 1);
			var menuItem:FlxSprite = new FlxSprite(0, (i * 121) + 7);
			menuItem.antialiasing = ClientPrefs.data.antialiasing;
			menuItem.scale.x = scale;
			menuItem.scale.y = scale;
			menuItem.frames = Paths.getSparrowAtlas('mainmenu/menu_' + optiontrash[i]);
			menuItem.animation.addByPrefix('idle', optiontrash[i] + " basic", 24);
			menuItem.animation.addByPrefix('selected', optiontrash[i] + " white", 24);
			menuItem.animation.play('idle');
			menuItems.add(menuItem);
			menuItem.ID = i;
			menuItem.updateHitbox();
		}

		versionText = new FlxText(-12, FlxG.height - 44, FlxG.width, "Psych Engine DS v" + psychEngineVersion, 12);
		versionText.scrollFactor.set();
		versionText.setFormat("VCR OSD Mono", 16, FlxColor.WHITE, RIGHT, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		versionText.cameras = [camAchievement];
		add(versionText);
		funkText = new FlxText(-12, FlxG.height - 24, FlxG.width, "Friday Night Funkin' v" + Application.current.meta.get('version'), 12);
		funkText.scrollFactor.set();
		funkText.setFormat("VCR OSD Mono", 16, FlxColor.WHITE, RIGHT, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		funkText.cameras = [camAchievement];
		add(funkText);

		#if ACHIEVEMENTS_ALLOWED
		// Unlocks "Freaky on a Friday Night" achievement if it's a Friday and between 6:00 PM and 11:59 PM
		var leDate = Date.now();
		if (leDate.getDay() == 5 && leDate.getHours() >= 18)
			Achievements.unlock('friday_night_play');

		#if MODS_ALLOWED
		Achievements.reloadList();
		#end
		#end

		callOnLuas('onCreatePost', []);
		callOnScripts('onCreatePost', []);

		changeItem();

		super.create();
	}

	var selectedSomethin:Bool = false;

	override function update(elapsed:Float)
	{
		callOnLuas('onUpdate', [elapsed]);
		callOnScripts('onUpdate', [elapsed]);
		if (FlxG.sound.music.volume < 0.8)
		{
			FlxG.sound.music.volume += 0.5 * elapsed;
			if(FreeplayState.vocals != null) FreeplayState.vocals.volume += 0.5 * elapsed;
		}
		FlxG.camera.followLerp = FlxMath.bound(elapsed * 9 / (FlxG.updateFramerate / 60), 0, 1);

		if (!selectedSomethin)
		{
			if (controls.UI_UP_P)
			{
				FlxG.sound.play(Paths.sound('scrollMenu'));
				changeItem(-1);
			}

			if (controls.UI_DOWN_P)
			{
				FlxG.sound.play(Paths.sound('scrollMenu'));
				changeItem(1);
			}

			if (controls.BACK)
			{
				CustomFadeTransition.nextCamera = camAchievement;
				selectedSomethin = true;
				FlxG.sound.play(Paths.sound('cancelMenu'));
				MusicBeatState.switchState(new TitleState());
			}

			if (controls.ACCEPT)
			{
				callOnLuas('onItemSelected', [itemList[curSelected]]);
				callOnScripts('onItemSelected', [itemList[curSelected]]);

				selectedSomethin = true;
				FlxG.sound.play(Paths.sound('confirmMenu'));

				if(ClientPrefs.data.flashing) FlxFlicker.flicker(magenta, 1.1, 0.15, false);

				menuItems.forEach(function(spr:FlxSprite)
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
							CustomFadeTransition.nextCamera = camAchievement;
							var daChoice:String = optiontrash[curSelected];

							switch (daChoice)
							{
								case 'story_mode':
									MusicBeatState.switchState(new StoryMenuState());
								case 'freeplay':
									MusicBeatState.switchState(new FreeplayState());
								#if MODS_ALLOWED
								case 'mods':
									MusicBeatState.switchState(new ModsMenuState());
								#end
								case 'awards':
									MusicBeatState.switchState(new AchievementsMenuState());
								case 'credits':
									MusicBeatState.switchState(new CreditsState());
								case 'options':
									LoadingState.loadAndSwitchState(new OptionsState());
									OptionsState.onPlayState = false;
									if (PlayState.SONG != null)
									{
										PlayState.SONG.arrowSkin = null;
										PlayState.SONG.splashSkin = null;
									}
							}
						});
					}
				});
			}
			#if desktop
			else if (controls.justPressed('debug_1'))
			{
				CustomFadeTransition.nextCamera = camAchievement;
				selectedSomethin = true;
				MusicBeatState.switchState(new MasterEditorMenu());
			}
			#end
		}

		super.update(elapsed);

		callOnLuas('onUpdatePost', [elapsed]);
		callOnScripts('onUpdatePost', [elapsed]);
	}

	function changeItem(huh:Int = 0)
	{
		curSelected += huh;

		if (curSelected >= menuItems.length)
			curSelected = 0;
		if (curSelected < 0)
			curSelected = menuItems.length - 1;

		setOnLuas('curSelected', curSelected);
		callOnLuas('onSelectionChange', [itemList[curSelected]]);

		setOnScripts('curSelected', curSelected);
		callOnScripts('onSelectionChange', [itemList[curSelected]]);

		menuItems.forEach(function(spr:FlxSprite)
		{
			spr.animation.play('idle');
			spr.updateHitbox();

			if (spr.ID == curSelected)
			{
				spr.animation.play('selected');
				if (spritesCanTween) FlxTween.tween(spr, {x: 130}, 0.1, {ease: FlxEase.linear});
				var add:Float = 0;
				if(menuItems.length > 4) {
					add = menuItems.length * 8;
				}
			}
			else
				if (spritesCanTween) FlxTween.tween(spr, {x: 0}, 0.1, {ease: FlxEase.linear});
		});
	}

	function formatItemList(item:String) {
		var invalidChars = ~/[~&\\;:<>#]/;
		var hideChars = ~/[.,'"%?!]/;

		var item = invalidChars.split(item.replace(' ', '_')).join("_");
		optiontrash.push(hideChars.split(item).join("").toLowerCase());
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

	public function callOnLuas(event:String, args:Array<Dynamic>, ignoreStops = true, exclusions:Array<String> = null, excludeValues:Array<Dynamic> = null):Dynamic {
		var returnVal = MainMenuLua.Function_Continue;
		#if LUA_ALLOWED
		if(exclusions == null) exclusions = [];
		if(excludeValues == null) excludeValues = [];

		for (script in luaArray) {
			if(exclusions.contains(script.scriptName))
				continue;

			var myValue = script.call(event, args);
			if(myValue == MainMenuLua.Function_Stop && !ignoreStops)
				break;
			
			if(myValue != null && myValue != MainMenuLua.Function_Continue) {
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
			var newScript:HScriptMainMenu = new HScriptMainMenu(null, file);
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
			var newScript:HScriptMainMenu = cast (SScript.global.get(file), HScriptMainMenu);
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
	
			new MainMenuLua(luaToLoad);
			return true;
		}
		return false;
	}
	#end

	public function callOnScripts(funcToCall:String, args:Array<Dynamic> = null, ignoreStops = false, exclusions:Array<String> = null, excludeValues:Array<Dynamic> = null):Dynamic {
		var returnVal:Dynamic = psychlua.MainMenuLua.Function_Continue;
		if(args == null) args = [];
		if(exclusions == null) exclusions = [];
		if(excludeValues == null) excludeValues = [psychlua.MainMenuLua.Function_Continue];

		var result:Dynamic = callOnLuas(funcToCall, args, ignoreStops, exclusions, excludeValues);
		if(result == null || excludeValues.contains(result)) result = callOnHScript(funcToCall, args, ignoreStops, exclusions, excludeValues);
		return result;
	}

	public function callOnHScript(funcToCall:String, args:Array<Dynamic> = null, ?ignoreStops:Bool = false, exclusions:Array<String> = null, excludeValues:Array<Dynamic> = null):Dynamic {
		var returnVal:Dynamic = psychlua.MainMenuLua.Function_Continue;

		#if HSCRIPT_ALLOWED
		if(exclusions == null) exclusions = new Array();
		if(excludeValues == null) excludeValues = new Array();
		excludeValues.push(psychlua.MainMenuLua.Function_Continue);

		var len:Int = hscriptArray.length;
		if (len < 1)
			return returnVal;
		for(i in 0...len)
		{
			var script:HScriptMainMenu = hscriptArray[i];
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
						MainMenuLua.luaTrace('ERROR (${script.origin}: ${callValue.calledFunction}) - ' + e.message.substr(0, e.message.indexOf('\n')), true, false, FlxColor.RED);
				}
				else
				{
					myValue = callValue.returnValue;
					if((myValue == MainMenuLua.Function_StopHScript || myValue == MainMenuLua.Function_StopAll) && !excludeValues.contains(myValue) && !ignoreStops)
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
			var lua:MainMenuLua = luaArray[0];
			lua.call('onDestroy', []);
			lua.stop();
		}
		luaArray = [];
		MainMenuLua.customFunctions.clear();
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
