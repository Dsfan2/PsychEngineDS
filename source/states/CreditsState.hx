package states;

#if MODS_ALLOWED
import sys.FileSystem;
import sys.io.File;
#end

import objects.AttachedSprite;

class CreditsState extends MusicBeatState
{
	var curSelected:Int = -1;

	private var grpOptions:FlxTypedGroup<Alphabet>;
	private var iconArray:Array<AttachedSprite> = [];
	private var creditsStuff:Array<Array<String>> = [];

	var bg:FlxSprite;
	var descText:FlxText;
	var intendedColor:FlxColor;
	var colorTween:FlxTween;
	var descBox:AttachedSprite;

	var offsetThing:Float = -75;

	override function create()
	{
		#if desktop
		// Updating Discord Rich Presence
		DiscordClient.changePresence("In the Menus", null);
		#end

		persistentUpdate = true;
		bg = new FlxSprite().loadGraphic(Paths.image('menuDesat'));
		bg.antialiasing = ClientPrefs.data.antialiasing;
		add(bg);
		bg.screenCenter();
		
		grpOptions = new FlxTypedGroup<Alphabet>();
		add(grpOptions);

		#if MODS_ALLOWED
		for (mod in Mods.parseList().enabled) pushModCreditsToList(mod);
		#end

		var defaultList:Array<Array<String>> = [ //Name - Icon name - Description - Link - BG Color
			['Psych Engine DS'],
			['Dsfan2',				'ds',				'Modifications to Base Psych Engine',							'https://www.youtube.com/channel/UC5ll8qg39youNX11mCCwI7Q','FF0000'],
			['5hark',				'5hark',			'New Pixel Monika Sprites & Dsfan2 Sprites',					'https://gamebanana.com/members/2282488','4DA6FF'],
			['CheezyLover',			'cheeze',			'New Bowser Jr Sprites & New Monika Sprites',					'https://gamebanana.com/members/2115914','DD33FF'],
			['Monika_Fan',			'monikafan',		'Wendy O Koopa & Pixel Bowser Jr Sprites',						'https://gamebanana.com/members/1938973','8F8F8F'],
			['Sourcandee',			'sourcandee',		'Help with FLPs',												'https://www.youtube.com/channel/UCiwDmzTrSPwsb-ZiyUWBTKw','80FF66'],
			['kamvoy',				'kamvoy',			'New Pixel BF & GF Sprites',									'https://gamebanana.com/members/1827340','4DA6FF'],
			['RonaTheRTD',			'rona',				'Pico Dialogue Sprites',										'https://gamebanana.com/members/1634532', 'FFFFFF'],
			['Sage_With_A_V',		'sage',				'Left Side Boyfriend Sprites',									'https://gamebanana.com/members/2186896','FFFFFF'],
			['DrkFon376',			'drkfon',			'Speakers Only Assets',											'https://gamebanana.com/members/1835098', 'FFFFFF'],
			['Elizm',				'elizm',			'BotPlay & Practice Text Sprites',								'https://gamebanana.com/members/2136991','FFFF00'],
			['DusterBuster',		'duster',			'New Winning Icons for Dad, Spooky, Pico, & Tankman',			'https://gamebanana.com/members/1497332','4DA6FF'],
			['Logan McOof',			'loof',				'Boyfriend Soundfont In Week ?',								'https://gamebanana.com/members/1807144','FFFFFF'],
			['objectshowmaster',	'osm',				'Monika Soundfont',												'https://gamebanana.com/members/2013618','80FF00'],
			['Tour de Pizza',		'peppino',			'Pizza Tower References & Sprites',								'https://twitter.com/PizzaTowergame',	 'FFFFFF'],
			['NoahGani1',			'gani',				'Peppino Soundfont (FNATPT)',									'https://gamebanana.com/members/2089459','FFFFFF'],
			['Rozebud',				'rozebud',			'Inspiration for the ChartingState things (FPS Plus)',			'https://gamebanana.com/members/1767623','FFFFFF'],
			['Danur S.',			'danur',			'Tankman Ascends Video inspiration & Green Screen used',		'https://www.youtube.com/watch?v=ZWIs_4k6ICE', 'FFFFFF'],
			[''],
			['Former Engine Contributors'],
			["DMZapp",				'sr',				"Old Bowser Jr Sprites (Spriter's Resource)",					'https://www.spriters-resource.com/custom_edited/mariocustoms/sheet/144817/','FFD500'],
			['SANTIAGO GAMER FAN',	'santiago',			'Old Monika Sprites',											'https://gamebanana.com/members/1796601','99E600'],
			['WALLKSss',			'walk',				'Old Pixel Monika Sprites',										'https://gamebanana.com/members/2105493','FFDD99'],
			[''],
			['OG Psych Engine Team'],
			['Shadow Mario',		'shadowmario',		'Main Programmer of Psych Engine',								'https://twitter.com/Shadow_Mario_',	'444444'],
			['Riveren',				'riveren',			'Main Artist/Animator of Psych Engine',							'https://twitter.com/riverennn',		'B42F71'],
			['shubs',				'shubs',			'Ex-Programmer of Psych Engine',								'https://twitter.com/yoshubs',			'5E99DF'],
			['bb-panzu',			'bb',				'Ex-Programmer of Psych Engine',								'https://twitter.com/bbsub3',			'3E813A'],
			[''],
			['OG Psych Engine Contributors'],
			['iFlicky',				'flicky',			'Composer of Psync and Tea Time\nMade the Dialogue Sounds',		'https://twitter.com/flicky_i',			'9E29CF'],
			['SqirraRNG',			'sqirra',			'Crash Handler and Base code for\nChart Editor\'s Waveform',	'https://twitter.com/gedehari',			'E1843A'],
			['EliteMasterEric',		'mastereric',		'Runtime Shaders support',										'https://twitter.com/EliteMasterEric',	'FFBD40'],
			['PolybiusProxy',		'proxy',			'.MP4 Video Loader Library (hxCodec)',							'https://twitter.com/polybiusproxy',	'DCD294'],
			['KadeDev',				'kade',				'Fixed some cool stuff on Chart Editor\nand other PRs',			'https://twitter.com/kade0912',			'64A250'],
			['Keoiki',				'keoiki',			'Note Splash Animations and Latin Alphabet',					'https://twitter.com/Keoiki_',			'D2D2D2'],
			['superpowers04',		'superpowers04',	'LUA JIT Fork',													'https://twitter.com/superpowers04',	'B957ED'],
			['Smokey',				'smokey',			'Sprite Atlas Support',											'https://twitter.com/Smokey_5_',		'483D92'],
			[''],
			["Funkin' Crew"],
			['NinjaMuffin99',		'ninjamuffin99',	"Programmer of Friday Night Funkin'",							'https://twitter.com/ninja_muffin99',	'CF2D2D'],
			['PhantomArcade',		'phantomarcade',	"Animator of Friday Night Funkin'",								'https://twitter.com/PhantomArcade3K',	'FADC45'],
			['evilsk8r',			'evilsk8r',			"Artist of Friday Night Funkin'",								'https://twitter.com/evilsk8r',			'5ABD4B'],
			['kawaisprite',			'kawaisprite',		"Composer of Friday Night Funkin'",								'https://twitter.com/kawaisprite',		'378FC7']
		];
		
		for(i in defaultList) {
			creditsStuff.push(i);
		}
	
		for (i in 0...creditsStuff.length)
		{
			var isSelectable:Bool = !unselectableCheck(i);
			var optionText:Alphabet = new Alphabet(FlxG.width / 2, 300, creditsStuff[i][0], !isSelectable);
			optionText.setScale(1 * TitleState.alphabetScale);
			optionText.isMenuItem = true;
			optionText.targetY = i;
			optionText.changeX = false;
			optionText.snapToPosition();
			grpOptions.add(optionText);

			if(isSelectable) {
				if(creditsStuff[i][5] != null)
				{
					Mods.currentModDirectory = creditsStuff[i][5];
				}

				var str:String = 'credits/missing_icon';
				if (Paths.image('credits/' + creditsStuff[i][1]) != null) str = 'credits/' + creditsStuff[i][1];
				var icon:AttachedSprite = new AttachedSprite(str);
				icon.xAdd = optionText.width + 10;
				icon.sprTracker = optionText;
	
				// using a FlxGroup is too much fuss!
				iconArray.push(icon);
				add(icon);
				Mods.currentModDirectory = '';

				if(curSelected == -1) curSelected = i;
			}
			else optionText.alignment = CENTERED;
		}
		
		descBox = new AttachedSprite();
		descBox.makeGraphic(1, 1, FlxColor.BLACK);
		descBox.xAdd = -10;
		descBox.yAdd = -10;
		descBox.alphaMult = 0.6;
		descBox.alpha = 0.6;
		add(descBox);

		descText = new FlxText(50, FlxG.height + offsetThing - 25, 1180, "", 32);
		descText.setFormat(Paths.font("vcr.ttf"), 32, FlxColor.WHITE, CENTER);
		descText.scrollFactor.set();
		descBox.sprTracker = descText;
		add(descText);

		bg.color = CoolUtil.colorFromString(creditsStuff[curSelected][4]);
		intendedColor = bg.color;
		changeSelection();
		super.create();
	}

	var quitting:Bool = false;
	var holdTime:Float = 0;
	override function update(elapsed:Float)
	{
		if (FlxG.sound.music.volume < 0.7)
		{
			FlxG.sound.music.volume += 0.5 * FlxG.elapsed;
		}

		if(!quitting)
		{
			if(creditsStuff.length > 1)
			{
				var shiftMult:Int = 1;
				if(FlxG.keys.pressed.SHIFT) shiftMult = 3;

				var upP = controls.UI_UP_P;
				var downP = controls.UI_DOWN_P;

				if (upP)
				{
					changeSelection(-shiftMult);
					holdTime = 0;
				}
				if (downP)
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
					{
						changeSelection((checkNewHold - checkLastHold) * (controls.UI_UP ? -shiftMult : shiftMult));
					}
				}
			}

			if(controls.ACCEPT && (creditsStuff[curSelected][3] == null || creditsStuff[curSelected][3].length > 4)) {
				CoolUtil.browserLoad(creditsStuff[curSelected][3]);
			}
			if (controls.BACK)
			{
				if(colorTween != null) {
					colorTween.cancel();
				}
				FlxG.sound.play(Paths.sound('cancelMenu'));
				MusicBeatState.switchState(new MainMenuState());
				quitting = true;
			}
		}
		
		for (item in grpOptions.members)
		{
			if(!item.bold)
			{
				var lerpVal:Float = FlxMath.bound(elapsed * 12, 0, 1);
				if(item.targetY == 0)
				{
					var lastX:Float = item.x;
					item.screenCenter(X);
					item.x = FlxMath.lerp(lastX, item.x - 70, lerpVal);
				}
				else
				{
					item.x = FlxMath.lerp(item.x, 200 + -40 * Math.abs(item.targetY), lerpVal);
				}
			}
		}
		super.update(elapsed);
	}

	var moveTween:FlxTween = null;
	function changeSelection(change:Int = 0)
	{
		FlxG.sound.play(Paths.sound('scrollMenu'), 0.4);
		do {
			curSelected += change;
			if (curSelected < 0)
				curSelected = creditsStuff.length - 1;
			if (curSelected >= creditsStuff.length)
				curSelected = 0;
		} while(unselectableCheck(curSelected));

		var newColor:FlxColor = CoolUtil.colorFromString(creditsStuff[curSelected][4]);
		trace('The BG color is: $newColor');
		if(newColor != intendedColor) {
			if(colorTween != null) {
				colorTween.cancel();
			}
			intendedColor = newColor;
			colorTween = FlxTween.color(bg, 1, bg.color, intendedColor, {
				onComplete: function(twn:FlxTween) {
					colorTween = null;
				}
			});
		}

		var bulltrash:Int = 0;

		for (item in grpOptions.members)
		{
			item.targetY = bulltrash - curSelected;
			bulltrash++;

			if(!unselectableCheck(bulltrash-1)) {
				item.alpha = 0.6;
				if (item.targetY == 0) {
					item.alpha = 1;
				}
			}
		}

		descText.text = creditsStuff[curSelected][2];
		descText.y = FlxG.height - descText.height + offsetThing - 60;

		if(moveTween != null) moveTween.cancel();
		moveTween = FlxTween.tween(descText, {y : descText.y + 75}, 0.25, {ease: FlxEase.sineOut});

		descBox.setGraphicSize(Std.int(descText.width + 20), Std.int(descText.height + 25));
		descBox.updateHitbox();
	}

	#if MODS_ALLOWED
	function pushModCreditsToList(folder:String)
	{
		var creditsFile:String = null;
		if(folder != null && folder.trim().length > 0) creditsFile = Paths.mods(folder + '/data/credits.txt');
		else creditsFile = Paths.mods('data/credits.txt');

		if (FileSystem.exists(creditsFile))
		{
			var firstarray:Array<String> = File.getContent(creditsFile).split('\n');
			for(i in firstarray)
			{
				var arr:Array<String> = i.replace('\\n', '\n').split("::");
				if(arr.length >= 5) arr.push(folder);
				creditsStuff.push(arr);
			}
			creditsStuff.push(['']);
		}
	}
	#end

	private function unselectableCheck(num:Int):Bool {
		return creditsStuff[num].length <= 1;
	}
}