# CSC258 Magical Drop - Milestones 2 and 3 (corrected)
# Bitmap configuration: unit 8x8, display 256x256, base 0x10008000
# Keyboard: MARS Keyboard and Display MMIO / Saturn Bitmap input
# Corrections: bounded underside-stack throw, initial no-triple generation,
# successful throw key counting; matching/flood-fill/float/chain retained.
# Review and adapt this code for your project submission.

.data
display_address:  .word 0x10008000
keyboard_address: .word 0xffff0000
bubble_colors:    .word 0xff0000, 0x00ff00, 0x0000ff, 0xffff00
game_over_message: .asciiz "GAME\nOVER\nYOU LOST\n"
game_over_line1:   .asciiz "GAME"
game_over_line2:   .asciiz "OVER"
game_over_line3:   .asciiz "YOU LOST"
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
    .byte 0                    # End of glyph table

# 7 columns x 14 rows = 98 words (0 = empty, 1 = red, 2 = green, 3 = blue, 4 = yellow)
grid:             .space 392
match_grid:       .space 392

# Character 1 (poop1) - A (left), D (right), S (grab), W (throw)
p1_col:           .word 2
p1_held_color:    .word 0
p1_held_count:    .word 0

# Character 2 (poop2) - J (left), L (right), K (grab), I (throw)
p2_col:           .word 4
p2_held_color:    .word 0
p2_held_count:    .word 0

# 360-degree flip animation state ('r' key)
flip_timer:       .word 0
flip_angle:       .word 0

# Row advancement counter (advances every 10 keystrokes)
keystroke_count:  .word 0

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

.text
.globl main

main:
    jal  init_grid               # Populate top 4 rows in memory
    jal  draw_static_borders     # Draw top, left, and right white borders
    jal  draw_screen             # Draw initial frame ONCE

game_loop:
    
    li   $v0, 32
    li   $a0, 1
    syscall
    
    # 1. Poll keyboard MMIO (0xffff0000)
    lw   $t0, keyboard_address
    lw   $t1, 0($t0)
    bne  $t1, 1, check_flip_anim # If no key pressed, only redraw if flipping

    lw   $t2, 4($t0)             # Read ASCII key from 0xffff0004
    beq  $t2, 0x71, quit_game    # 'q' -> quit

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
    li   $t3, 16                 # 16 frames total (4 frames per 90 deg)
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
    addi $t4, $t4, 364           # Row 13 start: 13 * 7 * 4
    li   $t5, 0
check_gameover_loop:
    lw   $t6, 0($t4)
    bne  $t6, $zero, game_over
    addi $t4, $t4, 4
    addi $t5, $t5, 1
    blt  $t5, 7, check_gameover_loop
    j    redraw_and_sleep

# =========================================================
# Animation Update & Conditional Redraw (No Flicker!)
# =========================================================
check_flip_anim:
    lw   $t3, flip_timer
    blez $t3, sleep_step         # Nothing changed -> DO NOT redraw

    addi $t3, $t3, -1
    sw   $t3, flip_timer

    andi $t4, $t3, 3             # Update angle every 4 frames
    bne  $t4, $zero, sleep_step
    lw   $t5, flip_angle
    addi $t5, $t5, 1
    andi $t5, $t5, 3
    sw   $t5, flip_angle

redraw_and_sleep:
    jal  draw_screen             # Only redraw when state actually changed!

sleep_step:
    li   $v0, 32                 # Throttle polling
    li   $a0, 16
    syscall
    j    game_loop

game_over:
    jal  draw_game_over_screen  # Bitmap overlay (losing condition only)
    li   $v0, 4                  # Print message on console
    la   $a0, game_over_message
    syscall
    j    quit_game

quit_game:
    li   $v0, 10
    syscall

# =========================================================
# Subroutines
# =========================================================

# Draw a two-line GAME OVER / YOU LOST bitmap end screen.
# Only called by game_over; pressing q bypasses it.
draw_game_over_screen:
    addi $sp, $sp, -4
    sw   $ra, 0($sp)

    # Wipe the playfield interior; leave the white frame intact.
    lw   $t0, display_address
    li   $t1, 4                 # y
end_clear_y:
    li   $t2, 10                # x
end_clear_x:
    sll  $t3, $t1, 8            # 64 units * 4 bytes per unit
    sll  $t4, $t2, 2
    addu $t3, $t3, $t4
    addu $t3, $t3, $t0
    sw   $zero, 0($t3)
    addi $t2, $t2, 1
    blt  $t2, 38, end_clear_x
    addi $t1, $t1, 1
    blt  $t1, 60, end_clear_y

    # Each letter is 3 units across; space is 2 units.

    #First and Second line: GAME and OVER (white)
    la   $a0, game_over_line1
    li   $a1, 18                # x
    li   $a2, 20                # y
    li   $a3, 0xffffff         # white
    jal  draw_bitmap_text
    
    la   $a0, game_over_line1
    li   $a1, 18                # x
    li   $a2, 30                # y
    li   $a3, 0xffffff         # white
    jal  draw_bitmap_text
    
    #Third line: YOU LOST (light red)
    la   $a0, game_over_line3
    li   $a1, 12
    li   $a2, 42
    li   $a3, 0xff4444
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

    la   $s4, bitmap_letters   # Search font glyphs
end_text_find:
    lbu  $t1, 0($s4)
    beq  $t1, $zero, end_text_advance
    beq  $t1, $t0, end_text_found
    addi $s4, $s4, 6
    j    end_text_find

end_text_found:
    li   $s5, 0                # glyph row (0..4)
end_glyph_row:
    addiu $t0, $s5, 1
    addu $t0, $s4, $t0
    lbu  $t1, 0($t0)            # 3-bit glyph row mask
    li   $t2, 0                # glyph column (0..2)
end_glyph_col:
    li   $t3, 4                # leftmost bit
    srlv $t3, $t3, $t2         # 4, 2, 1
    and  $t4, $t1, $t3
    beq  $t4, $zero, end_glyph_skip

    addu $t5, $s2, $s5         # y + glyph row
    sll  $t5, $t5, 8
    addu $t6, $s1, $t2         # x + glyph column
    sll  $t6, $t6, 2
    addu $t5, $t5, $t6
    lw   $t6, display_address
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

# Fill the first four rows with random colours, avoiding pre-existing
# vertical triples. Match removal should be initiated by gameplay throws.
init_grid:
    la   $t4, grid
    li   $t5, 0                  # Linear index, 0..27
init_grid_loop:
    li   $v0, 42
    li   $a0, 0
    li   $a1, 4
    syscall
    addi $a0, $a0, 1            # Colours 1..4
    blt  $t5, 14, init_store     # First two rows cannot make a triple
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
    lw   $t0, display_address
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
    lw   $t0, display_address
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
# Milestone 3: Vertical Match-3 -> Flood-Fill -> Upward Gravity
# =========================================================
resolve_matches:
    addi $sp, $sp, -24
    sw   $ra, 0($sp)
    sw   $s0, 4($sp)
    sw   $s1, 8($sp)
    sw   $s2, 12($sp)
    sw   $s3, 16($sp)
    sw   $s4, 20($sp)
    
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

    li   $s0, 0                  # $s0 = match_found flag

    # B. Stage 1: Scan columns for vertical match-3 triggers
    li   $s1, 0                  # col = 0..6
vert_col_loop:
    bltz $s4, check_this_col     # [ADDED] If $s4 < 0, check all columns
    bne  $s1, $s4, next_vert_col # [ADDED] On pass 1, only trigger on thrown column

check_this_col:                  # [ADDED]
    li   $s2, 0                  # row = 0..11
vert_row_loop:
    mul  $t0, $s2, 7
    add  $t0, $t0, $s1
    sll  $t0, $t0, 2             # Byte offset of (row, col)
    la   $t1, grid
    add  $t2, $t1, $t0
    lw   $t3, 0($t2)             # grid[row][col]
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
    li   $s0, 1                  # match_found = 1

next_vert_row:
    addi $s2, $s2, 1
    blt  $s2, 12, vert_row_loop

next_vert_col:
    addi $s1, $s1, 1
    blt  $s1, 7, vert_col_loop

    # If no vertical match-3 triggered, exit chain_loop
    beq  $s0, $zero, resolve_done

    # C. Stage 2: Flood-fill connected same-color neighbors
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
    lw   $t6, 0($t5)             # Target color of matched cell

    # Check UP (row > 0)
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
    bne  $s3, $zero, flood_pass  # Repeat until flood-fill stabilizes

    # D. Delete all marked bubbles
    la   $t0, grid
    la   $t1, match_grid
    li   $t2, 0
delete_loop:
    lw   $t3, 0($t1)
    beq  $t3, $zero, skip_delete
    sw   $zero, 0($t0)
skip_delete:
    addi $t0, $t0, 4
    addi $t1, $t1, 4
    addi $t2, $t2, 1
    blt  $t2, 98, delete_loop

    # E. Apply upward gravity (float bubbles toward row 0)
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

    # F. Repeat chain_loop to check for cascade matches!
    li   $s4, -1
    j    chain_loop

resolve_done:
    lw   $ra, 0($sp)
    lw   $s0, 4($sp)
    lw   $s1, 8($sp)
    lw   $s2, 12($sp)
    lw   $s3, 16($sp)
    lw   $s4, 20($sp)
    addi $sp, $sp, 24
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
    # STEP 2: keep new rows from creating pre-existing vertical triples.
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

    lw   $t0, display_address

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

    lw   $ra, 0($sp)
    addi $sp, $sp, 4
    jr   $ra

draw_single_poop:
    lw   $t0, display_address
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