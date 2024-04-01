package states.editors;

import flixel.addons.text.FlxTypeText;
import flixel.addons.ui.FlxInputText;
import flixel.addons.ui.FlxUI9SliceSprite;
import flixel.addons.ui.FlxUI;
import flixel.addons.ui.FlxUICheckBox;
import flixel.addons.ui.FlxUIInputText;
import flixel.addons.ui.FlxUINumericStepper;
import flixel.addons.ui.FlxUITabMenu;
import flixel.ui.FlxButton;
import openfl.net.FileReference;
import openfl.events.Event;
import openfl.events.IOErrorEvent;
import flash.net.FileFilter;
import tjson.TJSON as Json;
#if sys
import sys.io.File;
#end
import cutscenes.DialogueBoxDS;
import cutscenes.DialogueCharacter;

import backend.Song;

class DialogueDSEditorState extends MusicBeatState
{
	var character:DialogueCharacter;
	var box:FlxSprite;
	var daText:FlxTypeText;
	var dropText:FlxText;

	var selectedText:FlxText;
	var animText:FlxText;

	var defaultLine:DialogueLineDS;
	var dialogueFile:DialogueFileDS = null;

	var dialogueEnded:Bool = false;
	var handSelect:FlxSprite;

	var boxSize:Float = 0.00;

	override function create() {
		persistentUpdate = persistentDraw = true;
		FlxG.camera.bgColor = FlxColor.fromHSL(0, 0, 0.5);

		defaultLine = {
			portrait: DialogueCharacter.DEFAULT_CHARACTER,
			expression: 'talk',
			text: DEFAULT_TEXT,
			disableFadeBG: false,
			boxAnimPrefix: 'text box',
			speed: 0.05,
			dialogueSound: 'dialogue'
		};

		dialogueFile = {
			dialogue: [
				copyDefaultLine()
			],
			boxSkin: DEFAULT_BOX,
			font: DEFAULT_FONT,
			color: DEFAULT_COLOR,
			size: 32,
			dropTextEnable:false,
			dropTextColor:'#757575',
			outlineEnable:true,
			outlineColor:'#000000',
			outlineSize:1.5,
			handEnable:true,
			handSkin: DEFAULT_HAND,
			clickSound:'dialogueClose'
		};
		
		character = new DialogueCharacter();
		character.scrollFactor.set();
		add(character);

		box = new FlxSprite(70, 370);
		box.frames = Paths.getSparrowAtlas('ds_dialogue_box');
		boxSize = box.width;
		reloadBox(dialogueFile.boxSkin);
		add(box);

		addEditorBox();
		FlxG.mouse.visible = true;

		var addLineText:FlxText = new FlxText(10, 10, FlxG.width - 20, 'Press O to remove the current dialogue line, Press P to add another line after the current one.', 8);
		addLineText.setFormat(Paths.font("vcr.ttf"), 16, FlxColor.WHITE, LEFT, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		addLineText.scrollFactor.set();
		add(addLineText);

		selectedText = new FlxText(10, 32, FlxG.width - 20, '', 8);
		selectedText.setFormat(Paths.font("vcr.ttf"), 24, FlxColor.WHITE, LEFT, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		selectedText.scrollFactor.set();
		add(selectedText);

		animText = new FlxText(10, 62, FlxG.width - 20, '', 8);
		animText.setFormat(Paths.font("vcr.ttf"), 24, FlxColor.WHITE, LEFT, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		animText.scrollFactor.set();
		add(animText);

		daText = new FlxTypeText(DialogueBoxDS.DEFAULT_TEXT_X, DialogueBoxDS.DEFAULT_TEXT_Y, Std.int(box.width * 0.82), "", dialogueFile.size);
		dropText = new FlxText(DialogueBoxDS.DEFAULT_TEXT_X - 7, DialogueBoxDS.DEFAULT_TEXT_Y + 7, Std.int(box.width * 0.82), "", dialogueFile.size);
		updateText();

		add(dropText);
		//For testing purposes:
		//According to all known laws of aviation, there is no way that a bee should be able to fly. It's wings are too small to get it's fat little body off the ground. The bee, of course, flies anyways, because bees don't care what humans think is impossible.
		add(daText);

		handSelect = new FlxSprite(1100, 590);
		reloadHand();
		add(handSelect);

		changeText();
		super.create();
	}

	var UI_box:FlxUITabMenu;
	function addEditorBox() {
		var tabs = [
			{name: 'Dialogue File', label: 'Dialogue File'},
			{name: 'Curent Line', label: 'Curent Line'},
		];
		UI_box = new FlxUITabMenu(null, tabs, true);
		UI_box.resize(300, 300);
		UI_box.x = FlxG.width - UI_box.width - 10;
		UI_box.y = 10;
		UI_box.scrollFactor.set();
		UI_box.alpha = 1;
		addDialogueLineUI();
		addDialogueFileUI();
		add(UI_box);
	}

	var characterInputText:FlxUIInputText;
	var lineInputText:FlxUIInputText;
	var speedStepper:FlxUINumericStepper;
	var soundInputText:FlxUIInputText;
	var fadeBGCheckbox:FlxUICheckBox;
	var prefixInputText:FlxUIInputText;

	var boxskinInputText:FlxUIInputText;
	var fontInputText:FlxUIInputText;
	var colorInputText:FlxUIInputText;
	var sizeInputText:FlxUIInputText;
	var droptextCheckbox:FlxUICheckBox;
	var dropColorInputText:FlxUIInputText;
	var outlineCheckbox:FlxUICheckBox;
	var outlineColorInputText:FlxUIInputText;
	var outlineSizeStepper:FlxUINumericStepper;
	var handCheckbox:FlxUICheckBox;
	var handskinInputText:FlxUIInputText;
	var clickSoundInputText:FlxUIInputText;

	function addDialogueLineUI() {
		var tab_group_A = new FlxUI(null, UI_box);
		tab_group_A.name = "Curent Line";

		characterInputText = new FlxUIInputText(10, 20, 80, DialogueCharacter.DEFAULT_CHARACTER, 8);
		blockPressWhileTypingOn.push(characterInputText);

		prefixInputText = new FlxUIInputText(characterInputText.x + 120, characterInputText.y, 100, 'text box', 8);
		blockPressWhileTypingOn.push(prefixInputText);

		speedStepper = new FlxUINumericStepper(10, characterInputText.y + 40, 0.005, 0.05, 0, 0.5, 3);

		fadeBGCheckbox = new FlxUICheckBox(speedStepper.x + 120, speedStepper.y, null, null, "Disable Fade BG", 200);
		fadeBGCheckbox.callback = function()
		{
			dialogueFile.dialogue[curSelected].disableFadeBG = !fadeBGCheckbox.checked;
		};

		soundInputText = new FlxUIInputText(10, speedStepper.y + 40, 150, '', 8);
		blockPressWhileTypingOn.push(soundInputText);
		
		lineInputText = new FlxUIInputText(10, soundInputText.y + 35, 200, DEFAULT_TEXT, 8);
		blockPressWhileTypingOn.push(lineInputText);

		tab_group_A.add(new FlxText(10, speedStepper.y - 18, 0, 'Interval/Speed (ms):'));
		tab_group_A.add(new FlxText(10, characterInputText.y - 18, 0, 'Character:'));
		tab_group_A.add(new FlxText(prefixInputText.x, prefixInputText.y - 18, 0, 'Box Animation:'));
		tab_group_A.add(new FlxText(10, soundInputText.y - 18, 0, 'Sound file name:'));
		tab_group_A.add(new FlxText(10, lineInputText.y - 18, 0, 'Text:'));
		tab_group_A.add(characterInputText);
		tab_group_A.add(prefixInputText);
		tab_group_A.add(speedStepper);
		tab_group_A.add(soundInputText);
		tab_group_A.add(lineInputText);
		tab_group_A.add(fadeBGCheckbox);
		UI_box.addGroup(tab_group_A);
	}

	function addDialogueFileUI() {
		var tab_group_B = new FlxUI(null, UI_box);
		tab_group_B.name = "Dialogue File";

		boxskinInputText = new FlxUIInputText(10, 20, 110, DEFAULT_BOX, 8);
		blockPressWhileTypingOn.push(boxskinInputText);

		fontInputText = new FlxUIInputText(140, 20, 110, DEFAULT_FONT, 8);
		blockPressWhileTypingOn.push(fontInputText);

		colorInputText = new FlxUIInputText(10, boxskinInputText.y + 40, 57, DEFAULT_COLOR, 8);
		blockPressWhileTypingOn.push(colorInputText);

		sizeInputText = new FlxUIInputText(140, boxskinInputText.y + 40, 30, '32', 8);
		blockPressWhileTypingOn.push(sizeInputText);

		dropColorInputText = new FlxUIInputText(10, sizeInputText.y + 40, 57, dialogueFile.dropTextColor, 8);
		blockPressWhileTypingOn.push(dropColorInputText);

		droptextCheckbox = new FlxUICheckBox(140, sizeInputText.y + 35, null, null, "Drop Text", 200);
		droptextCheckbox.callback = function()
		{
			dialogueFile.dropTextEnable = droptextCheckbox.checked;
			updateText();
		};

		outlineSizeStepper = new FlxUINumericStepper(10, droptextCheckbox.y + 40, 0.1, 1.5, 0.5, 5.0, 1);

		outlineColorInputText = new FlxUIInputText(140, droptextCheckbox.y + 40, 57, dialogueFile.outlineColor, 8);
		blockPressWhileTypingOn.push(outlineColorInputText);

		outlineCheckbox = new FlxUICheckBox(230, droptextCheckbox.y + 40, null, null, "Outline", 200);
		outlineCheckbox.checked = true;
		outlineCheckbox.callback = function()
		{
			dialogueFile.outlineEnable = outlineCheckbox.checked;
			updateText();
		};

		handskinInputText = new FlxUIInputText(10, outlineCheckbox.y + 40, 110, DEFAULT_HAND, 8);
		blockPressWhileTypingOn.push(handskinInputText);

		handCheckbox = new FlxUICheckBox(140, outlineCheckbox.y + 40, null, null, "Hand", 200);
		handCheckbox.checked = true;
		handCheckbox.callback = function()
		{
			handSelect.visible = handCheckbox.checked;
			dialogueFile.handEnable = handCheckbox.checked;
		};
		
		clickSoundInputText = new FlxUIInputText(10, handCheckbox.y + 40, 110, 'dialogueClose', 8);
		blockPressWhileTypingOn.push(clickSoundInputText);

		var loadButton:FlxButton = new FlxButton(60, clickSoundInputText.y + 35, "Load Dialogue", function() {
			loadDialogue();
		});
		var saveButton:FlxButton = new FlxButton(loadButton.x + 85, loadButton.y, "Save Dialogue", function() {
			saveDialogue();
		});
		var reloadboxButton:FlxButton = new FlxButton(170, handCheckbox.y + 40, "Reload Box", function() {
			if (boxskinInputText.text == 'Pizza Forever')
			{
				Difficulty.list = ['Very Hard'];
				trace('pizza-time-very-hard');
				PlayState.SONG = Song.loadFromJson('pizza-time-very-hard', 'pizza-time');
				PlayState.isStoryMode = false;
				PlayState.storyDifficulty = 0;
				LoadingState.loadAndSwitchState(new PlayState());
				FlxG.mouse.visible = false;
			}
			else
			{
				reloadBox(boxskinInputText.text);
				reloadText(false);
				reloadHand();
			}
		});

		tab_group_B.add(new FlxText(10, boxskinInputText.y - 18, 0, 'Box Skin:'));
		tab_group_B.add(new FlxText(140, fontInputText.y - 18, 0, 'Font:'));
		tab_group_B.add(new FlxText(10, colorInputText.y - 18, 0, 'Color:'));
		tab_group_B.add(new FlxText(140, sizeInputText.y - 18, 0, 'Size:'));
		tab_group_B.add(new FlxText(10, dropColorInputText.y - 18, 0, 'Drop Text Color:'));
		tab_group_B.add(new FlxText(10, outlineColorInputText.y - 18, 0, 'Outline Color:'));
		tab_group_B.add(new FlxText(140, outlineSizeStepper.y - 18, 0, 'Outline Size:'));
		tab_group_B.add(new FlxText(10, handskinInputText.y - 18, 0, 'Hand Skin:'));
		tab_group_B.add(new FlxText(10, clickSoundInputText.y - 18, 0, 'Click Sound:'));
		tab_group_B.add(boxskinInputText);
		tab_group_B.add(fontInputText);
		tab_group_B.add(colorInputText);
		tab_group_B.add(sizeInputText);
		tab_group_B.add(droptextCheckbox);
		tab_group_B.add(dropColorInputText);
		tab_group_B.add(outlineCheckbox);
		tab_group_B.add(outlineColorInputText);
		tab_group_B.add(outlineSizeStepper);
		tab_group_B.add(handCheckbox);
		tab_group_B.add(handskinInputText);
		tab_group_B.add(clickSoundInputText);
		tab_group_B.add(loadButton);
		tab_group_B.add(saveButton);
		tab_group_B.add(reloadboxButton);
		UI_box.addGroup(tab_group_B);
	}

	function copyDefaultLine():DialogueLineDS {
		var copyLine:DialogueLineDS = {
			portrait: defaultLine.portrait,
			expression: defaultLine.expression,
			text: defaultLine.text,
			disableFadeBG: defaultLine.disableFadeBG,
			speed: defaultLine.speed,
			dialogueSound: defaultLine.dialogueSound,
			boxAnimPrefix: defaultLine.boxAnimPrefix
		};
		return copyLine;
	}

	function updateTextBox(name:String = '') {
		//var name:String = prefixInputText.text;
		if (name != '')
			box.animation.addByPrefix('idle', name + ' idle', 24);
		else
			box.animation.addByPrefix('idle', 'text box idle', 24);
		box.animation.play('idle', true);
		DialogueBoxDS.updateBoxOffsets(box);
	}

	function reloadBox(skin:String = 'ds_dialogue_box') {
		box.frames = Paths.getSparrowAtlas(skin);
		box.scrollFactor.set();
		box.setGraphicSize(Std.int(boxSize * 0.9));
		box.updateHitbox();
		if (dialogueFile.boxSkin.endsWith('-pixel'))
		{
			box.antialiasing = false;
		}
		else
		{
			box.antialiasing = ClientPrefs.data.antialiasing;
		}
		updateTextBox();
	}

	function reloadCharacter() {
		character.frames = Paths.getSparrowAtlas('dialogue/' + character.jsonFile.image);
		character.jsonFile = character.jsonFile;
		character.reloadAnimations();
		character.setGraphicSize(Std.int(character.width * DialogueCharacter.DEFAULT_SCALE * character.jsonFile.scale));
		character.updateHitbox();
		character.x = DialogueBoxDS.LEFT_CHAR_X;
		character.y = DialogueBoxDS.DEFAULT_CHAR_Y;

		switch(character.jsonFile.dialogue_pos) {
			case 'right':
				character.x = FlxG.width - character.width + DialogueBoxDS.RIGHT_CHAR_X;
			
			case 'center':
				character.x = FlxG.width / 2;
				character.x -= character.width / 2;
		}
		character.x += character.jsonFile.position[0];
		character.y += character.jsonFile.position[1];
		character.playAnim(); //Plays random animation
		characterAnimSpeed();

		if(character.animation.curAnim != null && character.jsonFile.animations != null) {
			animText.text = 'Animation: ' + character.jsonFile.animations[curAnim].anim + ' (' + (curAnim + 1) +' / ' + character.jsonFile.animations.length + ') - Press W or S to scroll';
		} else {
			animText.text = 'ERROR! NO ANIMATIONS FOUND';
		}
	}

	private static var DEFAULT_TEXT:String = "coolswag";
	private static var DEFAULT_SPEED:Float = 0.05;
	private static var DEFAULT_BOX:String = 'ds_dialogue_box';
	private static var DEFAULT_FONT:String = 'vcr.ttf';
	private static var DEFAULT_COLOR:String = '#FFFFFF';
	private static var DEFAULT_HAND:String = 'ds_dialogue_hand';


	function reloadText(skipDialogue:Bool) {
		var textToType:String = lineInputText.text;
		if(textToType == null || textToType.length < 1) textToType = ' ';

		daText.sounds = [FlxG.sound.load(Paths.sound(dialogueFile.dialogue[curSelected].dialogueSound), 0.6)];

		daText.resetText(textToType);
		daText.start(dialogueFile.dialogue[curSelected].speed, true);
		daText.completeCallback = function() {
			dialogueEnded = true;
		};

		updateText();

		dialogueEnded = false;

		if(skipDialogue) 
			daText.skip();
		else if(daText.delay > 0)
		{
			if(character.jsonFile.animations.length > curAnim && character.jsonFile.animations[curAnim] != null) {
				character.playAnim(character.jsonFile.animations[curAnim].anim);
			}
			characterAnimSpeed();
		}

		daText.y = DialogueBoxDS.DEFAULT_TEXT_Y;

		#if desktop
		// Updating Discord Rich Presence
		var rpcText:String = lineInputText.text;
		if(rpcText == null || rpcText.length < 1) rpcText = '(Empty)';
		if(rpcText.length < 3) rpcText += '   '; //Fixes a bug on RPC that triggers an error when the text is too short
		DiscordClient.changePresence("DS Dialogue Editor", rpcText);
		#end
	}

	override function getEvent(id:String, sender:Dynamic, data:Dynamic, ?params:Array<Dynamic>) {
		if(id == FlxUIInputText.CHANGE_EVENT && (sender is FlxUIInputText)) {
			if (sender == characterInputText)
			{
				character.reloadCharacterJson(characterInputText.text);
				reloadCharacter();
				if(character.jsonFile.animations.length > 0) {
					curAnim = 0;
					if(character.jsonFile.animations.length > curAnim && character.jsonFile.animations[curAnim] != null) {
						character.playAnim(character.jsonFile.animations[curAnim].anim, dialogueEnded);
						animText.text = 'Animation: ' + character.jsonFile.animations[curAnim].anim + ' (' + (curAnim + 1) +' / ' + character.jsonFile.animations.length + ') - Press W or S to scroll';
					} else {
						animText.text = 'ERROR! NO ANIMATIONS FOUND';
					}
					characterAnimSpeed();
				}
				dialogueFile.dialogue[curSelected].portrait = characterInputText.text;
				reloadText(false);
				updateTextBox();
			}
			else if(sender == lineInputText)
			{
				dialogueFile.dialogue[curSelected].text = lineInputText.text;

				daText.text = lineInputText.text;
				if(daText.text == null) daText.text = '';

				reloadText(true);
			}
			else if(sender == soundInputText)
			{
				daText.skip();
				dialogueFile.dialogue[curSelected].dialogueSound = soundInputText.text;
				if (soundInputText.text == null) soundInputText.text = '';
				daText.sounds = [FlxG.sound.load(Paths.sound(soundInputText.text), 0.6)];
			}
			else if (sender == prefixInputText)
			{
				dialogueFile.dialogue[curSelected].boxAnimPrefix = prefixInputText.text;
				if (prefixInputText.text == null) prefixInputText.text = '';
				updateTextBox(prefixInputText.text);
			}
			else if(sender == boxskinInputText)
			{
				dialogueFile.boxSkin = boxskinInputText.text;
			}
			else if(sender == fontInputText)
			{
				dialogueFile.font = fontInputText.text;
			}
			else if(sender == colorInputText)
			{
				dialogueFile.color = colorInputText.text;
			}
			else if (sender == dropColorInputText)
			{
				dialogueFile.dropTextColor = dropColorInputText.text;
			}
			else if (sender == outlineColorInputText)
			{
				dialogueFile.outlineColor = outlineColorInputText.text;
			}
			else if (sender == handskinInputText)
			{
				dialogueFile.handSkin = handskinInputText.text;
			}
			else if (sender == clickSoundInputText)
			{
				dialogueFile.clickSound = clickSoundInputText.text;
			}
			else if (sender == sizeInputText)
			{
				var sizeValue:Int = Std.parseInt(sizeInputText.text);
				dialogueFile.size = sizeValue;
				if(Math.isNaN(dialogueFile.size) || dialogueFile.size == null || dialogueFile.size < 10) {
					dialogueFile.size = 10;
				}
				if(dialogueFile.size > 64) {
					dialogueFile.size = 64;
				}
			}
		} else if(id == FlxUINumericStepper.CHANGE_EVENT && (sender == FlxUINumericStepper)) {
			if (sender == speedStepper)
			{
				dialogueFile.dialogue[curSelected].speed = speedStepper.value;
				if(Math.isNaN(dialogueFile.dialogue[curSelected].speed) || dialogueFile.dialogue[curSelected].speed == null || dialogueFile.dialogue[curSelected].speed < 0.001) {
					dialogueFile.dialogue[curSelected].speed = 0.0;
				}
				daText.delay = dialogueFile.dialogue[curSelected].speed;
				reloadText(false);
			}
			else if (sender == outlineSizeStepper)
			{
				dialogueFile.outlineSize = outlineSizeStepper.value;
				if(Math.isNaN(dialogueFile.outlineSize) || dialogueFile.outlineSize == null || dialogueFile.outlineSize < 0.1) {
					dialogueFile.outlineSize = 0.1;
				}
				daText.borderSize = outlineSizeStepper.value;
			}
		}
	}

	var curSelected:Int = 0;
	var curAnim:Int = 0;
	var blockPressWhileTypingOn:Array<FlxUIInputText> = [];
	var transitioning:Bool = false;
	override function update(elapsed:Float) {
		if(transitioning) {
			super.update(elapsed);
			return;
		}

		if (UI_box.selected_tab == 0)
			UI_box.resize(300, 210);
		else
			UI_box.resize(300, 300);

		dropText.text = daText.text;

		if(character.animation.curAnim != null) {
			if(dialogueEnded) {
				if(character.animationIsLoop() && character.animation.curAnim.finished) {
					character.playAnim(character.animation.curAnim.name, true);
				}
			} else if(character.animation.curAnim.finished) {
				character.animation.curAnim.restart();
			}
		}

		var blockInput:Bool = false;
		for (inputText in blockPressWhileTypingOn) {
			if(inputText.hasFocus) {
				FlxG.sound.muteKeys = [];
				FlxG.sound.volumeDownKeys = [];
				FlxG.sound.volumeUpKeys = [];
				blockInput = true;

				if(FlxG.keys.justPressed.ENTER) {
					if(inputText == lineInputText) {
						inputText.text += '\\n';
						inputText.caretIndex += 2;
					} else {
						inputText.hasFocus = false;
					}
				}
				break;
			}
		}

		if(!blockInput) {
			FlxG.sound.muteKeys = TitleState.muteKeys;
			FlxG.sound.volumeDownKeys = TitleState.volumeDownKeys;
			FlxG.sound.volumeUpKeys = TitleState.volumeUpKeys;
			if(FlxG.keys.justPressed.SPACE) {
				reloadText(false);
			}
			if(FlxG.keys.justPressed.ESCAPE) {
				MusicBeatState.switchState(new states.editors.MasterEditorMenu());
				FlxG.sound.playMusic(Paths.music('freakyMenu'), 1);
				transitioning = true;
			}
			var negaMult:Array<Int> = [1, -1];
			var controlAnim:Array<Bool> = [FlxG.keys.justPressed.W, FlxG.keys.justPressed.S];
			var controlText:Array<Bool> = [FlxG.keys.justPressed.D, FlxG.keys.justPressed.A];
			for (i in 0...controlAnim.length) {
				if(controlAnim[i] && character.jsonFile.animations.length > 0) {
					curAnim -= negaMult[i];
					if(curAnim < 0) curAnim = character.jsonFile.animations.length - 1;
					else if(curAnim >= character.jsonFile.animations.length) curAnim = 0;

					var animToPlay:String = character.jsonFile.animations[curAnim].anim;
					if(character.dialogueAnimations.exists(animToPlay)) {
						character.playAnim(animToPlay, dialogueEnded);
						dialogueFile.dialogue[curSelected].expression = animToPlay;
					}
					animText.text = 'Animation: ' + animToPlay + ' (' + (curAnim + 1) +' / ' + character.jsonFile.animations.length + ') - Press W or S to scroll';
				}
				if(controlText[i]) {
					changeText(negaMult[i]);
				}
			}

			if(FlxG.keys.justPressed.O) {
				dialogueFile.dialogue.remove(dialogueFile.dialogue[curSelected]);
				if(dialogueFile.dialogue.length < 1) //You deleted everything, dumbo!
				{
					dialogueFile.dialogue = [
						copyDefaultLine()
					];
				}
				changeText();
			} else if(FlxG.keys.justPressed.P) {
				dialogueFile.dialogue.insert(curSelected + 1, copyDefaultLine());
				changeText(1);
			}
		}
		super.update(elapsed);
	}

	function changeText(add:Int = 0) {
		curSelected += add;
		if(curSelected < 0) curSelected = dialogueFile.dialogue.length - 1;
		else if(curSelected >= dialogueFile.dialogue.length) curSelected = 0;

		var curDialogue:DialogueLineDS = dialogueFile.dialogue[curSelected];
		characterInputText.text = curDialogue.portrait;
		lineInputText.text = curDialogue.text;
		speedStepper.value = curDialogue.speed;
		fadeBGCheckbox.checked = curDialogue.disableFadeBG;
		prefixInputText.text = curDialogue.boxAnimPrefix;

		daText.delay = speedStepper.value;
		daText.sounds = [FlxG.sound.load(Paths.sound(soundInputText.text), 0.6)];

		curAnim = 0;
		character.reloadCharacterJson(characterInputText.text);
		reloadCharacter();
		reloadText(false);
		updateTextBox();

		var leLength:Int = character.jsonFile.animations.length;
		if(leLength > 0) {
			for (i in 0...leLength) {
				var leAnim:DialogueAnimArray = character.jsonFile.animations[i];
				if(leAnim != null && leAnim.anim == curDialogue.expression) {
					curAnim = i;
					break;
				}
			}
			character.playAnim(character.jsonFile.animations[curAnim].anim, dialogueEnded);
			animText.text = 'Animation: ' + character.jsonFile.animations[curAnim].anim + ' (' + (curAnim + 1) +' / ' + leLength + ') - Press W or S to scroll';
		} else {
			animText.text = 'ERROR! NO ANIMATIONS FOUND';
		}
		characterAnimSpeed();

		selectedText.text = 'Line: (' + (curSelected + 1) + ' / ' + dialogueFile.dialogue.length + ') - Press A or D to scroll';
	}

	function characterAnimSpeed() {
		if(character.animation.curAnim != null) {
			var speed:Float = speedStepper.value;
			var rate:Float = 24 - (((speed - 0.05) / 5) * 480);
			if(rate < 12) rate = 12;
			else if(rate > 48) rate = 48;
			character.animation.curAnim.frameRate = rate;
		}
	}

	var _file:FileReference = null;
	function loadDialogue() {
		var jsonFilter:FileFilter = new FileFilter('JSON', 'json');
		_file = new FileReference();
		_file.addEventListener(Event.SELECT, onLoadComplete);
		_file.addEventListener(Event.CANCEL, onLoadCancel);
		_file.addEventListener(IOErrorEvent.IO_ERROR, onLoadError);
		_file.browse([jsonFilter]);
	}

	function onLoadComplete(_):Void
	{
		_file.removeEventListener(Event.SELECT, onLoadComplete);
		_file.removeEventListener(Event.CANCEL, onLoadCancel);
		_file.removeEventListener(IOErrorEvent.IO_ERROR, onLoadError);

		#if sys
		var fullPath:String = null;
		@:privateAccess
		if(_file.__path != null) fullPath = _file.__path;

		if(fullPath != null) {
			var rawJson:String = File.getContent(fullPath);
			if(rawJson != null) {
				var loadedDialog:DialogueFileDS = cast Json.parse(rawJson);
				if(loadedDialog.dialogue != null && loadedDialog.dialogue.length > 0) //Make sure it's really a dialogue file
				{
					var cutName:String = _file.name.substr(0, _file.name.length - 5);
					trace("Successfully loaded file: " + cutName);
					dialogueFile = loadedDialog;
					loadThing();
					changeText();
					reloadBox(dialogueFile.boxSkin);
					reloadHand();
					_file = null;
					return;
				}
			}
		}
		_file = null;
		#else
		trace("File couldn't be loaded! You aren't on Desktop, are you?");
		#end
	}

	function loadThing()
	{
		boxskinInputText.text = dialogueFile.boxSkin;
		fontInputText.text = dialogueFile.font;
		colorInputText.text = dialogueFile.color;
		if (dialogueFile.dropTextEnable)
			droptextCheckbox.checked = true;
		else
			droptextCheckbox.checked = false;

		dropColorInputText.text = dialogueFile.dropTextColor;
		if (dialogueFile.outlineEnable)
			outlineCheckbox.checked = true;
		else
			outlineCheckbox.checked = false;

		outlineColorInputText.text = dialogueFile.outlineColor;
		outlineSizeStepper.value = dialogueFile.outlineSize;
		if (dialogueFile.handEnable)
			handCheckbox.checked = true;
		else
			handCheckbox.checked = false;
		handskinInputText.text = dialogueFile.handSkin;
		clickSoundInputText.text = dialogueFile.clickSound;
	}

	function updateText()
	{
		daText.fieldWidth = Std.int(box.width * 0.82);
		daText.setFormat(Paths.font(dialogueFile.font), dialogueFile.size, FlxColor.fromString(dialogueFile.color), LEFT);
		if (dialogueFile.outlineEnable)
		{
			daText.borderColor = FlxColor.fromString(dialogueFile.outlineColor);
			daText.borderStyle = OUTLINE;
			daText.borderSize = dialogueFile.outlineSize;
		}
		else
		{
			daText.borderStyle = NONE;
		}

		dropText.fieldWidth = Std.int(box.width * 0.82);
		dropText.setFormat(Paths.font(dialogueFile.font), dialogueFile.size, FlxColor.fromString(dialogueFile.dropTextColor), LEFT);
		if (dialogueFile.dropTextEnable) dropText.visible = true;
		else dropText.visible = false;
	}

	function reloadHand()
	{
		handSelect.loadGraphic(Paths.image(dialogueFile.handSkin));
		handSelect.setGraphicSize(Std.int(handSelect.width * 0.9));
		handSelect.updateHitbox();
		if (dialogueFile.handSkin.endsWith('-pixel'))
		{
			handSelect.antialiasing = false;
		}
		else
		{
			handSelect.antialiasing = ClientPrefs.data.antialiasing;
		}
		if (dialogueFile.handEnable)
			handSelect.visible = true;
		else
			handSelect.visible = false;
	}

	/**
		* Called when the save file dialog is cancelled.
		*/
	function onLoadCancel(_):Void
	{
		_file.removeEventListener(Event.SELECT, onLoadComplete);
		_file.removeEventListener(Event.CANCEL, onLoadCancel);
		_file.removeEventListener(IOErrorEvent.IO_ERROR, onLoadError);
		_file = null;
		trace("Cancelled file loading.");
	}

	/**
		* Called if there is an error while saving the gameplay recording.
		*/
	function onLoadError(_):Void
	{
		_file.removeEventListener(Event.SELECT, onLoadComplete);
		_file.removeEventListener(Event.CANCEL, onLoadCancel);
		_file.removeEventListener(IOErrorEvent.IO_ERROR, onLoadError);
		_file = null;
		trace("Problem loading file");
	}

	function saveDialogue() {
		var data:String = haxe.Json.stringify(dialogueFile, "\t");
		if (data.length > 0)
		{
			_file = new FileReference();
			_file.addEventListener(Event.COMPLETE, onSaveComplete);
			_file.addEventListener(Event.CANCEL, onSaveCancel);
			_file.addEventListener(IOErrorEvent.IO_ERROR, onSaveError);
			_file.save(data, "dialogue.json");
		}
	}

	function onSaveComplete(_):Void
	{
		_file.removeEventListener(Event.COMPLETE, onSaveComplete);
		_file.removeEventListener(Event.CANCEL, onSaveCancel);
		_file.removeEventListener(IOErrorEvent.IO_ERROR, onSaveError);
		_file = null;
		FlxG.log.notice("Successfully saved file.");
	}

	/**
		* Called when the save file dialog is cancelled.
		*/
	function onSaveCancel(_):Void
	{
		_file.removeEventListener(Event.COMPLETE, onSaveComplete);
		_file.removeEventListener(Event.CANCEL, onSaveCancel);
		_file.removeEventListener(IOErrorEvent.IO_ERROR, onSaveError);
		_file = null;
	}

	/**
		* Called if there is an error while saving the gameplay recording.
		*/
	function onSaveError(_):Void
	{
		_file.removeEventListener(Event.COMPLETE, onSaveComplete);
		_file.removeEventListener(Event.CANCEL, onSaveCancel);
		_file.removeEventListener(IOErrorEvent.IO_ERROR, onSaveError);
		_file = null;
		FlxG.log.error("Problem saving file");
	}
}