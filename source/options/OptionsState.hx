package options;

import states.MainMenuState;
import backend.StageData;
#if MODS_ALLOWED
import sys.FileSystem;
#end

class OptionsState extends MusicBeatState
{
	var charFile:Array<String> = [];
	
	var options:Array<String> = ['Note Colors', 'Controls', 'Adjust Delay and Combo', 'Graphics', 'Customization', 'Visuals and UI', 'Gameplay', 'Choose Player Character'];
	private var grpOptions:FlxTypedGroup<Alphabet>;
	private static var curSelected:Int = 0;
	public static var menuBG:FlxSprite;
	public static var onPlayState:Bool = false;

	function openSelectedSubstate(label:String) {
		switch(label) {
			case 'Note Colors':
				openSubState(new options.NotesSubState());
			case 'Controls':
				openSubState(new options.ControlsSubState());
			case 'Graphics':
				openSubState(new options.GraphicsSettingsSubState());
			case 'Customization':
				openSubState(new options.CustomizationSubstate());
			case 'Visuals and UI':
				openSubState(new options.VisualsUISubState());
			case 'Gameplay':
				openSubState(new options.GameplaySettingsSubState());
			case 'Adjust Delay and Combo':
				MusicBeatState.switchState(new options.NoteOffsetState());
			case 'Choose Player Character':
				openSubState(new options.PlayerSelectMenu());
		}
	}

	var selectorLeft:Alphabet;
	var selectorRight:Alphabet;

	override function create() {
		#if MODS_ALLOWED
		if (FileSystem.exists(Paths.modFolders('data/playerChars.txt')))
			charFile = CoolUtil.coolTextFile(Paths.modFolders('data/playerChars.txt'));
		else
			charFile = CoolUtil.coolTextFile(Paths.txt('playerChars'));
		#else
		charFile = CoolUtil.coolTextFile(Paths.txt('playerChars'));
		#end

		if (charFile.length <= 1 || onPlayState)
			options = ['Note Colors', 'Controls', 'Adjust Delay and Combo', 'Graphics', 'Customization', 'Visuals and UI', 'Gameplay'];
		#if desktop
		DiscordClient.changePresence("Options Menu", null);
		#end

		var bg:FlxSprite = new FlxSprite().loadGraphic(Paths.image('menuDesat'));
		bg.antialiasing = ClientPrefs.data.antialiasing;
		bg.color = 0xFFea71fd;
		bg.updateHitbox();

		bg.screenCenter();
		add(bg);

		grpOptions = new FlxTypedGroup<Alphabet>();
		add(grpOptions);

		for (i in 0...options.length)
		{
			var optionText:Alphabet = new Alphabet(0, 0, options[i], true);
			optionText.setScale(0.9 * TitleState.alphabetScale);
			optionText.screenCenter();
			optionText.y += (90 * (i - (options.length / 2))) + 50;
			grpOptions.add(optionText);
		}

		selectorLeft = new Alphabet(0, 0, '>', true);
		selectorLeft.setScale(0.9 * TitleState.alphabetScale);
		add(selectorLeft);
		selectorRight = new Alphabet(0, 0, '<', true);
		selectorRight.setScale(0.9 * TitleState.alphabetScale);
		add(selectorRight);

		changeSelection();
		ClientPrefs.saveSettings();

		super.create();
	}

	override function closeSubState() {
		super.closeSubState();
		ClientPrefs.saveSettings();
	}

	override function update(elapsed:Float) {
		super.update(elapsed);

		if (controls.UI_UP_P) {
			changeSelection(-1);
		}
		if (controls.UI_DOWN_P) {
			changeSelection(1);
		}

		if (controls.BACK) {
			FlxG.sound.play(Paths.sound('cancelMenu'));
			if(onPlayState)
			{
				StageData.loadDirectory(PlayState.SONG);
				LoadingState.loadAndSwitchState(new PlayState());
				FlxG.sound.music.volume = 0;
			}
			else MusicBeatState.switchState(new MainMenuState());
		}
		else if (controls.ACCEPT) openSelectedSubstate(options[curSelected]);
	}
	
	function changeSelection(change:Int = 0) {
		curSelected += change;
		if (curSelected < 0)
			curSelected = options.length - 1;
		if (curSelected >= options.length)
			curSelected = 0;

		var bulltrash:Int = 0;

		for (item in grpOptions.members) {
			item.targetY = bulltrash - curSelected;
			bulltrash++;

			item.alpha = 0.6;
			if (item.targetY == 0) {
				item.alpha = 1;
				selectorLeft.x = item.x - 63;
				selectorLeft.y = item.y;
				selectorRight.x = item.x + item.width + 15;
				selectorRight.y = item.y;
			}
		}
		FlxG.sound.play(Paths.sound('scrollMenu'));
	}

	override function destroy()
	{
		ClientPrefs.loadPrefs();
		super.destroy();
	}
}