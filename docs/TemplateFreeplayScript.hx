// HScript stuff
// For a freeplay hscript file make sure you name it "freeplay.hx"!

function onCreate()
{
	// triggered when the hscript file is started, some variables weren't created yet
}

function onCreatePost()
{
	// end of "create"
}

function onDestroy()
{
	// triggered when the haxe file is ended (Song fade out finished)
}

function onUpdate(elapsed:Float)
{
	// start of "update", some variables weren't updated yet
}

function onUpdatePost(elapsed:Float)
{
	// end of "update"
}

function onSelectionChange(curSelected:Int)
{
    // triggered when you switch between songs
}

function onDifficultyChange(curDifficulty:Int)
{
    // triggered when you switch between difficulties
}

function onSongSelected(curSelected:Int)
{
    // triggered when you select a song by pressing Enter
}