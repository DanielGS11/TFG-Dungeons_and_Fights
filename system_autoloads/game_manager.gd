extends Node

var teams : Array[Team] = [Team.new(), Team.new(), Team.new(), Team.new(), Team.new()]

var modes = {
	Mode.Type.BATTLE: BattleMode.new(),
	Mode.Type.DUNGEON: DungeonMode.new(),
}

var actual_mode: Mode

var config = ConfigData.new()
