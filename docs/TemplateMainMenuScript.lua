-- Lua stuff
-- for a main menu lua file make sure you name it "mainmenu.lua"!

function onCreate()
	-- triggered when the lua file is started, some variables weren't created yet
end

function onCreatePost()
	-- end of "create"
end

function onDestroy()
	-- triggered when the lua file is ended (Song fade out finished)
end

function onUpdate(elapsed)
	-- start of "update", some variables weren't updated yet
end

function onUpdatePost(elapsed)
	-- end of "update"
end

function onSelectionChange(curSelected)
    -- triggered when you switch between menu items
end

function onItemSelected(curSelected)
    -- tiggered when you select an option by pressing Enter
end
