
.data
display_address: .word 0x10008000
bubble_colors: .word 0xff0000, 0x00ff00, 0x0000ff, 0xffff00
# Pink flower sprite (4 rows x 4 columns)
# 0 means transparent
flower_sprite:
    .word 0x000000, 0x92400E, 0x000000, 0x000000
    .word 0x92400E, 0xD6A56D, 0x92400E, 0x000000
    .word 0x292524, 0x92400E, 0x92400E, 0x92400E
    .word 0x92400E, 0x292524, 0x292524, 0x92400E

.text
main:
    # Initialize
    lw   $t0, display_address
    li   $t1, 0xffffff       # Frame colour: white

    # --------------------------------
    # Loop 1: Draw horizontal borders
    # --------------------------------

    li   $t2, 8             # Starting X coordinate
    li   $t3, 40             # Ending X coordinate (exclusive)

horizontal_loop:

    # Calculate X offset in bytes
    sll  $t4, $t2, 2         # X * 4

    # Top border: Y = 2 and Y = 3
    addi $t5, $t0, 512       # Base + 2*256
    add  $t5, $t5, $t4
    sw   $t1, 0($t5)

    addi $t5, $t5, 256       # Move down one row
    sw   $t1, 0($t5)

    # Bottom border: Y = 60 and Y = 61
    addi $t5, $t0, 15360     # Base + 60*256
    add  $t5, $t5, $t4
    sw   $t1, 0($t5)

    addi $t5, $t5, 256
    sw   $t1, 0($t5)

    # Move to next X coordinate
    addi $t2, $t2, 1
    bne  $t2, $t3, horizontal_loop # stop if we meet the ending X coordinate


    # --------------------------------
    # Loop 2: Draw vertical borders
    # --------------------------------

    li   $t2, 2              # Starting Y coordinate
    li   $t3, 62             # Ending Y coordinate (exclusive)

vertical_loop:

    # Calculate Y offset in bytes
    sll  $t4, $t2, 8         # Y * 256

    add  $t5, $t0, $t4

    # Left border: X = 8 and X = 9
    sw   $t1, 32($t5)        # 8 * 4
    sw   $t1, 36($t5)        # 9 * 4

    # Right border: X = 38 and X = 39
    sw   $t1, 152($t5)       # 38 * 4
    sw   $t1, 156($t5)       # 39 * 4

    # Move to next Y coordinate
    addi $t2, $t2, 1
    bne  $t2, $t3, vertical_loop


    # =========================================
    # Loop 3: Draw 4 rows of random bubbles
    # =========================================

    li   $s0, 0              # Current bubble row
    li   $s1, 4              # Total number of bubble rows
    li   $s4, 4              # Bubble width and height
    li   $s5, 7              # Number of columns

bubble_row_loop:

    li   $s2, 0              # Current bubble column

bubble_col_loop:

    # --------------------------------
    # Step 1: Generate random colour
    # --------------------------------

    li   $v0, 42             # Random integer syscall
    li   $a0, 0              # Random generator ID
    li   $a1, 4              # Random number: 0, 1, 2, or 3
    syscall                  # Result returned in $a0

    # Find the corresponding colour in our palette
    sll  $t6, $a0, 2         # Index * 4 bytes
    la   $t7, bubble_colors
    add  $t7, $t7, $t6
    lw   $s3, 0($t7)        # $s3 = selected bubble colour


    # --------------------------------
    # Step 2: Calculate bubble position
    # --------------------------------

    # X = 18 + column * 4
    sll  $t6, $s2, 2
    addi $t6, $t6, 10       # Starting X

    # Y = 4 + row * 4
    sll  $t7, $s0, 2
    addi $t7, $t7, 4        # Starting Y


    # --------------------------------
    # Step 3: Draw a 4 * 4 bubble
    # --------------------------------

    li   $t8, 0              # Current pixel row

bubble_pixel_row:

    li   $t9, 0              # Current pixel column

bubble_pixel_col:

    # Calculate pixel Y coordinate
    add  $a2, $t7, $t8

    # Y offset = Y * 256 bytes
    sll  $a2, $a2, 8

    # Calculate pixel X coordinate
    add  $a3, $t6, $t9

    # X offset = X * 4 bytes
    sll  $a3, $a3, 2

    # Final address = base + Y offset + X offset
    add  $a2, $a2, $a3
    add  $a2, $t0, $a2

    # Draw the pixel using the selected colour
    sw   $s3, 0($a2)

    # Move to next pixel in this bubble
    addi $t9, $t9, 1
    bne  $t9, $s4, bubble_pixel_col

    # Move to next pixel row
    addi $t8, $t8, 1
    bne  $t8, $s4, bubble_pixel_row


    # --------------------------------
    # Step 4: Move to next bubble
    # --------------------------------

    addi $s2, $s2, 1
    bne  $s2, $s5, bubble_col_loop

    # Move to next bubble row
    addi $s0, $s0, 1
    bne  $s0, $s1, bubble_row_loop


    # =========================================
    # Loop 4: Draw pink flower character
    # =========================================

    la   $t6, flower_sprite  # Address of flower data

    li   $t7, 0              # Current flower row

flower_row_loop:

    li   $t8, 0              # Current flower column

flower_col_loop:

    # Get colour of current sprite pixel
    lw   $t9, 0($t6)

    # If colour is zero, skip drawing
    beq  $t9, $zero, flower_skip_draw

    # Calculate Y coordinate: 60 + row
    addi $a2, $t7, 60
    sll  $a2, $a2, 8        # Y * 256

    # Calculate X coordinate: 22 + column
    addi $a3, $t8, 22
    sll  $a3, $a3, 2        # X * 4

    # Calculate final bitmap address
    add  $a2, $a2, $a3
    add  $a2, $t0, $a2

    # Draw flower pixel
    sw   $t9, 0($a2)

flower_skip_draw:

    # Move to next sprite pixel in memory
    addi $t6, $t6, 4

    # Move to next column
    addi $t8, $t8, 1
    bne  $t8, 4, flower_col_loop

    # Move to next row
    addi $t7, $t7, 1
    bne  $t7, 4, flower_row_loop

    # Exit
    li   $v0, 10
    syscall
