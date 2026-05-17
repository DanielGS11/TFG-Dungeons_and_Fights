extends Node

var teams : Array[Team]

var modes = {
	Mode.Type.BATTLE: BattleMode.new(),
	Mode.Type.DUNGEON: DungeonMode.new(),
}

var actual_mode: Mode

var team_in_edition: int

var config = ConfigData.new()
