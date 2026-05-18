extends Node

## Lista de los equipos que hay creados en el juego
var teams : Array[Team]

## Diccionario con los modos del juego y sus datos
var modes = {
	Mode.Type.BATTLE: BattleMode.new(),
	Mode.Type.DUNGEON: DungeonMode.new(),
}

## Modo actual de la partida (Battle mode, Dungeon mode...)
var actual_mode: Mode

## Índice del equipo que se está editando
var team_in_edition: int

## Configuración del juego
var config = ConfigData.new()
