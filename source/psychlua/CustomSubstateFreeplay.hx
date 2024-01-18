package psychlua;

import flixel.FlxObject;

class CustomSubstateFreeplay extends MusicBeatSubstate
{
	public static var name:String = 'unnamed';
	public static var instance:CustomSubstateFreeplay;

	public static function implement(funk:FreeplayLua)
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
			FreeplayState.instance.persistentUpdate = false;
			FreeplayState.instance.persistentDraw = true;
			FreeplayState.instance.paused = true;
		}
		FreeplayState.instance.openSubState(new CustomSubstateFreeplay(name));
		FreeplayState.instance.setOnHScript('customSubstate', instance);
		FreeplayState.instance.setOnHScript('customSubstateName', name);
	}

	public static function closeCustomSubstate()
	{
		if(instance != null)
		{
			FreeplayState.instance.closeSubState();
			instance = null;
			return true;
		}
		return false;
	}

	public static function insertToCustomSubstate(tag:String, ?pos:Int = -1)
	{
		if(instance != null)
		{
			var tagObject:FlxObject = cast (FreeplayState.instance.variables.get(tag), FlxObject);
			#if LUA_ALLOWED if(tagObject == null) tagObject = cast (FreeplayState.instance.modchartSprites.get(tag), FlxObject); #end

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

		FreeplayState.instance.callOnScripts('onCustomSubstateCreate', [name]);
		super.create();
		FreeplayState.instance.callOnScripts('onCustomSubstateCreatePost', [name]);
	}
	
	public function new(name:String)
	{
		CustomSubstateFreeplay.name = name;
		super();
		cameras = [FlxG.cameras.list[FlxG.cameras.list.length - 1]];
	}
	
	override function update(elapsed:Float)
	{
		FreeplayState.instance.callOnScripts('onCustomSubstateUpdate', [name, elapsed]);
		super.update(elapsed);
		FreeplayState.instance.callOnScripts('onCustomSubstateUpdatePost', [name, elapsed]);
	}

	override function destroy()
	{
		FreeplayState.instance.callOnScripts('onCustomSubstateDestroy', [name]);
		name = 'unnamed';

		FreeplayState.instance.setOnHScript('customSubstate', null);
		FreeplayState.instance.setOnHScript('customSubstateName', name);
		super.destroy();
	}
}
