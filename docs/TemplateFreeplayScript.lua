-- Lua stuff
-- for a freeplay lua file make sure you name it "freeplay.lua"!

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
    -- triggered when you switch between songs
end

function onDifficultyChange(curDifficulty)
    -- triggered when you switch between difficulties
end

function onSongSelected(curSelected)
    -- triggered when you select a song by pressing Enter
end
