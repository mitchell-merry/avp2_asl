state("lithtech") {
    byte gameState: "d3d.ren", 0x5627C;
    // string32 levelName: "object.lto", 0x2FD9B4;
    bool hasControl: "cshell.dll", 0x1C9A64, 0xD2C, 0x0;
    int health: "cshell.dll", 0x1c5868, 0x788;
}

startup {
    vars.InGame = 0x88;
    vars.PauseMenu = 0xA0;
    vars.MainMenu = 0xC8;
    vars.Loading = 0x98;
    vars.GameNotLoaded = 0x0;

    vars.campaignStartLevels = new string[] { "A1S1", "M1S1", "P1S1" };
    vars.campaignEndLevels = new string[] { "A7S3", "M7S2", "P7S2" }; 
    // vars.missionStartLevels = new string[] { "P1S1", "P2S1"}
    vars.levelsToNotStartOn = new string[] { "A_OPEN", "M_OPEN", "P_OPEN", "M_CLOSE", "P_OPEN", "OUTRO" };
    vars.levelsToNotSplitOn = new string[] { "A4S1", "M3S1", "M4S1", "A_OPEN", "M_OPEN", "P_OPEN" };

    settings.Add("mission_timer", false, "Mission timer mode. (For ILs)");
}

init { 
    version = "ASL: 0.3.0";

    // vars.Watchers = new MemoryWatcherList
    // {
    //     new StringWatcher(new DeepPointer("object.lto", 0x2FD9B4), 32) { Name = "levelWatcher" }
    // };
}

update {
    // vars.Watchers.UpdateAll(game); 
    var levelP = new DeepPointer("object.lto", 0x2FD9B4);
    current.levelName = levelP.DerefString(game, ReadStringType.UTF8, 32);
    return;
    // return;
    // byte[] bytes = new byte[32];
    // levelP.DerefBytes(game, 32, out bytes);
    // var sb = new StringBuilder("new byte[] { ");
    // foreach (var b in bytes)
    // {
    //     sb.Append(b + ", ");
    // }
    // sb.Append("}");

    // print("ASL: " + sb.ToString());

    if(game.ModulesWow64Safe() == null) return;
    ProcessModuleWow64Safe module = game.ModulesWow64Safe().FirstOrDefault(m => m.ModuleName.ToLower() == "object.lto");
    if(module == null) {
        print("ASL: module object.lto not found.");
        return;
    }
    print("ASL: " + module.BaseAddress.ToString("X"));
    // print("ASL: " + levelP);
    
    // pm = new ProcessMemory(_process, (IntPtr)_process.Id);
    // IntPtr addr = 0x0;
    game.Refresh(); //idk what this does
    foreach (ProcessModuleWow64Safe __module in game.ModulesWow64Safe())
    {    
            print(String.Format("ASL: {0} - {1:X}", __module.ModuleName, __module.BaseAddress));    
        // if (__module.ModuleName == "object.lto")
        // {
        //     // addr = (int)__module.BaseAddress;
        // }
    }

    // foreach (ProcessModule __module in game.Modules)
    // {        
    //         print(String.Format("ASL: {0} - {1:X}", __module.ModuleName, __module.BaseAddress));
    //     if (__module.ModuleName == "object.lto")
    //     {
    //         // addr = __module.BaseAddress;
    //     }
    // }

    // print(String.Format("ASL: object.lto [{0:X}]", addr));
    // print("ASL: watcher [" + vars.Watchers["levelWatcher"].Current.ToString() + "]");
}

isLoading
{
    if(current.gameState == null) return false;

    return current.gameState == vars.Loading; // you reckon
}

start
{
    

    if(current.levelName == null || current.gameState == null || old.hasControl == null || current.hasControl == null || current.health == null) {
        // print("-----------------------");
        // print("ASL current.levelName: " + (current.levelName == null));
        // print("ASL current.gameState: " + (current.gameState == null));
        // print("ASL old.hasControl: " + (old.hasControl == null));
        // print("ASL current.hasControl: " + (current.hasControl == null));
        // print("ASL current.health: " + (current.health == null));
        return false;
    }

    // don't start on these levels
    if(Array.IndexOf(vars.levelsToNotStartOn, current.levelName) != -1) return false;

    // if mission timer is enabled, start only if it's a mission level & after you finish loading
    if(settings["mission_timer"]) {
        return 
            old.gameState == vars.Loading && current.gameState == vars.InGame;
    }

    // if its a campaign start level
    if(Array.IndexOf(vars.campaignStartLevels, current.levelName) != -1) {
        // start once you gain control
        return !old.hasControl && current.hasControl;
    } 

    return false;
}

split
{
    if(current.levelName == null || old.levelName == null || old.hasControl == null || current.hasControl == null || current.gameState == null) return false;

    // don't split on these levels
    if(Array.IndexOf(vars.levelsToNotSplitOn, current.levelName) != -1) return false;

    // print("ASL: ["+ + current.levelName + "]");
    // if we are on an end level
    if(Array.IndexOf(vars.campaignEndLevels, current.levelName) != -1) {
        // print("ASL: " + (old.levelName != current.levelName).ToString());
        // split if we just entered this level (so the previous split)
        if(old.levelName != current.levelName) return true;

        // split when we lose control but we didnt die
        return old.hasControl && !current.hasControl && current.health > 0;
    }

    // print("ASL: " + (old.levelName != current.levelName).ToString());

    // otherwise split when we load the next level
	return old.levelName != current.levelName && current.gameState != vars.MainMenu;
}

reset
{
	
}