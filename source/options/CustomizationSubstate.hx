package options;

import objects.Note;
import objects.StrumNote;
import objects.Alphabet;

class CustomizationSubstate extends BaseOptionsMenu
{
	var noteOptionID:Int = -1;
	var notes:FlxTypedGroup<StrumNote>;
	var notesTween:Array<FlxTween> = [];
	var noteY:Float = 90;
	var splashX:Float = 850;
	var comboX:Float = 850;
	var barX:Float = 720;

	var splashOption:Int;
	var uiOption:Int;
	var barOption:Int;

	var splashSpr:FlxSprite;
	var comboSpr:FlxSprite;
	var barSpr:FlxSprite;

	public function new()
	{
		title = 'Customization';
		rpcTitle = 'Customization Settings Menu'; //for Discord Rich Presence

		// for note skins
		notes = new FlxTypedGroup<StrumNote>();
		for (i in 0...Note.colArray.length)
		{
			var note:StrumNote = new StrumNote(370 + (560 / Note.colArray.length) * i, -200, i, 0);
			note.centerOffsets();
			note.centerOrigin();
			note.playAnim('static');
			notes.add(note);
		}

		// for splash skins
		splashSpr = new FlxSprite(1300, 240);
		splashSpr.frames = Paths.getSparrowAtlas('noteSplashes/' + ClientPrefs.data.splashSkin);
		splashSpr.animation.addByIndices('idle', "", [0], "", 24);
		splashSpr.animation.play('idle');
		splashSpr.setGraphicSize(Std.int(splashSpr.width * 0.85));
		splashSpr.updateHitbox();

		// for hud thing
		comboSpr = new FlxSprite(1300, 380).loadGraphic(Paths.image('hudFolders/' + ClientPrefs.data.comboHUDDir + 'UI/sick'));
		comboSpr.setGraphicSize(Std.int(comboSpr.width * 0.85));
		comboSpr.updateHitbox();

		// for bar thing
		barSpr = new FlxSprite(1300, 391).loadGraphic(Paths.image('bars/healthBar-' + ClientPrefs.data.healthAndTimeBars));
		barSpr.setGraphicSize(Std.int(barSpr.width * 0.9));
		barSpr.updateHitbox();

		// options

		var noteSkins:Array<String> = Mods.mergeAllTextsNamed('images/noteSkins/list.txt', 'shared');
		if(noteSkins.length > 0)
		{
			if(!noteSkins.contains(ClientPrefs.data.noteSkin))
				ClientPrefs.data.noteSkin = ClientPrefs.defaultData.noteSkin; //Reset to default if saved noteskin couldnt be found

			noteSkins.insert(0, ClientPrefs.defaultData.noteSkin); //Default skin always comes first
			var option:Option = new Option('Note Skins:',
				"Select your prefered Note skin.",
				'noteSkin',
				'string',
				noteSkins);
			addOption(option);
			option.onChange = onChangeNoteSkin;
			noteOptionID = optionsArray.length - 1;
		}
		
		var noteSplashes:Array<String> = Mods.mergeAllTextsNamed('images/noteSplashes/list.txt', 'shared');
		if(noteSplashes.length > 0)
		{
			if(!noteSplashes.contains(ClientPrefs.data.splashSkin))
				ClientPrefs.data.splashSkin = ClientPrefs.defaultData.splashSkin; //Reset to default if saved splashskin couldnt be found

			noteSplashes.insert(0, ClientPrefs.defaultData.splashSkin); //Default skin always comes first
			var option:Option = new Option('Note Splashes:',
				"Select your prefered Note Splash variation or turn it off.",
				'splashSkin',
				'string',
				noteSplashes);
			addOption(option);
			option.onChange = changeSplashSkin;
			splashOption = optionsArray.length-1;
		}

		var hudFolders:Array<String> = Mods.mergeAllTextsNamed('images/hudFolders/list.txt', 'shared');
		if(hudFolders.length > 0)
		{
			if(!hudFolders.contains(ClientPrefs.data.comboHUDDir))
				ClientPrefs.data.comboHUDDir = ClientPrefs.defaultData.comboHUDDir; //Reset to default if saved hud folder couldnt be found

			hudFolders.insert(0, ClientPrefs.defaultData.comboHUDDir); //Default hud always comes first
			var option:Option = new Option('Combo Sprites:',
				"Select your prefered Combo & Rating Sprites.",
				'comboHUDDir',
				'string',
				hudFolders);
			addOption(option);
			uiOption = optionsArray.length-1;
			option.onChange = changeUI;
		}

		var barsList:Array<String> = Mods.mergeAllTextsNamed('images/bars/list.txt', 'shared');
		if(barsList.length > 0)
		{
			if(!barsList.contains(ClientPrefs.data.healthAndTimeBars))
				ClientPrefs.data.healthAndTimeBars = ClientPrefs.defaultData.healthAndTimeBars; //Reset to default if saved bar skin couldnt be found

			barsList.insert(0, ClientPrefs.defaultData.healthAndTimeBars); //Default bar always comes first
			var option:Option = new Option('Bar Skin:',
				"Select your prefered Combo & Rating Sprites.",
				'healthAndTimeBars',
				'string',
				barsList);
			addOption(option);
			option.onChange = changeBar;
			barOption = optionsArray.length-1;
		}

		var dsBorders:Array<String> = Mods.mergeAllTextsNamed('images/DS-Filters/list.txt', 'shared');
		if(dsBorders.length > 0)
		{
			if(!dsBorders.contains(ClientPrefs.data.dsBorder))
				ClientPrefs.data.dsBorder = ClientPrefs.defaultData.dsBorder; //Reset to default if saved splashskin couldnt be found

			dsBorders.insert(0, ClientPrefs.defaultData.dsBorder); //Default skin always comes first
			var option:Option = new Option('DS Filter Border:',
				"Select your prefered DS Border or turn it off. (Doesn't apply if DS Filter is off)",
				'dsBorder',
				'string',
				dsBorders);
			addOption(option);
		}

		super();
		add(notes);
		insert(1, splashSpr);
		insert(1, comboSpr);
		insert(1, barSpr);
	}

	override function changeSelection(change:Int = 0)
	{
		super.changeSelection(change);
		
		if(noteOptionID < 0) return;

		for (i in 0...Note.colArray.length)
		{
			var note:StrumNote = notes.members[i];
			if(notesTween[i] != null) notesTween[i].cancel();
			if(curSelected == noteOptionID)
				notesTween[i] = FlxTween.tween(note, {y: noteY}, Math.abs(note.y / (200 + noteY)) / 3, {ease: FlxEase.quadInOut});
			else
				notesTween[i] = FlxTween.tween(note, {y: -200}, Math.abs(note.y / (200 + noteY)) / 3, {ease: FlxEase.quadInOut});
		}
		if (curSelected == splashOption)
			FlxTween.tween(splashSpr, {x: splashX}, 0.1, {ease: FlxEase.quadInOut});
		else
			FlxTween.tween(splashSpr, {x: 1300}, 0.1, {ease: FlxEase.quadInOut});
		if (curSelected == uiOption)
			FlxTween.tween(comboSpr, {x: comboX}, 0.1, {ease: FlxEase.quadInOut});
		else
			FlxTween.tween(comboSpr, {x: 1300}, 0.1, {ease: FlxEase.quadInOut});
		if (curSelected == barOption)
			FlxTween.tween(barSpr, {x: barX}, 0.1, {ease: FlxEase.quadInOut});
		else
			FlxTween.tween(barSpr, {x: 1300}, 0.1, {ease: FlxEase.quadInOut});
	}

	function onChangeNoteSkin()
	{
		notes.forEachAlive(function(note:StrumNote) {
			changeNoteSkin(note);
			note.centerOffsets();
			note.centerOrigin();
		});
	}

	function changeNoteSkin(note:StrumNote)
	{
		var skin:String = ClientPrefs.data.noteSkin;
		var customSkin:String = 'noteSkins/' + skin;
		if(Paths.fileExists('images/$customSkin.png', IMAGE)) skin = customSkin;

		note.texture = skin; //Load texture and anims
		note.reloadNote();
		note.playAnim('static');
	}

	function changeSplashSkin()
	{
		splashSpr.frames = Paths.getSparrowAtlas('noteSplashes/' + ClientPrefs.data.splashSkin);
		splashSpr.animation.addByIndices('idle', "", [0], "", 24);
		splashSpr.animation.play('idle');
	}

	function changeUI()
	{
		comboSpr.loadGraphic(Paths.image('hudFolders/' + ClientPrefs.data.comboHUDDir + 'UI/sick'));
	}

	function changeBar()
	{
		barSpr.loadGraphic(Paths.image('bars/healthBar-' + ClientPrefs.data.healthAndTimeBars));
	}
}
