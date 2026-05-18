extends Node

## Lista de músicas del juego
var music_list: Dictionary = {
	"Menu": load("res://assets/audio/music/menu.mp3"),
	"Battle mode": load("res://assets/audio/music/let_the_battle_begin.mp3"),
	"Dungeon mode": load("res://assets/audio/music/exploring_the_dungeon.mp3"),
	"Dungeon boss": load("res://assets/audio/music/battle_against_the_dungeon_boss.mp3"),
	"Win": load("res://assets/audio/music/you_win.mp3"),
	"Lose": load("res://assets/audio/music/you_lost.mp3")
}

## Lista de sonidos del juego
var sfx_list: Dictionary = {
	"Click": load("res://assets/audio/sfx/click.mp3"),
	"Hit": load("res://assets/audio/sfx/hit.mp3"),
	"Heal": load("res://assets/audio/sfx/heal.mp3"),
	"Buff": load("res://assets/audio/sfx/buff.mp3"),
	"Debuff": load("res://assets/audio/sfx/debuff.mp3"),
	"Level Up": load("res://assets/audio/sfx/level_up.mp3"),
	"Key": load("res://assets/audio/sfx/key_obtained.mp3")
}

## Reproductor de música
@onready var music_player: AudioStreamPlayer = $Music

## Reproductor de sonidos
@onready var sfx_player: AudioStreamPlayer = $SFX

## Reproduce la música seleccionada en el juego
func play_music(music: String):
	# Si la que se estaba reproduciendo era otra música y existe la solicitada en la lista, la cambia en el reproductor, de lo contrario, deja la que estaba
	if music_list.has(music) and music_player.stream != music_list[music]:
		music_player.stop()
		
		music_player.stream = music_list[music]
		music_player.play()

## Reproduce el sonido seleccionado en el juego
func play_sfx(sfx: String):
	# Si existe el sonido solicitado en la lista, lo reproduce
	if sfx_list.has(sfx):
		sfx_player.stop()
		
		sfx_player.stream = sfx_list[sfx]
		sfx_player.play()
