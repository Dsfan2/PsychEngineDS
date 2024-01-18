package options;

import flixel.addons.display.FlxGridOverlay;
import objects.AttachedSprite;
#if MODS_ALLOWED
import sys.FileSystem;
#end

class PlayerSelectMenu extends MusicBeatSubstate
{
	var charFile:Array<String> = [];
	var options:Array<String> = CoolUtil.coolTextFile(Paths.txt('playerChars'));

	private var grpTexts:FlxTypedGroup<Alphabet>;
 	var descBox:FlxSprite;
	private var descText:FlxText;
	var playerName:String = "";

	var player1Sprite:FlxSprite;
	var player2Sprite:FlxSprite;
	var player3Sprite:FlxSprite;
	var cursor:FlxSprite;

	var nextAccept:Int = 5;

	private var curSelected = 0;

	override function create()
	{
		#if MODS_ALLOWED
		if (FileSystem.exists(Paths.modFolders('data/playerChars.txt')))
			charFile = CoolUtil.coolTextFile(Paths.modFolders('data/playerChars'));
		else
			charFile = CoolUtil.coolTextFile(Paths.txt('playerChars'));
		#else
		charFile = CoolUtil.coolTextFile(Paths.txt('playerChars'));
		#end
		if (charFile.length > 3)
			options = [charFile[0], charFile[1], charFile[2]];

		if (ClientPrefs.data.playerChar == 1)
            playerName = options[0];	
        if (ClientPrefs.data.playerChar == 2)
            playerName = options[1];
        if (ClientPrefs.data.playerChar == 3)
            playerName = options[2];

		var bg:FlxSprite = new FlxSprite().loadGraphic(Paths.image('menuDesat'));
		bg.color = 0xFFEA71FD;
		bg.screenCenter();
		bg.antialiasing = ClientPrefs.data.antialiasing;
		add(bg);

		var grid:FlxBackdrop = new FlxBackdrop(FlxGridOverlay.createGrid(80, 80, 160, 160, true, 0x33FFFFFF, 0x0));
		grid.velocity.set(40, 40);
		grid.alpha = 0;
		FlxTween.tween(grid, {alpha: 1}, 0.5, {ease: FlxEase.quadOut});
		add(grid);

		cursor = new FlxSprite(100, 200);
		cursor.frames = Paths.getSparrowAtlas('player-select/SlotFrame');
		cursor.animation.addByPrefix('static', 'Static', 24, true);
		cursor.animation.addByPrefix('confirm', 'Selected', 24, false);
		cursor.animation.play('static');
	    cursor.setGraphicSize(Std.int(cursor.width * 0.5));
		cursor.updateHitbox();
		cursor.antialiasing = ClientPrefs.data.antialiasing;
		add(cursor);

		loadJunk();

		grpTexts = new FlxTypedGroup<Alphabet>();
		add(grpTexts);

		for (i in 0...options.length)
		{
			var leText:Alphabet = new Alphabet((400 * i) + 130, 530, options[i], true);
			leText.setScale(0.6 * TitleState.alphabetScale);
			leText.changeX = false;
			leText.changeY = false;
			leText.isMenuItem = true;
			grpTexts.add(leText);
		}
		
		descBox = new FlxSprite().makeGraphic(1, 1, FlxColor.BLACK);
		descBox.alpha = 0.6;
		add(descBox);

		descText = new FlxText(50, 670, 1180, "", 32);
		descText.setFormat(Paths.font("vcr.ttf"), 32, FlxColor.WHITE, CENTER, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		descText.scrollFactor.set();
		descText.borderSize = 2.4;
		descText.text = "Curent Player Character: " + playerName;
		add(descText);

		var titleText:Alphabet = new Alphabet(20, 20, "Player Character Select", true);
		titleText.setScale(0.6 * TitleState.alphabetScale);
		titleText.alpha = 0.4;
		add(titleText);

		changeSelection();

		FlxG.mouse.visible = false;
		super.create();
	}

	override function update(elapsed:Float)
	{
		if (controls.UI_LEFT_P)
		{
			changeSelection(-1);
		}
		if (controls.UI_RIGHT_P)
		{
			changeSelection(1);
		}

		if (controls.BACK)
		{
			close();
			FlxG.sound.play(Paths.sound('cancelMenu'));
		}

		if (controls.ACCEPT && nextAccept <= 0)
		{
			changeCharacter();
		}
		
		var bulltrash:Int = 0;
		for (item in grpTexts.members)
		{
			item.targetY = bulltrash - curSelected;
			bulltrash++;

			item.alpha = 0.6;

			if (item.targetY == 0)
			{
				item.alpha = 1;
			}
		}

		if(nextAccept > 0) {
			nextAccept -= 1;
		}

		super.update(elapsed);
	}

	function changeCharacter()
	{
		switch(curSelected) 
		{
			case 0:
				FlxG.sound.play(Paths.sound('confirmMenu'), 0.7);
				ClientPrefs.data.playerChar = 1;
				player1Sprite.animation.play('select', true);
				player2Sprite.animation.play('idle', true);
				player3Sprite.animation.play('idle', true);
			case 1:
				FlxG.sound.play(Paths.sound('confirmMenu'), 0.7);
				ClientPrefs.data.playerChar = 2;
				player1Sprite.animation.play('idle', true);
				player2Sprite.animation.play('select', true);
				player3Sprite.animation.play('idle', true);
			case 2:
				FlxG.sound.play(Paths.sound('confirmMenu'), 0.7);
				ClientPrefs.data.playerChar = 3;
				player1Sprite.animation.play('idle', true);
				player2Sprite.animation.play('idle', true);
				player3Sprite.animation.play('select', true);
		}

		if (ClientPrefs.data.playerChar == 1)
            playerName = options[0];	
        if (ClientPrefs.data.playerChar == 2)
            playerName = options[1];
        if (ClientPrefs.data.playerChar == 3)
            playerName = options[2];

		cursor.animation.play('confirm');

		descText.text = "Curent Player Character: " + playerName;
		descBox.setPosition(descText.x - 10, descText.y - 10);
		descBox.setGraphicSize(Std.int(descText.width + 20), Std.int(descText.height + 25));
		descBox.updateHitbox();
	}

	function changeSelection(change:Int = 0)
	{
		curSelected += change;

		if (curSelected < 0)
			curSelected = options.length - 1;
		if (curSelected >= options.length)
			curSelected = 0;

		cursor.animation.play('static');

		switch (curSelected)
		{
			case 0:
				cursor.x = player1Sprite.x;
			case 1:
				cursor.x = player2Sprite.x;
			case 2:
				cursor.x = player3Sprite.x;
		}

		descText.text = "Curent Player Character: " + playerName;
		descBox.setPosition(descText.x - 10, descText.y - 10);
		descBox.setGraphicSize(Std.int(descText.width + 20), Std.int(descText.height + 25));
		descBox.updateHitbox();
		FlxG.sound.play(Paths.sound('scrollMenu'), 0.4);
	}

	function loadJunk()
	{
		player1Sprite = new FlxSprite(100, 200);
		player1Sprite.frames = Paths.getSparrowAtlas('player-select/PlayerChar_1');
		player1Sprite.animation.addByPrefix('idle', 'Idle Anim', 24, true);
		player1Sprite.animation.addByPrefix('select', 'Hey Anim', 24, false);
		player1Sprite.animation.play('idle');
	    player1Sprite.setGraphicSize(Std.int(player1Sprite.width * 0.5));
		player1Sprite.updateHitbox();
		player1Sprite.antialiasing = ClientPrefs.data.antialiasing;
		add(player1Sprite);

		player2Sprite = new FlxSprite(500, 200);
		player2Sprite.frames = Paths.getSparrowAtlas('player-select/PlayerChar_2');
		player2Sprite.animation.addByPrefix('idle', 'Idle Anim', 24, true);
		player2Sprite.animation.addByPrefix('select', 'Hey Anim', 24, false);
		player2Sprite.animation.play('idle');
	    player2Sprite.setGraphicSize(Std.int(player2Sprite.width * 0.5));
		player2Sprite.updateHitbox();
		player2Sprite.antialiasing = ClientPrefs.data.antialiasing;
		add(player2Sprite);

		player3Sprite = new FlxSprite(900, 200);
		player3Sprite.frames = Paths.getSparrowAtlas('player-select/PlayerChar_3');
		player3Sprite.animation.addByPrefix('idle', 'Idle Anim', 24, true);
		player3Sprite.animation.addByPrefix('select', 'Hey Anim', 24, false);
		player3Sprite.animation.play('idle');
	    player3Sprite.setGraphicSize(Std.int(player3Sprite.width * 0.5));
		player3Sprite.updateHitbox();
		player3Sprite.antialiasing = ClientPrefs.data.antialiasing;
		add(player3Sprite);

		switch (ClientPrefs.data.playerChar)
		{
			case 1:
				player1Sprite.animation.play('select');
			case 2:
				player2Sprite.animation.play('select');
			case 3:
				player3Sprite.animation.play('select');
		}
	}
}