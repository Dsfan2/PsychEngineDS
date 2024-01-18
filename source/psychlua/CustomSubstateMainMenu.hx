package psychlua;

import flixel.FlxObject;

class CustomSubstateMainMenu extends MusicBeatSubstate
{
	public static var name:String = 'unnamed';
	public static var instance:CustomSubstateMainMenu;

	public static function implement(funk:MainMenuLua)
	{
		#if LUA_ALLOWED
		var lua = funk.lua;
		Lua_helper.add_callback(lua, "openCustomSubstate", openCustomSubstate);
		Lua_helper.add_callback(lua, "closeCustomSubstate", closeCustomSubstate);
		Lua_helper.add_callback(lua, "insertToCustomSubstate", insertToCustomSubstate);
		#end
	}
	
	public static function openCustomSubstate(name:String, ?pauseGame:Bool = false)
	{
		if(pauseGame)
		{
			FlxG.camera.followLerp = 0;
			MainMenuState.instance.persistentUpdate = false;
			MainMenuState.instance.persistentDraw = true;
			MainMenuState.instance.paused = true;
		}
		MainMenuState.instance.openSubState(new CustomSubstateMainMenu(name));
		MainMenuState.instance.setOnHScript('customSubstate', instance);
		MainMenuState.instance.setOnHScript('customSubstateName', name);
	}

	public static function closeCustomSubstate()
	{
		if(instance != null)
		{
			MainMenuState.instance.closeSubState();
			instance = null;
			return true;
		}
		return false;
	}

	public static function insertToCustomSubstate(tag:String, ?pos:Int = -1)
	{
		if(instance != null)
		{
			var tagObject:FlxObject = cast (MainMenuState.instance.variables.get(tag), FlxObject);
			#if LUA_ALLOWED if(tagObject == null) tagObject = cast (MainMenuState.instance.modchartSprites.get(tag), FlxObject); #end

			if(tagObject != null)
			{
				if(pos < 0) instance.add(tagObject);
				else instance.insert(pos, tagObject);
				return true;
			}
		}
		return false;
	}

	override function create()
	{
		instance = this;

		MainMenuState.instance.callOnScripts('onCustomSubstateCreate', [name]);
		super.create();
		MainMenuState.instance.callOnScripts('onCustomSubstateCreatePost', [name]);
	}
	
	public function new(name:String)
	{
		CustomSubstateMainMenu.name = name;
		super();
		cameras = [FlxG.cameras.list[FlxG.cameras.list.length - 1]];
	}
	
	override function update(elapsed:Float)
	{
		MainMenuState.instance.callOnScripts('onCustomSubstateUpdate', [name, elapsed]);
		super.update(elapsed);
		MainMenuState.instance.callOnScripts('onCustomSubstateUpdatePost', [name, elapsed]);
	}

	override function destroy()
	{
		MainMenuState.instance.callOnScripts('onCustomSubstateDestroy', [name]);
		name = 'unnamed';

		MainMenuState.instance.setOnHScript('customSubstate', null);
		MainMenuState.instance.setOnHScript('customSubstateName', name);
		super.destroy();
	}
}
