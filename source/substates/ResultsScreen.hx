package substates;

import flixel.FlxSubState;
import flixel.effects.FlxFlicker;
import states.FreeplayState;

class ResultsScreen extends MusicBeatSubstate
{
    var songName:String = "";
    var songDifficulty:String = "";
    var songRanking:String = "";
    var songAccuracy:Float = 0;
    var songScore:Int = 0;
    var songMisses:Int = 0;
    var highestCombo:Int = 0;
    var gameOvers:Int = 0;
    var sicks:Int = 0;
    var goods:Int = 0;
    var bads:Int = 0;
    var trashes:Int = 0;
    var accNum:Float = 0.00;

    var jingle:String = "";
    var playerSound:String = "";

    public static var bgName:String = "menuBGBlue";
    public static var spriteName:String = "player";
    public static var soundName:String = "BF";
    public static var musicName:String = "breakfast";

    var canExit:Bool = false;
    var resultsStarted:Bool = false;
    var whiteFlash:FlxSprite;
    var background:FlxSprite;

    var songNameText:Alphabet;
    var basicText:Alphabet;
    var accuracyText:Alphabet;
    var accuracyCounter:Alphabet;
    public var charSprite:FlxSprite;
    var rankText:Alphabet;
    var ranking:Alphabet;
    var contText:Alphabet;

    public var music:FlxSound;

    public static var instance:ResultsScreen;

    public static function resetVariables() {
		bgName = 'menuBGBlue';
        switch (ClientPrefs.data.playerChar)
        {
            case 1:
                spriteName = 'player1';
                soundName = 'BF';
            case 2:
                spriteName = 'player2';
                soundName = 'JR';
            case 3:
                spriteName = 'player3';
                soundName = 'MONI';
        }
		musicName = 'breakfast';

		var _song = PlayState.SONG;
		if(_song != null)
		{
			if(_song.resultBG != null && _song.resultBG.trim().length > 0) bgName = _song.resultBG;
			if(_song.resultSprite != null && _song.resultSprite.trim().length > 0) spriteName = _song.resultSprite;
			if(_song.resultSound != null && _song.resultSound.trim().length > 0) soundName = _song.resultSound;
			if(_song.resultMusic != null && _song.resultMusic.trim().length > 0) musicName = _song.resultMusic;
		}
	}

	override function create()
	{
        instance = this;
		PlayState.instance.callOnScripts('onResultsStart', []);

        songName = PlayState.SONG.song;
        songDifficulty = Difficulty.getString().toUpperCase();
        songRanking = PlayState.instance.ratingName;
        songAccuracy = PlayState.songAccuracy;
        songScore = PlayState.instance.songScore;
        songMisses = PlayState.instance.songMisses;
        highestCombo = PlayState.highestCombo;
        gameOvers = PlayState.deathCounter;
        sicks = PlayState.sicks;
        goods = PlayState.goods;
        bads = PlayState.bads;
        trashes = PlayState.trashes;
        
        background = new FlxSprite().loadGraphic(Paths.image(bgName));
		background.updateHitbox();
        background.scrollFactor.set();
        add(background);

        charSprite = new FlxSprite(830, 50);
        charSprite.frames = Paths.getSparrowAtlas('results/' + spriteName +'_sprites');
		charSprite.animation.addByPrefix('idle', "Pending", 24, false);
        charSprite.animation.addByPrefix('hey', "S Rank", 24, false);
        charSprite.animation.addByPrefix('cool', "C-A Rank", 24, false);
        charSprite.animation.addByPrefix('uncool', "H-D Rank", 24, false);
        charSprite.animation.addByPrefix('oof', "U SUK Rank", 24, false);
		charSprite.antialiasing = ClientPrefs.data.antialiasing;
		charSprite.setGraphicSize(Std.int(charSprite.width * 0.75));
		charSprite.updateHitbox();
		add(charSprite);
        charSprite.animation.play('idle');

        songNameText = new Alphabet(5, 5, songName + " (" + songDifficulty + ")", true);
        songNameText.setScale(0.5 * TitleState.alphabetScale);
        songNameText.alpha = 0.9;
        add(songNameText);

        accuracyText = new Alphabet(620, 130, "Song Accuracy:", true);
        accuracyText.setScale(0.75 * TitleState.alphabetScale);
        accuracyText.screenCenter(X);
        add(accuracyText);

        accuracyCounter = new Alphabet(0, 0, "420%", true);
        accuracyCounter.screenCenter();
        accuracyCounter.x -= 20;
        accuracyCounter.y -= 140;
        add(accuracyCounter);

        rankText = new Alphabet(670, 35, "Your Rank Is:", true);
        rankText.setScale(0.75 * TitleState.alphabetScale);
        rankText.screenCenter(X);
        rankText.y = accuracyCounter.y + 90;
        rankText.alpha = 0;
        add(rankText);

        ranking = new Alphabet(450, 380, songRanking, true);
        ranking.setScale(1.3 * TitleState.alphabetScale);
        ranking.screenCenter(X);
        ranking.y -= 45;
        ranking.alpha = 0;
        add(ranking);

        basicText = new Alphabet(5, 130, 'Score: ${songScore}\\nSicks: ${sicks}\\nGoods: ${goods}\\nBads: ${bads}\\nTrashes: ${trashes}\\nMisses: ${songMisses}\\nHighest Combo: ${highestCombo}\\nTimes Died: ${gameOvers}', true);
        basicText.setScale(0.6 * TitleState.alphabetScale);
        basicText.alpha = 0;
        add(basicText);

        contText = new Alphabet(FlxG.width * 0.5, FlxG.height * 0.91, "Press ENTER To Continue", true);
        contText.setScale(0.6 * TitleState.alphabetScale);
        contText.alpha = 0;
        add(contText);

        whiteFlash = new FlxSprite().makeGraphic(FlxG.width,FlxG.height,FlxColor.WHITE);
        whiteFlash.scrollFactor.set();
        whiteFlash.alpha = 0;
        add(whiteFlash);

        switch (songRanking)
        {
            case "S" | "S+" | "S++":
                jingle = "results/SRankJingle";
                playerSound = "results/" + soundName + "_SRank";
            case "C" | "B" | "A":
                jingle = "results/C-ARankJingle";
                playerSound = "results/" + soundName + "_C-ARank";
            case "H" | "G" | "F" | "E" | "D":
                jingle = "results/H-DRankJingle";
                playerSound = "results/" + soundName + "_H-DRank";
            default:
                jingle = "results/USUKRankJingle";
                playerSound = "results/" + soundName + "_USUKRank";
        }

        music = new FlxSound().loadEmbedded(Paths.music(musicName), true, true);
        FlxG.sound.list.add(music);
		
        new FlxTimer().start(0.1, function(tmr:FlxTimer)
        {
            resultsBegin();
        });

        cameras = [FlxG.cameras.list[FlxG.cameras.list.length - 1]];

        PlayState.instance.setOnScripts('inResults', true);
		super.create();
	}


    var frames = 0;

	override function update(elapsed:Float)
	{
        PlayState.instance.callOnScripts('onUpdate', [elapsed]);

        if (resultsStarted)
        {
            if (accNum != songAccuracy)
            {
                accNum += 0.5;
                if (accNum >= songAccuracy)
                    accNum = songAccuracy;
            }
            else
            {
                rankText.alpha = 1;
            }
        }
        accuracyCounter.text = accNum + "%";
        accuracyCounter.screenCenter(X);

        // keybinds

        if (FlxG.keys.justPressed.ENTER && canExit)
        {
            PlayState.deathCounter = 0;
            music.stop();

            FlxG.sound.playMusic(Paths.music('freakyMenu'));
            FlxG.sound.music.volume = 1;
            MusicBeatState.switchState(new FreeplayState());
        }

		super.update(elapsed);

        PlayState.instance.callOnScripts('onUpdatePost', [elapsed]);
	}

    function resultsBegin()
    {
        resultsStarted = true;
        FlxG.sound.play(Paths.sound('results/Drumroll'), 1, false, null, true, function()
		{
			rankReveal();
		});
    }

    function rankReveal()
    {
        whiteFlash.alpha = 1;
        FlxTween.tween(whiteFlash, {alpha: 0}, 0.5, {ease: FlxEase.linear});
        ranking.alpha = 1;
        basicText.alpha = 1;
        FlxG.sound.play(Paths.sound(playerSound));
        FlxG.sound.play(Paths.sound(jingle), 1, false, null, true, function()
        {
            contText.alpha = 1;
            music.play();
            canExit = true;
        });
        switch (songRanking)
        {
            case "S" | "S+" | "S++":
                charSprite.animation.play('hey');
            case "C" | "B" | "A":
                charSprite.animation.play('cool');
            case "H" | "G" | "F" | "E" | "D":
                charSprite.animation.play('uncool');
            default:
                charSprite.animation.play('oof');
        }
    }

    override function destroy()
	{
		instance = null;
		super.destroy();
	}
}
