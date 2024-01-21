package cutscenes;

import flixel.addons.text.FlxTypeText;
import tjson.TJSON as Json;
import openfl.utils.Assets;

#if sys
import sys.FileSystem;
import sys.io.File;
#end

import cutscenes.DialogueCharacter;

typedef DialogueFileDS = {
	var dialogue:Array<DialogueLineDS>;
	var boxSkin:Null<String>;
	var font:Null<String>;
	var color:Null<String>;
	var size:Null<Int>;
	var dropTextEnable:Null<Bool>;
	var dropTextColor:Null<String>;
	var outlineEnable:Null<Bool>;
	var outlineColor:Null<String>;
	var outlineSize:Null<Float>;
	var handEnable:Null<Bool>;
	var handSkin:Null<String>;
	var clickSound:Null<String>;
}

typedef DialogueLineDS = {
	var portrait:Null<String>;
	var expression:Null<String>;
	var text:Null<String>;
	var speed:Null<Float>;
	var dialogueSound:Null<String>;
	var disableFadeBG:Null<Bool>;
}

// TO DO: Clean code? Maybe? idk
class DialogueBoxDS extends FlxSpriteGroup
{
	var dialogue:FlxTypeText;
	var dialogueList:DialogueFileDS = null;
	var dropText:FlxText;

	public var finishThing:Void->Void;
	public var nextDialogueThing:Void->Void = null;
	public var skipDialogueThing:Void->Void = null;
	var bgFade:FlxSprite = null;
	var box:FlxSprite;
	var textToType:String = '';

	var arrayCharacters:Array<DialogueCharacter> = [];

	var currentText:Int = 0;
	var offsetPos:Float = -600;

	var textBoxTypes:Array<String> = ['idle'];
	
	var curCharacter:String = "";
	var handSelect:FlxSprite;

	var boxSize:Float = 0.00;

	public function new(dialogueList:DialogueFileDS, ?song:String = null)
	{
		super();

		if(song != null && song != '') {
			FlxG.sound.playMusic(Paths.music(song), 0);
			FlxG.sound.music.fadeIn(2, 0, 1);
		}
		
		bgFade = new FlxSprite(-500, -500).makeGraphic(FlxG.width * 2, FlxG.height * 2, FlxColor.WHITE);
		bgFade.scrollFactor.set();
		bgFade.visible = true;
		bgFade.alpha = 0;
		add(bgFade);

		this.dialogueList = dialogueList;
		spawnCharacters();

		box = new FlxSprite(70, 370);
		box.frames = Paths.getSparrowAtlas(dialogueList.boxSkin);
		boxSize = box.width;
		box.scrollFactor.set();
		box.animation.addByPrefix('idle', 'text box idle', 24);
		box.animation.addByPrefix('open', 'text box open', 24, false);
		box.animation.play('open', true);
		box.visible = false;
		box.setGraphicSize(Std.int(box.width * 0.9));
		box.updateHitbox();
		if (dialogueList.boxSkin.endsWith('-pixel'))
		{
			box.antialiasing = false;
		}
		else
		{
			box.antialiasing = ClientPrefs.data.antialiasing;
		}
		add(box);

		daText = new FlxTypeText(DEFAULT_TEXT_X, DEFAULT_TEXT_Y, Std.int(box.width * 0.82), "", dialogueList.size);
		daText.font = Paths.font(dialogueList.font);
		daText.color = FlxColor.fromString(dialogueList.color);
		if (dialogueList.outlineEnable)
		{
			daText.borderColor = FlxColor.fromString(dialogueList.outlineColor);
			daText.borderStyle = OUTLINE;
			daText.borderSize = dialogueList.outlineSize;
		}

		dropText = new FlxText(DEFAULT_TEXT_X - 2, DEFAULT_TEXT_Y + 2, Std.int(box.width * 0.82), "", dialogueList.size);
		dropText.font = dialogueList.font;
		dropText.color = FlxColor.fromString(dialogueList.dropTextColor);
		add(dropText);

		if (!dialogueList.dropTextEnable)
			dropText.visible = false;
		add(daText);

		handSelect = new FlxSprite(1042, 590).loadGraphic(Paths.image(dialogueList.handSkin));
		handSelect.setGraphicSize(Std.int(handSelect.width * 0.9));
		handSelect.updateHitbox();
		if (dialogueList.handSkin.endsWith('-pixel'))
		{
			handSelect.antialiasing = false;
		}
		else
		{
			handSelect.antialiasing = ClientPrefs.data.antialiasing;
		}
		handSelect.visible = false;
		if (dialogueList.handEnable)
			add(handSelect);

		closeSound = dialogueList.clickSound;
		startNextDialog();
	}

	var dialogueOpened:Bool = false;
	var dialogueStarted:Bool = false;
	var dialogueEnded:Bool = false;
	var isEnding:Bool = false;

	public static var LEFT_CHAR_X:Float = -60;
	public static var RIGHT_CHAR_X:Float = -100;
	public static var DEFAULT_CHAR_Y:Float = 60;

	function spawnCharacters() {
		#if (haxe >= "4.0.0")
		var charsMap:Map<String, Bool> = new Map();
		#else
		var charsMap:Map<String, Bool> = new Map<String, Bool>();
		#end
		for (i in 0...dialogueList.dialogue.length) {
			if(dialogueList.dialogue[i] != null) {
				var charToAdd:String = dialogueList.dialogue[i].portrait;
				if(!charsMap.exists(charToAdd) || !charsMap.get(charToAdd)) {
					charsMap.set(charToAdd, true);
				}
			}
		}

		for (individualChar in charsMap.keys()) {
			var x:Float = LEFT_CHAR_X;
			var y:Float = DEFAULT_CHAR_Y;
			var char:DialogueCharacter = new DialogueCharacter(x + offsetPos, y, individualChar);
			char.setGraphicSize(Std.int(char.width * DialogueCharacter.DEFAULT_SCALE * char.jsonFile.scale));
			char.updateHitbox();
			char.scrollFactor.set();
			char.alpha = 0.00001;
			add(char);

			var saveY:Bool = false;
			switch(char.jsonFile.dialogue_pos) {
				case 'center':
					char.x = FlxG.width / 2;
					char.x -= char.width / 2;
					y = char.y;
					char.y = FlxG.height + 50;
					saveY = true;
				case 'right':
					x = FlxG.width - char.width + RIGHT_CHAR_X;
					char.x = x - offsetPos;
			}
			x += char.jsonFile.position[0];
			y += char.jsonFile.position[1];
			char.x += char.jsonFile.position[0];
			char.y += char.jsonFile.position[1];
			char.startingPos = (saveY ? y : x);
			arrayCharacters.push(char);
		}
	}

	public static var DEFAULT_TEXT_X = 190;
	public static var DEFAULT_TEXT_Y = 475;
	public static var LONG_TEXT_ADD = 24;
	var scrollSpeed = 4000;
	var daText:FlxTypeText = null;
	var ignoreThisFrame:Bool = true; //First frame is reserved for loading dialogue images

	public var closeSound:String = 'dialogueClose';
	public var closeVolume:Float = 1;
	override function update(elapsed:Float)
	{
		if(ignoreThisFrame) {
			ignoreThisFrame = false;
			super.update(elapsed);
			return;
		}

		dropText.text = daText.text;

		if(!isEnding) {
			bgFade.alpha += 0.5 * elapsed;
			if(bgFade.alpha > 0.5) bgFade.alpha = 0.5;

			if(Controls.instance.ACCEPT) {
				if(!dialogueEnded) {
					FlxG.sound.play(Paths.sound(closeSound), closeVolume);
					daText.skip();
					if(skipDialogueThing != null) {
						skipDialogueThing();
					}
				} else if(currentText >= dialogueList.dialogue.length) {
					isEnding = true;
					box.animation.play('open', true);

					box.animation.curAnim.curFrame = box.animation.curAnim.frames.length - 1;
					box.animation.curAnim.reverse();
					if(daText != null)
					{
						daText.kill();
						remove(daText);
						daText.destroy();
					}
					updateBoxOffsets(box);
					FlxG.sound.music.fadeOut(1, 0);
				} else {
					startNextDialog();
				}
				FlxG.sound.play(Paths.sound(closeSound), closeVolume);
			} else if(dialogueEnded) {
				var char:DialogueCharacter = arrayCharacters[lastCharacter];
				if(char != null && char.animation.curAnim != null && char.animationIsLoop() && char.animation.finished) {
					char.playAnim(char.animation.curAnim.name, true);
				}
			} else {
				var char:DialogueCharacter = arrayCharacters[lastCharacter];
				if(char != null && char.animation.curAnim != null && char.animation.finished) {
					char.animation.curAnim.restart();
				}
			}

			if(box.animation.curAnim.finished) {
				for (i in 0...textBoxTypes.length) {
					var animName:String = box.animation.curAnim.name;
					if(animName == 'open') {
						box.animation.play('idle', true);
					}
				}
				updateBoxOffsets(box);
			}

			if(lastCharacter != -1 && arrayCharacters.length > 0) {
				for (i in 0...arrayCharacters.length) {
					var char = arrayCharacters[i];
					if(char != null) {
						if(i != lastCharacter) {
							switch(char.jsonFile.dialogue_pos) {
								case 'left':
									char.x -= scrollSpeed * elapsed;
									if(char.x < char.startingPos + offsetPos) char.x = char.startingPos + offsetPos;
								case 'center':
									char.y += scrollSpeed * elapsed;
									if(char.y > char.startingPos + FlxG.height) char.y = char.startingPos + FlxG.height;
								case 'right':
									char.x += scrollSpeed * elapsed;
									if(char.x > char.startingPos - offsetPos) char.x = char.startingPos - offsetPos;
							}
							char.alpha -= 3 * elapsed;
							if(char.alpha < 0.00001) char.alpha = 0.00001;
						} else {
							switch(char.jsonFile.dialogue_pos) {
								case 'left':
									char.x += scrollSpeed * elapsed;
									if(char.x > char.startingPos) char.x = char.startingPos;
								case 'center':
									char.y -= scrollSpeed * elapsed;
									if(char.y < char.startingPos) char.y = char.startingPos;
								case 'right':
									char.x -= scrollSpeed * elapsed;
									if(char.x < char.startingPos) char.x = char.startingPos;
							}
							char.alpha += 3 * elapsed;
							if(char.alpha > 1) char.alpha = 1;
						}
					}
				}
			}
		} else { //Dialogue ending
			daText.alpha = 0;
			dropText.alpha = 0;
			handSelect.alpha = 0;
			if(box != null && box.animation.curAnim.curFrame <= 0) {
				box.kill();
				remove(box);
				box.destroy();
				box = null;
			}

			if(bgFade != null) {
				bgFade.alpha -= 0.5 * elapsed;
				if(bgFade.alpha <= 0) {
					bgFade.kill();
					remove(bgFade);
					bgFade.destroy();
					bgFade = null;
				}
			}

			for (i in 0...arrayCharacters.length) {
				var leChar:DialogueCharacter = arrayCharacters[i];
				if(leChar != null) {
					switch(arrayCharacters[i].jsonFile.dialogue_pos) {
						case 'left':
							leChar.x -= scrollSpeed * elapsed;
						case 'center':
							leChar.y += scrollSpeed * elapsed;
						case 'right':
							leChar.x += scrollSpeed * elapsed;
					}
					leChar.alpha -= elapsed * 10;
				}
			}

			if(box == null && bgFade == null) {
				for (i in 0...arrayCharacters.length) {
					var leChar:DialogueCharacter = arrayCharacters[0];
					if(leChar != null) {
						arrayCharacters.remove(leChar);
						leChar.kill();
						remove(leChar);
						leChar.destroy();
					}
				}
				finishThing();
				kill();
			}
		}
		super.update(elapsed);
	}

	var lastCharacter:Int = -1;
	function startNextDialog():Void
	{
		var curDialogue:DialogueLineDS = null;
		do {
			curDialogue = dialogueList.dialogue[currentText];
		} while(curDialogue == null);

		if(curDialogue.text == null || curDialogue.text.length < 1) curDialogue.text = ' ';
		if(curDialogue.speed == null || Math.isNaN(curDialogue.speed)) curDialogue.speed = 0.05;

		if (curDialogue.disableFadeBG == null)
			curDialogue.disableFadeBG = false;
		bgFade.visible = !curDialogue.disableFadeBG;

		daText.sounds = [FlxG.sound.load(Paths.sound(curDialogue.dialogueSound), 0.6)];
		var character:Int = 0;
		box.visible = true;
		handSelect.visible = false;
		for (i in 0...arrayCharacters.length) {
			if(arrayCharacters[i].curCharacter == curDialogue.portrait) {
				character = i;
				break;
			}
		}
		var centerPrefix:String = '';
		var lePosition:String = arrayCharacters[character].jsonFile.dialogue_pos;
		if(lePosition == 'center') centerPrefix = 'center-';

		if (lastCharacter == -1) {
			box.animation.play('open', true);
			updateBoxOffsets(box);
		} else {
			box.animation.play('idle', true);
			updateBoxOffsets(box);
		}
		lastCharacter = character;

		daText.resetText(curDialogue.text);
		daText.delay = curDialogue.speed;
		daText.start(curDialogue.speed, true);
		daText.completeCallback = function() {
			handSelect.visible = true;
			dialogueEnded = true;
		};
		
		daText.y = DEFAULT_TEXT_Y;
		dialogueEnded = false;

		var char:DialogueCharacter = arrayCharacters[character];
		if(char != null) {
			char.playAnim(curDialogue.expression, dialogueEnded);
			if(char.animation.curAnim != null) {
				var rate:Float = 24 - (((curDialogue.speed - 0.05) / 5) * 480);
				if(rate < 12) rate = 12;
				else if(rate > 48) rate = 48;
				char.animation.curAnim.frameRate = rate;
			}
		}
		currentText++;

		if(nextDialogueThing != null) {
			nextDialogueThing();
		}
	}

	public static function parseDialogue(path:String):DialogueFileDS {
		#if MODS_ALLOWED
		if(FileSystem.exists(path))
		{
			return cast Json.parse(File.getContent(path));
		}
		#end
		return cast Json.parse(Assets.getText(path));
	}

	public static function updateBoxOffsets(box:FlxSprite) { //Had to make it static because of the editors
		box.centerOffsets();
		box.updateHitbox();
		box.offset.set(10, 0);
		box.offset.y += 10;
	}
}
