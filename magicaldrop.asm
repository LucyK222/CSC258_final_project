################# CSC258 Assembly Final Project ###################
# This file contains our implementation of Magical Drop.
#
# Student 1: Jiayun Kang, 1009918074
# Student 2: Bowen Guang, 1010490808
#
# We assert that the code submitted here is entirely our own 
# creation, and will indicate otherwise when it is not.
#
######################## Bitmap Display Configuration ########################
# - Unit width in pixels:       8
# - Unit height in pixels:      8
# - Display width in pixels:    512
# - Display height in pixels:   512
# - Base Address for Display:   0x10008000 ($gp)
##############################################################################

    .data
##############################################################################
# Immutable Data
##############################################################################
# The address of the bitmap display. Don't forget to connect it!
ADDR_DSPL:
    .word 0x10008000
# The address of the keyboard. Don't forget to connect it!
ADDR_KBRD:
    .word 0xffff0000

# AI-assisted implementation; review and disclose assistance under course rules.
# CSC258 Magical Drop - Milestone up to 4
# Bitmap configuration: 64x64 logical units, base 0x10008000
# Keyboard: MARS Keyboard and Display MMIO / Saturn Bitmap input

# Bubble colors
bubble_colors:
    .word 0xff0000, 0x00ff00, 0x0000ff, 0xffff00
# GAME OVER DISPLAY MESSAGES
game_over_message: .asciiz "GAME\nOVER\nYOU LOST\nR: RESTART | Q: QUIT\n"
game_over_line1:   .asciiz "GAME"
game_over_line2:   .asciiz "OVER"
game_over_line3:   .asciiz "YOU LOST"

# STRING for REPLAY, QUIT, PAUSE/RESUME MESSAGES
replay_text:      .asciiz "R REPLAY"
quit_text:        .asciiz "Q QUIT"
pause_text:       .asciiz "PAUSED"
resume_text:      .asciiz "P RESUME"

# Compact 3x5 uppercase font: ASCII code followed by five 3-bit row masks.
# Each mask uses bit 2 for the left pixel, bit 1 for center, bit 0 for right.
bitmap_letters:
    .byte 71, 7,4,5,5,7       # G
    .byte 65, 2,5,7,5,5       # A
    .byte 77, 5,7,7,5,5       # M
    .byte 69, 7,4,6,4,7       # E
    .byte 79, 7,5,5,5,7       # O
    .byte 86, 5,5,5,5,2       # V
    .byte 82, 6,5,6,5,5       # R
    .byte 89, 5,5,2,2,2       # Y
    .byte 85, 5,5,5,5,7       # U
    .byte 76, 4,4,4,4,7       # L
    .byte 83, 7,4,7,1,7       # S
    .byte 84, 7,2,2,2,2       # T

    #Figure for the Steve on the right
    .byte 78, 5,7,7,7,5       # N
    .byte 66, 6,5,6,5,6       # B
    .byte 68, 6,5,5,5,6       # D
    .byte 73, 7,2,2,2,7       # I
    .byte 33, 2,2,2,0,2       # !
    .byte 80, 6,5,6,4,4       # P
    .byte 81, 7,5,5,7,1       # Q [REPLAY/PAUSE]
    .byte 0

steve_title:      .asciiz "STEVE"
steve_emmm:       .asciiz "EMMM!"
steve_not:        .asciiz "NOT"
steve_bad:        .asciiz "BAD!"
steve_smart:      .asciiz "SMART!"
steve_genius:     .asciiz "GENIUS!"
steve_dumb:       .asciiz "DUMB"

# The bit for the Steve NPC
# 10x16 where 0 transparent, 1 hair, 2 skin,
# 3 cyan shirt, 4 pants, 5 eyes, 6 nose 
# Notice: One sprite pixel = 1 bitmap unit
steve_sprite:
    .byte 0,0,1,1,1,1,1,1,0,0
    .byte 0,1,1,1,1,1,1,1,1,0
    .byte 0,1,2,2,2,2,2,2,1,0
    .byte 0,2,5,2,2,2,5,2,2,0
    .byte 0,2,2,2,2,2,2,2,2,0
    .byte 0,2,2,2,6,6,2,2,2,0
    .byte 0,0,2,2,2,2,2,2,0,0
    .byte 0,0,3,3,3,3,3,3,0,0
    .byte 0,3,3,3,3,3,3,3,3,0
    .byte 2,3,3,3,3,3,3,3,3,2
    .byte 2,3,3,3,3,3,3,3,3,2
    .byte 0,0,3,3,3,3,3,3,0,0
    .byte 0,0,4,4,4,4,4,4,0,0
    .byte 0,0,4,4,0,0,4,4,0,0
    .byte 0,0,4,4,0,0,4,4,0,0
    .byte 0,0,4,4,0,0,4,4,0,0
# Color palette indexed by the steve_sprite digits.
    .align 2
steve_palette:
    .word 0x000000, 0x49301e, 0xb98a61, 0x39c1c7
    .word 0x34359c, 0x17253c, 0x7a5038

# 4x4 Poop Sprites (4 angles for 360-degree flip)
poop_0:
    .word 0x000000, 0x92400E, 0x000000, 0x000000
    .word 0x92400E, 0xD6A56D, 0x92400E, 0x000000
    .word 0x292524, 0x92400E, 0x92400E, 0x92400E
    .word 0x92400E, 0x292524, 0x292524, 0x92400E

poop_90:
    .word 0x92400E, 0x292524, 0x92400E, 0x000000
    .word 0x292524, 0x92400E, 0xD6A56D, 0x92400E
    .word 0x292524, 0x92400E, 0x92400E, 0x000000
    .word 0x92400E, 0x92400E, 0x000000, 0x000000

poop_180:
    .word 0x92400E, 0x292524, 0x292524, 0x92400E
    .word 0x92400E, 0x92400E, 0x92400E, 0x292524
    .word 0x000000, 0x92400E, 0xD6A56D, 0x92400E
    .word 0x000000, 0x000000, 0x92400E, 0x000000

poop_270:
    .word 0x000000, 0x000000, 0x92400E, 0x92400E
    .word 0x000000, 0x92400E, 0x92400E, 0x292524
    .word 0x92400E, 0xD6A56D, 0x92400E, 0x292524
    .word 0x000000, 0x92400E, 0x292524, 0x92400E
    
pink_bow:
    .word 0x000000, 0xff69b4, 0x000000
    .word 0xff69b4, 0xff1493, 0xff69b4
    .word 0x000000, 0xff69b4, 0x000000

    .align 2

# Music Implementation: Original supplied MIDI event table
# WetHands.mid piano notes: start (ms), pitch, duration (ms), velocity.
bgm_notes:
    .word     0, 45,  394, 56
    .word   417, 49,  394, 56
    .word   833, 57,  394, 69
    .word  1250, 59,  394, 73
    .word  1667, 61,  394, 64
    .word  2083, 59,  394, 62
    .word  2500, 57,  394, 62
    .word  2917, 52,  394, 57
    .word  3333, 50,  394, 59
    .word  3750, 54,  394, 61
    .word  4167, 61,  394, 73
    .word  4583, 64,  394, 81
    .word  5000, 61,  394, 55
    .word  5417, 57, 1185, 53
    .word  6667, 45,  394, 51
    .word  7083, 49,  394, 55
    .word  7500, 57,  394, 67
    .word  7917, 59,  394, 74
    .word  8333, 61,  394, 64
    .word  8750, 59,  394, 58
    .word  9167, 57,  394, 62
    .word  9583, 52,  394, 59
    .word 10000, 50,  394, 58
    .word 10417, 54,  394, 62
    .word 10833, 61,  394, 72
    .word 11250, 64,  394, 82
    .word 11667, 61,  394, 53
    .word 12083, 57, 1186, 50
    .word 13333, 45,  394, 52
    .word 13333, 68, 2374, 49
    .word 13750, 49,  394, 56
    .word 14167, 57,  394, 66
    .word 14583, 59,  394, 66
    .word 15000, 61,  394, 70
    .word 15417, 59,  394, 68
    .word 15833, 57,  415, 53
    .word 15833, 69,  790, 63
    .word 16250, 52,  394, 48
    .word 16667, 50,  394, 80
    .word 16667, 66, 2373, 78
    .word 17083, 54,  394, 85
    .word 17500, 61,  394, 98
    .word 17917, 64,  394, 110
    .word 18333, 61,  394, 81
    .word 18750, 57, 1186, 73
    .word 19167, 64,  394, 78
    .word 19583, 66,  394, 87
    .word 20000, 45,  394, 72
    .word 20000, 68, 2373, 92
    .word 20417, 49,  394, 74
    .word 20833, 57,  394, 88
    .word 21250, 59,  394, 93
    .word 21667, 61,  394, 92
    .word 22083, 59,  394, 90
    .word 22500, 57,  394, 85
    .word 22500, 71,  394, 95
    .word 22917, 52,  394, 81
    .word 22917, 73,  394, 89
    .word 23333, 50,  394, 79
    .word 23750, 54,  394, 85
    .word 23750, 66, 1977, 72
    .word 24167, 61,  394, 98
    .word 24583, 64,  394, 108
    .word 25000, 61,  394, 79
    .word 25417, 57,  394, 70
    .word 25833, 73,  394, 104
    .word 26250, 76,  394, 93
    .word 26667, 43,  394, 74
    .word 26667, 79, 1185, 96
    .word 27083, 47,  394, 78
    .word 27500, 50,  394, 87
    .word 27917, 54,  394, 88
    .word 27917, 78,  394, 81
    .word 28333, 57,  415, 85
    .word 28333, 74,  790, 75
    .word 28750, 54,  394, 80
    .word 29167, 50,  394, 76
    .word 29167, 69,  394, 72
    .word 29583, 47,  394, 74
    .word 29583, 71, 3561, 87
    .word 30000, 43,  394, 80
    .word 30417, 47,  394, 88
    .word 30833, 50,  394, 89
    .word 31250, 54,  394, 92
    .word 31667, 57, 1581, 95
    .word 33333, 43,  415, 86
    .word 33333, 79,  790, 119
    .word 33750, 47,  394, 93
    .word 34167, 50,  415, 102
    .word 34167, 78,  790, 95
    .word 34583, 54,  394, 100
    .word 35000, 57,  415, 104
    .word 35000, 74,  790, 92
    .word 35417, 54,  394, 101
    .word 35833, 50,  394, 93
    .word 35833, 69,  394, 83
    .word 36250, 47,  394, 94
    .word 36250, 71, 2769, 98
    .word 36667, 43,  394, 95
    .word 37083, 47,  394, 103
    .word 37500, 50,  394, 101
    .word 37917, 54,  394, 108
    .word 38333, 57, 1582, 103
    .word 39167, 69,  790, 91
    .word 40000, 45,  394, 83
    .word 40000, 64,  790, 81
    .word 40417, 49,  394, 84
    .word 40833, 57,  394, 86
    .word 41250, 59,  394, 118
    .word 41667, 61,  394, 105
    .word 42083, 59,  394, 100
    .word 42500, 57,  394, 91
    .word 42917, 52,  394, 83
    .word 43333, 45,  394, 88
    .word 43750, 49,  394, 88
    .word 44167, 52,  394, 107
    .word 44583, 57,  394, 80
    .word 45000, 61,  394, 106
    .word 45417, 64,  394, 113
    .word 45833, 69,  394, 121
    .word 46250, 73,  592, 127
    .word 50000, 47,  394, 81
    .word 50000, 66, 1186, 91
    .word 50000, 71, 1186, 91
    .word 50000, 74, 1186, 91
    .word 50417, 50,  394, 87
    .word 50833, 54,  394, 105
    .word 51250, 57,  394, 108
    .word 51250, 73,  394, 97
    .word 51667, 66,  790, 84
    .word 51667, 69,  790, 84
    .word 51667, 61, 1581, 112
    .word 52500, 64,  394, 120
    .word 52500, 76,  394, 120
    .word 52917, 66,  394, 105
    .word 52917, 78,  394, 105
    .word 53333, 47,  394, 84
    .word 53750, 50,  394, 85
    .word 53750, 74, 1977, 88
    .word 54167, 54,  394, 108
    .word 54583, 57,  394, 115
    .word 55000, 61, 1582, 106
    .word 55833, 71,  394, 88
    .word 56250, 73,  394, 101
    .word 56667, 43,  394, 86
    .word 56667, 74,  790, 102
    .word 57083, 47,  394, 100
    .word 57500, 50,  394, 96
    .word 57500, 73,  394, 92
    .word 57917, 55,  394, 102
    .word 57917, 74,  790, 102
    .word 58333, 57, 1582, 105
    .word 58750, 78, 1186, 111
    .word 60000, 64, 2373, 74
    .word 60000, 73, 2373, 62
    .word 60000, 45, 3165, 65
    .word 60000, 52, 3165, 65
    .word 62500, 59,  394, 78
    .word 62500, 71,  790, 68
    .word 62917, 57,  394, 83
    .word 63333, 40,  394, 60
    .word 63333, 52, 1250, 62
    .word 63333, 56, 1582, 62
    .word 63333, 59, 3165, 62
    .word 63750, 44,  394, 58
    .word 64167, 47,  415, 73
    .word 64583, 52,  790, 74
    .word 65000, 56, 1582, 79
    .word 65417, 52, 1185, 75
    .word 65833, 47,  394, 64
    .word 66250, 44,  394, 60
    .word 66667, 40,  394, 67
    .word 66667, 52, 1250, 64
    .word 67083, 44,  394, 72
    .word 67500, 47,  415, 75
    .word 67917, 52,  790, 82
    .word 68333, 56,  415, 76
    .word 68750, 52, 1186, 74
    .word 69167, 45,  790, 69
    .word 70000, 43,  394, 59
    .word 70000, 79,  394, 74
    .word 70417, 47,  394, 61
    .word 70417, 78,  394, 71
    .word 70833, 50,  394, 68
    .word 70833, 76,  394, 57
    .word 71250, 54,  394, 71
    .word 71250, 74,  394, 53
    .word 71667, 57,  394, 64
    .word 71667, 76,  394, 67
    .word 72083, 54,  394, 60
    .word 72083, 74,  394, 65
    .word 72500, 50,  394, 56
    .word 72500, 76,  394, 62
    .word 72917, 47,  394, 57
    .word 72917, 78,  394, 72
    .word 73333, 45,  415, 55
    .word 73750, 49,  394, 54
    .word 73750, 76, 2769, 53
    .word 74167, 52,  394, 63
    .word 74583, 57,  394, 66
    .word 75000, 61,  394, 69
    .word 75000, 81, 1582, 58
    .word 75417, 59,  394, 68
    .word 75833, 57,  394, 63
    .word 76250, 52,  394, 59
    .word 76667, 40,  394, 52
    .word 76667, 80,  394, 60
    .word 77083, 44,  394, 57
    .word 77083, 76,  394, 54
    .word 77500, 47,  394, 62
    .word 77500, 71,  394, 52
    .word 77917, 52,  394, 62
    .word 77917, 68,  394, 46
    .word 78333, 56, 1582, 68
    .word 78333, 64, 1582, 57
    .word 80000, 40,  394, 55
    .word 80000, 71,  394, 67
    .word 80417, 44,  394, 57
    .word 80417, 68,  394, 65
    .word 80833, 47,  394, 64
    .word 80833, 64,  394, 53
    .word 81250, 52,  394, 69
    .word 81250, 59,  394, 46
    .word 81667, 56, 1581, 55
    .word 83333, 52,  394, 37
    .word 83333, 40, 6332, 32
    .word 83750, 56,  394, 42
    .word 84167, 59,  394, 41
    .word 84583, 64,  394, 43
    .word 85000, 59,  394, 38
    .word 85417, 56, 1185, 35
    .word 86667, 52,  394, 26
    .word 87083, 56,  394, 29
    .word 87500, 59,  394, 25
    .word 87917, 64,  394, 29
    .word 88333, 59,  394, 19
    .word 88750, 56, 1186, 22

bgm_notes_end:
bgm_loop_ms:      .word 89937

##############################################################################
# Mutable Data
##############################################################################
# The 7 columns x 14 rows play board
# In total of 98 words
# {0: transparent, 1: red, 2: green, 3: blue, 4: yellow}
    .align 2
grid:             .space 392
match_grid:       .space 392

# NPC STEVE REACTIONS
# {-1: NPC initialize, 0: EMMM!, 1: NOT BAD!, 2: SMART!, 3: GENIUS!, 4: DUMBx3}
steve_reaction: .word -1

# Player1 (poop1)
# {a: left, d: right, s: grab, w: throw}
p1_col: .word 2
p1_held_color: .word 0
p1_held_count: .word 0

# Player2 (poop2) with a flower demoe
# {j: left, l: right, k: grab, i: throw}
p2_col: .word 4
p2_held_color: .word 0
p2_held_count: .word 0

# Extra animation (both flip 360 degree by pressing r)
flip_timer: .word 0
flip_angle: .word 0

# Row dropdown counter
# Every 10 keystrokes of total of two players
keystroke_count:    .word 0

# BGM states
bgm_cycle_start:    .word 0
bgm_next_note:      .word 0
bgm_pause_time:     .word 0

# Pause Key that suspend the clock
p_last_event:   .word 0
##############################################################################
# Code
##############################################################################
.text
.globl main

    # Run the game.
main:
    # Initialize the game
    # Preload piano once
    li   $v0, 33
    li   $a0, 60
    li   $a1, 1
    move $a2, $zero
    move $a3, $zero
    syscall
# Public initialization for Restart
restart_game:
    jal  reset_game_state
    # Populate top 4 rows in memory
    jal  init_grid               
    jal  draw_static_borders
    jal  draw_screen
    jal  draw_steve_sidebar
    
    # Start fresh on replay
    jal  bgm_reset

game_loop:
    # 1a. Check if key has been pressed
    # Poll keyboard before scheduling any new music.
    # 1. Poll keyboard MMIO (0xffff0000)
    lw   $t0, ADDR_KBRD
    lw   $t1, 0($t0)
    andi $t1, $t1, 1
    # If no key pressed, only redraw if flipping
    beq  $t1, $zero, check_flip_anim

    # 1b. Check which key has been pressed
    # Read ASCII key from 0xffff0004
    lw   $t2, 4($t0)
    
    # Accept both upper/lowercase
    ori  $t2, $t2, 0x20
    beq  $t2, 0x71, quit_game    # q
    beq  $t2, 0x70, pause_key_playing # p

    # Poop 1 controls: a (left), d (right), s (grab), w (throw)
    beq  $t2, 0x61, p1_left
    beq  $t2, 0x64, p1_right
    beq  $t2, 0x73, p1_grab
    beq  $t2, 0x77, p1_throw

    # Poop 2 controls: j (left), l (right), k (grab), i (throw)
    beq  $t2, 0x6a, p2_left
    beq  $t2, 0x6c, p2_right
    beq  $t2, 0x6b, p2_grab
    beq  $t2, 0x69, p2_throw

    # Extra 360-degree flip ('r')
    beq  $t2, 0x72, trigger_flip
    j    check_flip_anim

# =========================================================
# Input Handlers
# =========================================================
    # 2a. Check for collisions
    # 2b. Update locations (capsules)
    # Input handlers check boundaries and update player and bubble states.
p1_left:
    lw   $t3, p1_col
    blez $t3, sleep_step
    addi $t3, $t3, -1
    sw   $t3, p1_col
    j    on_valid_keystroke

p1_right:
    lw   $t3, p1_col
    bge  $t3, 6, sleep_step
    addi $t3, $t3, 1
    sw   $t3, p1_col
    j    on_valid_keystroke

p1_grab:
    la   $a0, p1_col
    la   $a1, p1_held_color
    la   $a2, p1_held_count
    jal  grab_bubble
    j    on_valid_keystroke

p1_throw:
    la   $a0, p1_col
    la   $a1, p1_held_color
    la   $a2, p1_held_count
    jal  throw_bubble
    bltz $v0, on_valid_keystroke
    move $a0, $v0
    jal  resolve_matches
    j    on_valid_keystroke

p2_left:
    lw   $t3, p2_col
    blez $t3, sleep_step
    addi $t3, $t3, -1
    sw   $t3, p2_col
    j    on_valid_keystroke

p2_right:
    lw   $t3, p2_col
    bge  $t3, 6, sleep_step
    addi $t3, $t3, 1
    sw   $t3, p2_col
    j    on_valid_keystroke

p2_grab:
    la   $a0, p2_col
    la   $a1, p2_held_color
    la   $a2, p2_held_count
    jal  grab_bubble
    j    on_valid_keystroke

p2_throw:
    la   $a0, p2_col
    la   $a1, p2_held_color
    la   $a2, p2_held_count
    jal  throw_bubble
    bltz $v0, on_valid_keystroke
    move $a0, $v0
    jal  resolve_matches
    j    on_valid_keystroke

trigger_flip:
    li   $t3, 16
    sw   $t3, flip_timer
    sw   $zero, flip_angle
    jal  draw_screen
    j    sleep_step

# =========================================================
# Row Advancement (every 10 keystrokes) & Game Over Check
# =========================================================
on_valid_keystroke:
    lw   $t3, keystroke_count
    addi $t3, $t3, 1
    sw   $t3, keystroke_count
    blt  $t3, 10, redraw_and_sleep

    # Reset counter and push rows down by 1.
    sw   $zero, keystroke_count
    jal  advance_row

    # Game Over check: if any bubble reached row 13
    la   $t4, grid
    
     # Row 13 start: 13 * 7 * 4
    addi $t4, $t4, 364
    li   $t5, 0
check_gameover_loop:
    lw   $t6, 0($t4)
    bne  $t6, $zero, game_over
    addi $t4, $t4, 4
    addi $t5, $t5, 1
    blt  $t5, 7, check_gameover_loop
    j    redraw_and_sleep

# =========================================================
# Animation Update & Conditional Redraw
# =========================================================
check_flip_anim:
    lw   $t3, flip_timer
    
    # Nothing changed -> DO NOT redraw
    blez $t3, sleep_step

    addi $t3, $t3, -1
    sw   $t3, flip_timer

    # Update angle every 4 frames
    andi $t4, $t3, 3
    bne  $t4, $zero, sleep_step
    lw   $t5, flip_angle
    addi $t5, $t5, 1
    andi $t5, $t5, 3
    sw   $t5, flip_angle

redraw_and_sleep:
    # 3. Draw the screen
    # Only redraw when state actually changed!
    jal  draw_screen
    
    # Refresh NPC  reaction on each input
    jal  draw_steve_sidebar

sleep_step:
    # 4. Sleep
    jal  bgm_tick
    li   $v0, 32
    li   $a0, 16
    syscall
    # 5. Go back to Step 1
    j    game_loop

game_over:
    li   $t0, 4
    sw   $t0, steve_reaction
    jal  draw_steve_sidebar
    
    # Bitmap overlay (losing condition only)
    jal  draw_game_over_screen
    
    # Print message on console
    li   $v0, 4  
    la   $a0, game_over_message
    syscall
    j    game_over_wait
    
# Wait for the player's decision
# Self-looped back to current state waiting for input keys
game_over_wait:
    li   $v0, 32
    li   $a0, 16
    syscall

    lw   $t0, ADDR_KBRD
    lw   $t1, 0($t0)

    andi $t1, $t1, 1
    beq  $t1, $zero, game_over_wait

    lw   $t2, 4($t0)

    beq  $t2, 0x1b, quit_game
    ori  $t2, $t2, 0x20
    
    # q for QUIT
    beq  $t2, 0x71, quit_game
    
    # r for RESTART (re-initialize the entire porcess)
    beq  $t2, 0x72, restart_game

    j    game_over_wait

# Reset all gameplay variables
# When replay is triggered, reset and re-initialize entire process and setting
reset_game_state:
    la   $t0, grid
    la   $t1, match_grid
    li   $t2, 98

reset_grid_loop:
    sw   $zero, 0($t0)
    sw   $zero, 0($t1)

    addiu $t0, $t0, 4
    addiu $t1, $t1, 4
    addiu $t2, $t2, -1

    bgtz $t2, reset_grid_loop

    # Reset player positions
    li   $t0, 2
    sw   $t0, p1_col

    li   $t0, 4
    sw   $t0, p2_col

    # Reset bubbles holded
    sw   $zero, p1_held_color
    sw   $zero, p1_held_count
    sw   $zero, p2_held_color
    sw   $zero, p2_held_count

    # Reset animation
    sw   $zero, flip_timer
    sw   $zero, flip_angle

    # Reset random row advancement
    sw   $zero, keystroke_count

    # Reset Steve's reaction
    li   $t0, -1
    sw   $t0, steve_reaction

    jr   $ra


pause_key_playing:
    jal  accept_pause_key
    beq  $v0, $zero, sleep_step
    j    pause_game

pause_key_waiting:
    jal  accept_pause_key
    beq  $v0, $zero, pause_wait
    j    resume_game

accept_pause_key:
    li   $v0, 30
    syscall
    lw   $t0, p_last_event
    sw   $a0, p_last_event
    subu $t1, $a0, $t0
    sltiu $v0, $t1, 250
    xori $v0, $v0, 1
    jr   $ra

# Display status in unused sidebar space, preserve board and reaction.
pause_game:
    # Freeze the song clock before drawing pause text
    # Allows MUSIC suspend until resume p is input
    li   $v0, 30
    syscall
    sw   $a0, bgm_pause_time
    la   $a0, pause_text
    li   $a1, 43
    li   $a2, 27
    li   $a3, 0xffff00
    jal  draw_bitmap_text

    la   $a0, resume_text
    li   $a1, 40
    li   $a2, 55
    li   $a3, 0xffff00
    jal  draw_bitmap_text

pause_wait:
    li   $v0, 32
    li   $a0, 16
    syscall
    lw   $t0, ADDR_KBRD
    lw   $t1, 0($t0)
    andi $t1, $t1, 1
    beq  $t1, $zero, pause_wait
    lw   $t2, 4($t0)
    ori  $t2, $t2, 0x20
    beq  $t2, 0x70, pause_key_waiting
    beq  $t2, 0x71, quit_game
    j    pause_wait

# [MUSIC] Exclude paused wall-clock time from the song timeline.
resume_game:
    li   $v0, 30
    syscall
    lw   $t0, bgm_pause_time
    subu $t1, $a0, $t0
    lw   $t2, bgm_cycle_start
    addu $t2, $t2, $t1
    sw   $t2, bgm_cycle_start
    j    redraw_and_sleep

quit_game:
    li   $v0, 10
    syscall

# =========================================================
# Subroutines
# =========================================================

# Draw a three-line GAME / OVER / YOU LOST bitmap end screen.
# The following states only starts when GAME OVER is presented, 
# and we skip the entire process by reading q for QUIT
draw_game_over_screen:
    addi $sp, $sp, -4
    sw   $ra, 0($sp)

    # Wipe the playfield interior; leave the white frame intact.
    lw   $t0, ADDR_DSPL
    
    # y
    li   $t1, 4
end_clear_y:
    # x
    li   $t2, 10
end_clear_x:
    # 64 units * 4 bytes per unit
    sll  $t3, $t1, 8            
    sll  $t4, $t2, 2
    addu $t3, $t3, $t4
    addu $t3, $t3, $t0
    sw   $zero, 0($t3)
    addi $t2, $t2, 1
    blt  $t2, 38, end_clear_x
    addi $t1, $t1, 1
    blt  $t1, 60, end_clear_y

    # [GAME OVER LAYOUT] Three centered lines with vertical layout
    # The 3x5 font advances 3 units per letter and 2 per space
    # GAME and OVER: 12 units wide; YOU LOST: 23 units wide
    # All fit inside the demo board
    la   $a0, game_over_line1
    li   $a1, 18                # centered x: GAME
    li   $a2, 20                # first line y
    li   $a3, 0xffffff         # white
    jal  draw_bitmap_text

    la   $a0, game_over_line2
    li   $a1, 18                # centered x: OVER
    li   $a2, 30                # second line y
    li   $a3, 0xffffff         # white
    jal  draw_bitmap_text

    la   $a0, game_over_line3
    li   $a1, 12                # centered x: YOU LOST
    li   $a2, 42                # third line y
    li   $a3, 0xff4444         # red
    jal  draw_bitmap_text

    # Show restart option below YOU LOST
    # This allows to restart function
    la   $a0, replay_text
    li   $a1, 12
    li   $a2, 53
    li   $a3, 0x00ff00
    jal  draw_bitmap_text

    # Quit option in sidebar below Steve
    # This allows to quit the game
    la   $a0, quit_text
    li   $a1, 43
    li   $a2, 55
    li   $a3, 0xffff00
    jal  draw_bitmap_text

    lw   $ra, 0($sp)
    addi $sp, $sp, 4
    jr   $ra

# Draw an uppercase string using the 3x5 bitmap_letters table.
# Input: $a0 string address, $a1 x, $a2 y, $a3 pixel colour.
draw_bitmap_text:
    addi $sp, $sp, -28
    sw   $ra, 0($sp)
    sw   $s0, 4($sp)
    sw   $s1, 8($sp)
    sw   $s2, 12($sp)
    sw   $s3, 16($sp)
    sw   $s4, 20($sp)
    sw   $s5, 24($sp)
    move $s0, $a0              # string pointer
    move $s1, $a1              # x cursor
    move $s2, $a2              # y top
    move $s3, $a3              # colour

end_text_next:
    lbu  $t0, 0($s0)
    beq  $t0, $zero, end_text_done
    li   $t1, 32               # ASCII space
    beq  $t0, $t1, end_text_space

    la   $s4, bitmap_letters
end_text_find:
    lbu  $t1, 0($s4)
    beq  $t1, $zero, end_text_advance
    beq  $t1, $t0, end_text_found
    addi $s4, $s4, 6
    j    end_text_find

end_text_found:
    li   $s5, 0       
end_glyph_row:
    addiu $t0, $s5, 1
    addu $t0, $s4, $t0
    lbu  $t1, 0($t0)           
    li   $t2, 0               
end_glyph_col:
    li   $t3, 4                
    srlv $t3, $t3, $t2         
    and  $t4, $t1, $t3
    beq  $t4, $zero, end_glyph_skip

    addu $t5, $s2, $s5         # y + glyph row
    sll  $t5, $t5, 8
    addu $t6, $s1, $t2         # x + glyph column
    sll  $t6, $t6, 2
    addu $t5, $t5, $t6
    lw   $t6, ADDR_DSPL
    addu $t5, $t5, $t6
    sw   $s3, 0($t5)
end_glyph_skip:
    addi $t2, $t2, 1
    blt  $t2, 3, end_glyph_col
    addi $s5, $s5, 1
    blt  $s5, 5, end_glyph_row

end_text_advance:
    addi $s1, $s1, 3
    addi $s0, $s0, 1
    j    end_text_next
end_text_space:
    addi $s1, $s1, 2
    addi $s0, $s0, 1
    j    end_text_next
end_text_done:
    lw   $ra, 0($sp)
    lw   $s0, 4($sp)
    lw   $s1, 8($sp)
    lw   $s2, 12($sp)
    lw   $s3, 16($sp)
    lw   $s4, 20($sp)
    lw   $s5, 24($sp)
    addi $sp, $sp, 28
    jr   $ra

# =========================================================
# Draw outside the RIGHT border (x=40..63).
# Right side is 24 bitmap units wide; never alter playfield x=10..37.
# =========================================================
# Below are NPC configurations
draw_steve_sidebar:
    addiu $sp, $sp, -20
    sw    $ra, 0($sp)
    sw    $s0, 4($sp)
    sw    $s1, 8($sp)
    sw    $s2, 12($sp)
    sw    $s3, 16($sp)

    # Clear only the sidebar to avoid leaving old message pixels.
    lw    $t0, ADDR_DSPL
    li    $t1, 4               # y = 4..59
steve_clear_y:
    li    $t2, 40              # x = 40..63
steve_clear_x:
    sll   $t3, $t1, 8
    sll   $t4, $t2, 2
    addu  $t3, $t3, $t4
    addu  $t3, $t3, $t0
    sw    $zero, 0($t3)
    addiu $t2, $t2, 1
    blt   $t2, 64, steve_clear_x
    addiu $t1, $t1, 1
    blt   $t1, 60, steve_clear_y

    # Render 10x16 Steve sprite at x=47..56, y=9..24.
    la    $s0, steve_sprite
    la    $s3, steve_palette
    li    $s1, 0              # row
steve_sprite_y:
    li    $s2, 0              # column
steve_sprite_x:
    lbu   $t0, 0($s0)
    beq   $t0, $zero, steve_sprite_skip
    sll   $t0, $t0, 2
    addu  $t1, $s3, $t0
    lw    $t1, 0($t1)         # colour
    addiu $t2, $s1, 9
    sll   $t2, $t2, 8
    addiu $t3, $s2, 47
    sll   $t3, $t3, 2
    addu  $t2, $t2, $t3
    lw    $t3, ADDR_DSPL
    addu  $t2, $t2, $t3
    sw    $t1, 0($t2)
steve_sprite_skip:
    addiu $s0, $s0, 1
    addiu $s2, $s2, 1
    blt   $s2, 10, steve_sprite_x
    addiu $s1, $s1, 1
    blt   $s1, 16, steve_sprite_y

    # Render a reaction based on the distinct colours cleared this throw.
    lw    $s0, steve_reaction
    bltz  $s0, steve_say_title
    beq   $s0, $zero, steve_say_emmm
    li    $t0, 1
    beq   $s0, $t0, steve_say_not_bad
    li    $t0, 2
    beq   $s0, $t0, steve_say_smart
    li    $t0, 3
    beq   $s0, $t0, steve_say_genius
    j     steve_say_dumb
steve_say_title:
    la    $a0, steve_title
    li    $a1, 45
    li    $a2, 36
    j     steve_one_line
steve_say_emmm:
    la    $a0, steve_emmm
    li    $a1, 45
    li    $a2, 36
    j     steve_one_line
steve_say_smart:
    la    $a0, steve_smart
    li    $a1, 43
    li    $a2, 36
    j     steve_one_line
steve_say_genius:
    la    $a0, steve_genius
    li    $a1, 41
    li    $a2, 36
    j     steve_one_line
steve_one_line:
    li    $a3, 0xffffff
    jal   draw_bitmap_text
    j     steve_sidebar_done
steve_say_not_bad:
    la    $a0, steve_not
    li    $a1, 47
    li    $a2, 35
    li    $a3, 0xffffff
    jal   draw_bitmap_text
    la    $a0, steve_bad
    li    $a1, 45
    li    $a2, 44
    li    $a3, 0xffffff
    jal   draw_bitmap_text
    j     steve_sidebar_done
steve_say_dumb:
    # [STEVE] Game over: DUMB x3, each on its own line, in red.
    li    $s0, 33
steve_dumb_loop:
    la    $a0, steve_dumb
    li    $a1, 46
    move  $a2, $s0
    li    $a3, 0xff4444
    jal   draw_bitmap_text
    addiu $s0, $s0, 8
    ble   $s0, 49, steve_dumb_loop
steve_sidebar_done:
    lw    $ra, 0($sp)
    lw    $s0, 4($sp)
    lw    $s1, 8($sp)
    lw    $s2, 12($sp)
    lw    $s3, 16($sp)
    addiu $sp, $sp, 20
    jr    $ra

# Fill the first four rows with random colours, avoiding pre-existing
# vertical triples. Match removal should be initiated by gameplay throws.
init_grid:
    la   $t4, grid
    li   $t5, 0
init_grid_loop:
    li   $v0, 42
    li   $a0, 0
    li   $a1, 4
    syscall
    addi $a0, $a0, 1            # Colours 1..4
    
    # First two rows cannot make a triple
    blt  $t5, 14, init_store     
    lw   $t6, -28($t4)          # Same column, preceding row
    bne  $a0, $t6, init_store
    lw   $t7, -56($t4)          # Same column, two rows above
    beq  $a0, $t7, init_grid_loop
init_store:
    sw   $a0, 0($t4)
    addi $t4, $t4, 4
    addi $t5, $t5, 1
    blt  $t5, 28, init_grid_loop
    jr   $ra

draw_static_borders:
    lw   $t0, ADDR_DSPL
    li   $t1, 0xffffff
    li   $t2, 8
top_border_loop:
    sll  $t4, $t2, 2
    addi $t5, $t0, 512
    add  $t5, $t5, $t4
    sw   $t1, 0($t5)
    addi $t5, $t5, 256
    sw   $t1, 0($t5)
    addi $t2, $t2, 1
    bne  $t2, 40, top_border_loop

    li   $t2, 2
side_border_loop:
    sll  $t4, $t2, 8
    add  $t5, $t0, $t4
    sw   $t1, 32($t5)
    sw   $t1, 36($t5)
    sw   $t1, 152($t5)
    sw   $t1, 156($t5)
    addi $t2, $t2, 1
    bne  $t2, 62, side_border_loop
    jr   $ra

draw_bottom_border:
    lw   $t0, ADDR_DSPL
    li   $t1, 0xffffff
    li   $t2, 8
bot_border_loop:
    sll  $t4, $t2, 2
    addi $t5, $t0, 15360
    add  $t5, $t5, $t4
    sw   $t1, 0($t5)
    addi $t5, $t5, 256
    sw   $t1, 0($t5)
    addi $t2, $t2, 1
    bne  $t2, 40, bot_border_loop
    jr   $ra

# Grab bottom-most same-colored bubbles in column
grab_bubble:
    lw   $t0, 0($a0)             # col
    la   $t1, grid
    li   $t2, 13                 # Start at bottom row (13)

find_bottom_loop:
    bltz $t2, grab_done
    mul  $t3, $t2, 7
    add  $t3, $t3, $t0
    sll  $t3, $t3, 2
    add  $t4, $t1, $t3
    lw   $t5, 0($t4)
    bne  $t5, $zero, found_bubble
    addi $t2, $t2, -1
    j    find_bottom_loop

found_bubble:
    lw   $t6, 0($a2)             # held_count
    lw   $t7, 0($a1)             # held_color
    beq  $t6, $zero, collect_chain
    bne  $t7, $t5, grab_done

collect_chain:
    sw   $t5, 0($a1)
collect_loop:
    bltz $t2, grab_done
    mul  $t3, $t2, 7
    add  $t3, $t3, $t0
    sll  $t3, $t3, 2
    add  $t4, $t1, $t3
    lw   $t8, 0($t4)
    bne  $t8, $t5, grab_done

    sw   $zero, 0($t4)
    addi $t6, $t6, 1
    sw   $t6, 0($a2)
    addi $t2, $t2, -1
    j    collect_loop

grab_done:
    jr   $ra

# Throw held bubbles upward into the column above the character
# $a0 = &p_col, $a1 = &p_held_color, $a2 = &p_held_count
throw_bubble:
    lw   $t6, 0($a2)            # Number held
    blez $t6, throw_nothing
    lw   $t0, 0($a0)            # Target column
    lw   $t5, 0($a1)            # Held colour
    la   $t1, grid
    li   $t2, 13                # Search UP from bottom

throw_find_bottom:
    bltz $t2, throw_empty_column
    mul  $t3, $t2, 7
    add  $t3, $t3, $t0
    sll  $t3, $t3, 2
    add  $t4, $t1, $t3
    lw   $t7, 0($t4)
    bne  $t7, $zero, throw_bottom_found
    addi $t2, $t2, -1
    j    throw_find_bottom

throw_empty_column:
    li   $t2, 0                # An empty column starts at the top
    j    throw_check_space

throw_bottom_found:
    addi $t2, $t2, 1           # Join underside of existing top stack

throw_check_space:
    # All held bubbles must fit in rows 0..13.
    add  $t7, $t2, $t6
    bgt  $t7, 14, throw_no_space

throw_place_loop:
    blez $t6, throw_finished
    mul  $t3, $t2, 7
    add  $t3, $t3, $t0
    sll  $t3, $t3, 2
    add  $t4, $t1, $t3
    sw   $t5, 0($t4)
    addi $t2, $t2, 1
    addi $t6, $t6, -1
    j    throw_place_loop

throw_finished:
    sw   $zero, 0($a1)
    sw   $zero, 0($a2)
    move $v0, $t0              # Newly changed column
    jr   $ra

throw_no_space:
    # Keep the collected bubbles rather than partially writing the throw.
    li   $v0, -1
    jr   $ra

throw_nothing:
    li   $v0, -1
    jr   $ra

# =========================================================
# The Gravity and Chain-Cancelation
# =========================================================
resolve_matches:
    addi $sp, $sp, -28
    sw   $ra, 0($sp)
    sw   $s0, 4($sp)
    sw   $s1, 8($sp)
    sw   $s2, 12($sp)
    sw   $s3, 16($sp)
    sw   $s4, 20($sp)
    sw   $s5, 24($sp)
    move $s5, $zero

    move $s4, $a0

chain_loop:
    # A. Clear match_grid (98 words)
    la   $t0, match_grid
    li   $t1, 0
clear_match_grid:
    sw   $zero, 0($t0)
    addi $t0, $t0, 4
    addi $t1, $t1, 1
    blt  $t1, 98, clear_match_grid

    # $s0 = match_found flag
    li   $s0, 0

    # B. Stage 1: Scan columns for vertical match-3 triggers
    li   $s1, 0                  # col = 0..6

vert_col_loop:
    # If $s4 < 0, check all columns
    bltz $s4, check_this_col 
    
    # On pass 1, only trigger on thrown column
    bne  $s1, $s4, next_vert_col 
    
check_this_col:                  
    li   $s2, 0                 
vert_row_loop:
    mul  $t0, $s2, 7
    add  $t0, $t0, $s1
    sll  $t0, $t0, 2             
    la   $t1, grid
    add  $t2, $t1, $t0
    lw   $t3, 0($t2)             
    beq  $t3, $zero, next_vert_row

    lw   $t4, 28($t2)            # grid[row+1][col] (+28 bytes)
    bne  $t3, $t4, next_vert_row
    lw   $t5, 56($t2)            # grid[row+2][col] (+56 bytes)
    bne  $t3, $t5, next_vert_row

    # Mark all 3 cells in match_grid
    la   $t6, match_grid
    add  $t6, $t6, $t0
    li   $t7, 1
    sw   $t7, 0($t6)
    sw   $t7, 28($t6)
    sw   $t7, 56($t6)
    
    # match_found = 1, here we flip the flag
    li   $s0, 1

next_vert_row:
    addi $s2, $s2, 1
    blt  $s2, 12, vert_row_loop

next_vert_col:
    addi $s1, $s1, 1
    blt  $s1, 7, vert_col_loop

    # If no vertical match-3 triggered, exit chain_loop
    beq  $s0, $zero, resolve_done

    # Stage 2: Chain-connected same-color neighbors
flood_pass:
    li   $s3, 0                  # $s3 = changed flag
    li   $s2, 0                  # row = 0..13
flood_row:
    li   $s1, 0                  # col = 0..6
flood_col:
    mul  $t0, $s2, 7
    add  $t0, $t0, $s1
    sll  $t0, $t0, 2

    la   $t1, match_grid
    add  $t2, $t1, $t0
    lw   $t3, 0($t2)
    beq  $t3, $zero, next_flood_cell

    la   $t4, grid
    add  $t5, $t4, $t0
    lw   $t6, 0($t5)

    # Check all the rows above to see if cancelation match is founded
    blez $s2, check_down
    lw   $t7, -28($t2)
    bne  $t7, $zero, check_down
    lw   $t8, -28($t5)
    bne  $t8, $t6, check_down
    li   $t9, 1
    sw   $t9, -28($t2)
    li   $s3, 1

check_down:
    bge  $s2, 13, check_left
    lw   $t7, 28($t2)
    bne  $t7, $zero, check_left
    lw   $t8, 28($t5)
    bne  $t8, $t6, check_left
    li   $t9, 1
    sw   $t9, 28($t2)
    li   $s3, 1

check_left:
    blez $s1, check_right
    lw   $t7, -4($t2)
    bne  $t7, $zero, check_right
    lw   $t8, -4($t5)
    bne  $t8, $t6, check_right
    li   $t9, 1
    sw   $t9, -4($t2)
    li   $s3, 1

check_right:
    bge  $s1, 6, next_flood_cell
    lw   $t7, 4($t2)
    bne  $t7, $zero, next_flood_cell
    lw   $t8, 4($t5)
    bne  $t8, $t6, next_flood_cell
    li   $t9, 1
    sw   $t9, 4($t2)
    li   $s3, 1

next_flood_cell:
    addi $s1, $s1, 1
    blt  $s1, 7, flood_col
    addi $s2, $s2, 1
    blt  $s2, 14, flood_row
    
    # Repeat until all the pixels on the board wont cause a matched
    bne  $s3, $zero, flood_pass

    # Delete all marked bubbles to do cancellation
    la   $t0, grid
    la   $t1, match_grid
    li   $t2, 0

delete_loop:
    lw   $t3, 0($t1)
    beq  $t3, $zero, skip_delete
    # Set one bit per colour cleared, across every chain pass.
    lw   $t4, 0($t0)
    addiu $t4, $t4, -1
    li   $t5, 1
    sllv $t5, $t5, $t4
    or   $s5, $s5, $t5
    sw   $zero, 0($t0)
skip_delete:
    addi $t0, $t0, 4
    addi $t1, $t1, 4
    addi $t2, $t2, 1
    blt  $t2, 98, delete_loop

    # Apply upward gravity (float bubbles toward row 0)
    li   $s1, 0                  # col = 0..6
grav_col_loop:
    li   $t0, 0                  # write_row = 0
    li   $t1, 0                  # read_row = 0
grav_read_loop:
    mul  $t2, $t1, 7
    add  $t2, $t2, $s1
    sll  $t2, $t2, 2
    la   $t3, grid
    add  $t2, $t3, $t2
    lw   $t4, 0($t2)             # grid[read_row][col]
    beq  $t4, $zero, next_grav_read

    mul  $t5, $t0, 7
    add  $t5, $t5, $s1
    sll  $t5, $t5, 2
    add  $t5, $t3, $t5
    sw   $t4, 0($t5)             # grid[write_row][col] = value
    addi $t0, $t0, 1             # write_row++

next_grav_read:
    addi $t1, $t1, 1
    blt  $t1, 14, grav_read_loop

    # Fill remaining rows (write_row..13) with 0
grav_fill_zero:
    bge  $t0, 14, next_grav_col
    mul  $t5, $t0, 7
    add  $t5, $t5, $s1
    sll  $t5, $t5, 2
    la   $t3, grid
    add  $t5, $t3, $t5
    sw   $zero, 0($t5)
    addi $t0, $t0, 1
    j    grav_fill_zero

next_grav_col:
    addi $s1, $s1, 1
    blt  $s1, 7, grav_col_loop

    # Repeat chain_loop to check for matches!
    li   $s4, -1
    j    chain_loop

resolve_done:
    # Number of different colours deleted in this whole throw,
    # which will later feed to Steve to show reaction
    # Bitmap popcount uses only four bits (1,2,4,8).
    move $t0, $s5
    move $t1, $zero
steve_count_colors:
    beq  $t0, $zero, steve_colors_ready
    andi $t2, $t0, 1
    addu $t1, $t1, $t2
    srl  $t0, $t0, 1
    j    steve_count_colors
steve_colors_ready:
    slti $t2, $t1, 3
    bne  $t2, $zero, steve_store_reaction
    li   $t1, 3               # 3 or 4 -> GENIUS!
steve_store_reaction:
    sw   $t1, steve_reaction
    lw   $ra, 0($sp)
    lw   $s0, 4($sp)
    lw   $s1, 8($sp)
    lw   $s2, 12($sp)
    lw   $s3, 16($sp)
    lw   $s4, 20($sp)
    lw   $s5, 24($sp)
    addi $sp, $sp, 28
    jr   $ra

advance_row:
    la   $t0, grid
    li   $t1, 13
shift_row_loop:
    beq  $t1, $zero, fill_top_row
    li   $t2, 0
shift_col_loop:
    addi $t3, $t1, -1
    mul  $t4, $t3, 7
    add  $t4, $t4, $t2
    sll  $t4, $t4, 2
    add  $t4, $t0, $t4
    lw   $t5, 0($t4)

    mul  $t6, $t1, 7
    add  $t6, $t6, $t2
    sll  $t6, $t6, 2
    add  $t6, $t0, $t6
    sw   $t5, 0($t6)

    addi $t2, $t2, 1
    blt  $t2, 7, shift_col_loop
    addi $t1, $t1, -1
    j    shift_row_loop

fill_top_row:
    li   $t2, 0
fill_top_loop:
    # keep new rows from creating pre-existing vertical triples.
    # After shifting, rows 1 and 2 sit at +28 and +56 bytes.
    li   $v0, 42
    li   $a0, 0
    li   $a1, 4
    syscall
    addi $a0, $a0, 1
    lw   $t7, 28($t0)            # row 1, same column
    bne  $a0, $t7, store_top_bubble
    lw   $t8, 56($t0)            # row 2, same column
    beq  $a0, $t8, fill_top_loop # retry only if all three match
store_top_bubble:
    sw   $a0, 0($t0)
    addi $t0, $t0, 4
    addi $t2, $t2, 1
    blt  $t2, 7, fill_top_loop
    jr   $ra

draw_screen:
    addi $sp, $sp, -4
    sw   $ra, 0($sp)

    lw   $t0, ADDR_DSPL

    # Clear playfield interior (X = 10..37, Y = 4..63)
    li   $t1, 4
clear_y_loop:
    li   $t2, 10
clear_x_loop:
    sll  $t3, $t1, 8
    sll  $t4, $t2, 2
    add  $t3, $t3, $t4
    add  $t3, $t0, $t3
    sw   $zero, 0($t3)
    addi $t2, $t2, 1
    blt  $t2, 38, clear_x_loop
    addi $t1, $t1, 1
    blt  $t1, 64, clear_y_loop

    # Draw grid bubbles
    li   $s0, 0
draw_grid_row:
    li   $s1, 0
draw_grid_col:
    mul  $t1, $s0, 7
    add  $t1, $t1, $s1
    sll  $t1, $t1, 2
    la   $t2, grid
    add  $t2, $t2, $t1
    lw   $t3, 0($t2)
    beq  $t3, $zero, next_grid_cell

    addi $t3, $t3, -1
    sll  $t3, $t3, 2
    la   $t4, bubble_colors
    add  $t4, $t4, $t3
    lw   $s3, 0($t4)

    sll  $t6, $s1, 2
    addi $t6, $t6, 10
    sll  $t7, $s0, 2
    addi $t7, $t7, 4

    li   $t8, 0
b_pix_y:
    li   $t9, 0
b_pix_x:
    add  $a2, $t7, $t8
    sll  $a2, $a2, 8
    add  $a3, $t6, $t9
    sll  $a3, $a3, 2
    add  $a2, $a2, $a3
    add  $a2, $t0, $a2
    sw   $s3, 0($a2)
    addi $t9, $t9, 1
    blt  $t9, 4, b_pix_x
    addi $t8, $t8, 1
    blt  $t8, 4, b_pix_y

next_grid_cell:
    addi $s1, $s1, 1
    blt  $s1, 7, draw_grid_col
    addi $s0, $s0, 1
    blt  $s0, 14, draw_grid_row

    # Redraw bottom border so characters cross over it
    jal  draw_bottom_border

    # Draw poop1 and poop2
    lw   $a0, p1_col
    lw   $a1, p1_held_color
    lw   $a2, p1_held_count
    jal  draw_single_poop

    lw   $a0, p2_col
    lw   $a1, p2_held_color
    lw   $a2, p2_held_count
    jal  draw_single_poop
    
    jal  draw_pink_bow

    lw   $ra, 0($sp)
    addi $sp, $sp, 4
    jr   $ra

draw_single_poop:
    lw   $t0, ADDR_DSPL
    sll  $t1, $a0, 2
    addi $t1, $t1, 10

    # Draw held bubble indicator above poop if holding ($a2 > 0)
    blez $a2, select_poop_sprite
    addi $t2, $a1, -1
    sll  $t2, $t2, 2
    la   $t3, bubble_colors
    add  $t3, $t3, $t2
    lw   $t4, 0($t3)

    addi $t5, $t1, 1
    sll  $t5, $t5, 2
    addi $t6, $t0, 14592         # Y = 57
    add  $t6, $t6, $t5
    sw   $t4, 0($t6)
    sw   $t4, 4($t6)
    sw   $t4, 256($t6)
    sw   $t4, 260($t6)

select_poop_sprite:
    lw   $t2, flip_angle
    la   $t6, poop_0
    beq  $t2, 0, draw_poop_pixels
    la   $t6, poop_90
    beq  $t2, 1, draw_poop_pixels
    la   $t6, poop_180
    beq  $t2, 2, draw_poop_pixels
    la   $t6, poop_270

draw_poop_pixels:
    li   $t7, 0
p_row_loop:
    li   $t8, 0
p_col_loop:
    lw   $t9, 0($t6)
    beq  $t9, $zero, p_skip_pixel

    addi $a2, $t7, 60            # Y = 60 + row (crosses over Y=60..61 border)
    sll  $a2, $a2, 8
    add  $a3, $t1, $t8
    sll  $a3, $a3, 2
    add  $a2, $a2, $a3
    add  $a2, $t0, $a2
    sw   $t9, 0($a2)

p_skip_pixel:
    addi $t6, $t6, 4
    addi $t8, $t8, 1
    blt  $t8, 4, p_col_loop
    addi $t7, $t7, 1
    blt  $t7, 4, p_row_loop
    jr   $ra

# Reset music timeline and event pointer.
bgm_reset:
    li   $v0, 30
    syscall
    sw   $a0, bgm_cycle_start
    la   $t0, bgm_notes
    sw   $t0, bgm_next_note
    sw   $zero, bgm_pause_time
    addiu $t0, $a0, -250
    sw   $t0, p_last_event
    jr   $ra

# Schedule due notes without blocking keyboard input.
bgm_tick:
    li   $v0, 30
    syscall
    lw   $t0, bgm_cycle_start
    subu $t1, $a0, $t0           # Milliseconds since the loop started
    lw   $t2, bgm_loop_ms
    lw   $t3, bgm_next_note
    bltu $t1, $t2, bgm_due_notes

    # Keep the song on its original timeline across loop boundaries.
    divu $t1, $t2
    mfhi $t1
    subu $t0, $a0, $t1
    sw   $t0, bgm_cycle_start
    la   $t3, bgm_notes

bgm_due_notes:
    la   $t4, bgm_notes_end
bgm_read_note:
    beq  $t3, $t4, bgm_tick_done
    lw   $t5, 0($t3)
    bltu $t1, $t5, bgm_tick_done

    lw   $a1, 8($t3)
    subu $t6, $t1, $t5
    subu $a1, $a1, $t6           # Keep the original end time if a tick was late
    blez $a1, bgm_advance_note     # Skip notes that ended before this tick
    lw   $a0, 4($t3)
    move $a2, $zero
    lw   $a3, 12($t3)
    li   $v0, 31
    syscall
bgm_advance_note:
    addiu $t3, $t3, 16
    j    bgm_read_note

bgm_tick_done:
    sw   $t3, bgm_next_note
    jr   $ra
    
# Draw a 3x3 pink flower inside Player 2's 4x4 region
draw_pink_bow:
    lw   $t0, ADDR_DSPL

    # Calculate flower's starting x coordinate
    lw   $t1, p2_col
    sll  $t1, $t1, 2
    addi $t1, $t1, 12

    # Starting y coordinate
    li   $t2, 60

    la   $t3, pink_bow
    li   $t4, 0

bow_row_loop:
    li   $t5, 0

bow_col_loop:
    lw   $t6, 0($t3)
    beq  $t6, $zero, bow_skip_pixel

    # Calculate y offset
    add  $t7, $t2, $t4
    sll  $t7, $t7, 8

    # Calculate x offset
    add  $t8, $t1, $t5
    sll  $t8, $t8, 2

    # Calculate final display address
    add  $t7, $t7, $t8
    add  $t7, $t7, $t0

    # Draw pixel
    sw   $t6, 0($t7)

bow_skip_pixel:
    addi $t3, $t3, 4
    addi $t5, $t5, 1
    blt  $t5, 3, bow_col_loop

    addi $t4, $t4, 1
    blt  $t4, 3, bow_row_loop

    jr   $ra
