    .data
    .align 2
zero_float:   .float 0.0
eps_float:    .float 1.0e-9
newline:      .asciz "\n"

io_buffer:    .space 128
name_buf1:    .space 9
name_buf2:    .space 9
names_head:   .word 0

    .align 2
fp_half:      .float 0.5

    .text
    .globl main
    .align 2
main:
    addi  sp, sp, -40
    sw    ra,  36(sp)
    sw    s1,  32(sp)	# s1 = n
    sw    s2,  28(sp)	# s2 = loop counter -- i
    sw    s3,  24(sp)	# x
    sw    s4,  20(sp)	# pointer to amount str
    sw    s5,  16(sp)
    sw    s6,  12(sp)	# account1 pointer
    sw    s7,  8(sp)	# account2 pointer
    fsw   fs0, 4(sp)

    la    t0, names_head
    sw    x0, 0(t0)

    li    a7, 5
    ecall 
    mv    s1, a0                    
    li    s2, 0

loop:
    bge   s2, s1, exit

    jal   ra, parse_line
    mv    s3, a0			# a0 = x
    mv    s4, a1			# a1 = amount

    li    t1, 1
    beq   s3, t1, cmd1
    li    t1, 2
    beq   s3, t1, cmd2
    li    t1, 3
    beq   s3, t1, cmd3
    li    t1, 4
    beq   s3, t1, cmd4
    li    t1, 5
    beq   s3, t1, cmd5
    li    t1, 6
    beq   s3, t1, cmd6
    j     next

cmd1:
    mv    a0, s4
    jal   ra, parse_float
    fmv.s fs0, fa0                   # fs0 = amount

    la    t1, names_head
    lw    s5, 0(t1)
find1:
    beqz  s5, create1
    lw    t0, 0(s5)
    mv    a0, t0
    la    a1, name_buf1
    jal   ra, strcmp
    beqz  a0, name1_ok
    lw    s5, 8(s5)
    j     find1
name1_ok:
    mv    s6, s5
    j     after_find1
create1:
    li    a0, 12
    li    a7, 9
    ecall
    mv    s6, a0
    li    a0, 9
    li    a7, 9
    ecall
    mv    t0, a0
    sw    t0, 0(s6)
    la    t1, name_buf1
copy1:
    lb    t2, 0(t1)
    sb    t2, 0(t0)
    addi  t1, t1, 1
    addi  t0, t0, 1
    bnez  t2, copy1
                      
    # adding new node in front of the list
    la    t0, names_head
    lw    t1, 0(t0)
    sw    t1, 8(s6)
    sw    s6, 0(t0)
    sw    x0, 4(s6)
after_find1:
    # if nameNode->node == 0, create node
    lw    t0, 4(s6)
    beqz  t0, make1
    j     got1
make1:
    li    a0, 16
    li    a7, 9
    ecall
    mv    t0, a0
    lw    t1, 0(s6)                  # Get name string pointer from nameNode
    sw    t1, 0(t0)                  # account->name = name
    la    t1, zero_float
    flw   f12, 0(t1)
    fsw   f12, 4(t0)
    sw    x0,  12(t0)
    sw    t0,  4(s6)
got1:

    la    t1, names_head
    lw    s5, 0(t1)
find2:
    beqz  s5, create2
    lw    t0, 0(s5)
    mv    a0, t0
    la    a1, name_buf2
    jal   ra, strcmp
    beqz  a0, name2_ok
    lw    s5, 8(s5)
    j     find2
name2_ok:
    mv    s7, s5
    j     after_find2
create2:
    li    a0, 12
    li    a7, 9
    ecall
    mv    s7, a0
    li    a0, 9
    li    a7, 9
    ecall
    mv    t0, a0
    sw    t0, 0(s7)
    la    t1, name_buf2
copy2:
    lb    t2, 0(t1)
    sb    t2, 0(t0)
    addi  t1, t1, 1
    addi  t0, t0, 1
    bnez  t2, copy2
    la    t0, names_head
    lw    t1, 0(t0)
    sw    t1, 8(s7)
    sw    s7, 0(t0)
    sw    x0, 4(s7)
after_find2:
    lw    t5, 4(s7)
    beqz  t5, make2
    j     got2
make2:
    li    a0, 16
    li    a7, 9
    ecall
    mv    t5, a0
    lw    t1, 0(s7)
    sw    t1, 0(t5)
    la    t1, zero_float
    flw   f12, 0(t1)
    fsw   f12, 4(t5)
    sw    x0,  12(t5)
    sw    t5,  4(s7)
got2:

    lw    t0, 4(s6)                  # account1 ptr
    flw   fa1, 4(t0)
    fsub.s fa1, fa1, fs0             # n1_node->node->amount -= amount
    fsw   fa1, 4(t0)

    lw    t0, 4(s7)                  # account2 ptr
    flw   fa1, 4(t0)
    fadd.s fa1, fa1, fs0             # n2_node->node->amount += amount
    fsw   fa1, 4(t0)

    lw    t0, 4(s6)
    lw    t4, 12(t0)                 # *p1 = n1_node->node->next
    li    t3, 0                      # found1 = false
p1_loop:
    beqz  t4, p1_done
    lw    t6, 0(t4)
    lw    t1, 0(t6)                  # name string from that nameNode
    mv    a0, t1
    la    a1, name_buf2
    jal   ra, strcmp
    beqz  a0, p1_found               # if (p1->name == name2)
    lw    t4, 12(t4)                 # p1 = p1->next
    j     p1_loop
p1_found:
    flw   f13, 4(t4)
    fneg.s f14, fs0
    fadd.s f13, f13, f14             # p1->amount -= amount
    fsw   f13, 4(t4)
    li    t3, 1                      # found1 = true
p1_done:
    bnez  t3, trans2
p1_create:
    li    a0, 16
    li    a7, 9
    ecall
    mv    t5, a0
    sw    s7, 0(t5)                  # nn1->name = name2
    fneg.s f14, fs0
    fsw   f14, 4(t5)                 # nn1->amount = -amount
    lw    t0, 4(s6)
    lw    t6, 12(t0)
    sw    t6, 12(t5)                 # nn1->next = n1_node->node->next
    sw    t5, 12(t0)                 # n1_node->node->next = nn1

trans2:
    lw    t0, 4(s7)
    lw    t4, 12(t0)
    li    t3, 0
p2_loop:
    beqz  t4, p2_done
    lw    t6, 0(t4)
    lw    t1, 0(t6)
    mv    a0, t1
    la    a1, name_buf1
    jal   ra, strcmp
    beqz  a0, p2_found
    lw    t4, 12(t4)
    j     p2_loop
p2_found:
    flw   f13, 4(t4)
    fadd.s f13, f13, fs0
    fsw   f13, 4(t4)
    li    t3, 1
p2_done:
    bnez  t3, next
p2_create:
    li    a0, 16
    li    a7, 9
    ecall
    mv    t5, a0
    sw    s6, 0(t5)
    fsw   fs0, 4(t5)
    lw    t0, 4(s7)
    lw    t6, 12(t0)
    sw    t6, 12(t5)
    sw    t5, 12(t0)
    j     next


cmd2:
    la    t1, names_head
    lw    t2, 0(t1)
    beqz  t2, print_minus1
    lw    s5, 4(t2)
    flw   f12, 4(s5)
    mv    t4, t2
max_loop:
    beqz  t4, max_done
    lw    t5, 4(t4)
    flw   f13, 4(t5)
    flt.s t0, f12, f13
    beqz  t0, skip_upd2
    fmv.s f12, f13
skip_upd2:
    lw    t4, 8(t4)                  # ptr = ptr->next
    j     max_loop
max_done:
    la    t6, eps_float
    flw   f13, 0(t6)
    fle.s t0, f12, f13
    bnez  t0, print_minus1

    li    t3, 0
    mv    t4, t2
find_max:
    beqz  t4, done_max
    lw    t5, 4(t4)
    flw   f14, 4(t5)
    fsub.s f15, f14, f12
    fabs.s f15, f15
    flt.s t0, f15, f13
    bnez  t0, eq_max
    j     cont2
eq_max:
    lw    t5, 0(t4)
    beqz  t3, set_max
    mv    a0, t5
    mv    a1, t3
    jal   ra, strcmp
    bltz  a0, set_max
cont2:
    lw    t4, 8(t4)
    j     find_max
set_max:
    mv    t3, t5
    j     cont2
done_max:
    mv    a0, t3
    li    a7, 4
    ecall
    la    a0, newline
    li    a7, 4
    ecall
    j     next


cmd3:
    la    t1, names_head
    lw    t2, 0(t1)
    beqz  t2, print_minus1
    lw    s5, 4(t2)
    beqz  s5, min_loop_next_person
    flw   f12, 4(s5)
    j min_loop_start
min_loop_next_person:
    la    t6, zero_float
    flw   f12, 0(t6)
min_loop_start:
    mv    t4, t2
min_loop:
    beqz  t4, min_done
    lw    t5, 4(t4)
    beqz  t5, skip_min
    flw   f13, 4(t5)
    flt.s t0, f13, f12
    beqz  t0, skip_min
    fmv.s f12, f13
skip_min:
    lw    t4, 8(t4)
    j     min_loop
min_done:
    la    t6, eps_float
    flw   f13, 0(t6)
    fneg.s f14, f13
    fge.s t0, f12, f14
    bnez  t0, print_minus1
    li    t3, 0
    mv    t4, t2
find_min:
    beqz  t4, done_min
    lw    t5, 4(t4)
    beqz  t5, cont_min
    flw   f15, 4(t5)
    fsub.s f16, f15, f12
    fabs.s f16, f16
    flt.s t0, f16, f13
    bnez  t0, eq_min
    j     cont_min
eq_min:
    lw    t5, 0(t4)
    beqz  t3, set_min2
    mv    a0, t5
    mv    a1, t3
    jal   ra, strcmp
    bltz  a0, set_min2
cont_min:
    lw    t4, 8(t4)
    j     find_min
set_min2:
    mv    t3, t5
    j     cont_min
done_min:
    mv    a0, t3
    li    a7, 4
    ecall
    la    a0, newline
    li    a7, 4
    ecall
    j     next

cmd4:
    la    t1, names_head
    lw    s5, 0(t1)
find4:
    beqz  s5, print_zero4
    lw    t4, 0(s5)
    mv    a0, t4
    la    a1, name_buf1
    jal   ra, strcmp
    beqz  a0, got4
    lw    s5, 8(s5)
    j     find4
got4:
    lw    t0, 4(s5)
    beqz  t0, print_zero4
    lw    t4, 12(t0)
    li    t1, 0
    la    t6, eps_float
    flw   f13, 0(t6)
cred4:
    beqz  t4, done4
    flw   f14, 4(t4)
    flt.s t0, f13, f14
    beqz  t0, skip4
    addi  t1, t1, 1
skip4:
    lw    t4, 12(t4)                 # ptr = ptr->next
    j     cred4
done4:
    mv    a0, t1
    li    a7, 1
    ecall
    la    a0, newline
    li    a7, 4
    ecall
    j     next
print_zero4:
    li    a0, 0
    li    a7, 1
    ecall
    la    a0, newline
    li    a7, 4
    ecall
    j     next


cmd5:
    la    t1, names_head
    lw    s5, 0(t1)
find5:
    beqz  s5, print_zero5
    lw    t4, 0(s5)
    mv    a0, t4
    la    a1, name_buf1
    jal   ra, strcmp
    beqz  a0, got5
    lw    s5, 8(s5)
    j     find5
got5:
    lw    t0, 4(s5)
    beqz  t0, print_zero5
    lw    t4, 12(t0)
    li    t1, 0
    la    t6, eps_float
    flw   f13, 0(t6)
    fneg.s f13, f13
deb5:
    beqz  t4, done5
    flw   f14, 4(t4)
    flt.s t0, f14, f13
    beqz  t0, skip5
    addi  t1, t1, 1
skip5:
    lw    t4, 12(t4)
    j     deb5
done5:
    mv    a0, t1
    li    a7, 1
    ecall
    la    a0, newline
    li    a7, 4
    ecall
    j     next
print_zero5:
    li    a0, 0
    li    a7, 1
    ecall
    la    a0, newline
    li    a7, 4
    ecall
    j     next

cmd6:
    la    t1, names_head
    lw    s5, 0(t1)
find6: 
    beqz  s5, print_zero6
    lw    t4, 0(s5)
    mv    a0, t4
    la    a1, name_buf1
    jal   ra, strcmp
    beqz  a0, got6
    lw    s5, 8(s5)
    j     find6
got6:
    lw    t0, 4(s5)
    beqz  t0, print_zero6
    lw    t4, 12(t0)
scan6:
    beqz  t4, print_zero6
    lw    t5, 0(t4)
    lw    t1, 0(t5)
    mv    a0, t1
    la    a1, name_buf2
    jal   ra, strcmp
    beqz  a0, found6
    lw    t4, 12(t4)
    j     scan6
found6:
    flw   fa0, 4(t4)
    la    a1, io_buffer
    jal   ra, format_float
    la    a0, io_buffer
    li    a7, 4
    ecall
    la    a0, newline
    li    a7, 4
    ecall
    j     next
print_zero6:
    la    t0, zero_float
    flw   fa0, 0(t0)
    la    a1, io_buffer
    jal   ra, format_float
    la    a0, io_buffer
    li    a7, 4
    ecall
    la    a0, newline
    li    a7, 4
    ecall
    j     next

print_minus1:
    li    a0, -1
    li    a7, 1
    ecall
    la    a0, newline
    li    a7, 4
    ecall
    j     next

next:
    addi  s2, s2, 1
    j     loop

exit:
    fsw   fs0, 4(sp)
    lw    s7,   8(sp)
    lw    s6,   12(sp)
    lw    s5,   16(sp)
    lw    s4,   20(sp)
    lw    s3,   24(sp)
    lw    s2,   28(sp)
    lw    s1,   32(sp)
    lw    ra,   36(sp)
    addi  sp, sp, 40
    li    a7, 10
    ecall


parse_line:
    addi sp, sp, -16
    sw   ra, 12(sp)                  # return address
    sw   s2, 8(sp)                   # s2 = source ptr
    sw   s3, 4(sp)                   # s3 = dest ptr
    sw   s4, 0(sp)                   # s4 = current char

    la   a0, io_buffer
    li   a1, 128
    li   a7, 8
    ecall


    la   s2, io_buffer 
    la   s3, name_buf1
    sb   x0, 0(s3) 
    la   s3, name_buf2
    sb   x0, 0(s3) 
    
    li   a0, 0                       # a0 will be = x
    li   a1, 0                       # a1 will be = amount
    
    lb   s4, 0(s2)
    addi t0, s4, -48
    li   t1, 10
    beq  s4, t1, no_argument_cmd
    
    mv   a0, t0                     # a0 = x
    addi s2, s2, 2

    la   s3, name_buf1
parse_name1_loop:
    lb   s4, 0(s2)
    li   t2, ' '
    beq  s4, t2, name1_ready
    li   t2, 10
    beq  s4, t2, terminate_name1 

    sb   s4, 0(s3)
    addi s2, s2, 1
    addi s3, s3, 1
    j    parse_name1_loop
    
name1_ready:
    addi s2, s2, 1
terminate_name1:
    sb   x0, 0(s3)
    lb   s4, 0(s2)
    beqz s4, parsing_done


    la   s3, name_buf2
parse_name2_loop:
    lb   s4, 0(s2)
    li   t2, ' '
    beq  s4, t2, name2_ready
    li   t2, 10
    beq  s4, t2, terminate_name2 

    sb   s4, 0(s3)
    addi s2, s2, 1
    addi s3, s3, 1
    j    parse_name2_loop
    
name2_ready:
    addi s2, s2, 1
terminate_name2:
    sb   x0, 0(s3)
    lb   s4, 0(s2)
    beqz s4, parsing_done

    mv a1, s2
    j parsing_done

no_argument_cmd:
    mv a0, t1

parsing_done:
    lw   s4, 0(sp)
    lw   s3, 4(sp)
    lw   s2, 8(sp)
    lw   ra, 12(sp)
    addi sp, sp, 16
    ret

parse_float:
    addi sp, sp, -12
    sw   ra, 8(sp)
    sw   s2, 4(sp)
    sw   s3, 0(sp)
    mv   t0, a0
    li   s2, 0
    lb   t1, 0(t0)
    li   t2, '-'
    bne  t1, t2, start_parse
    li   s2, 1
    addi t0, t0, 1
start_parse:
    li   t1, 0
    li   t2, 0
    li   t3, 1
    li   t4, 0
    li   s3, 10
parse_loop:
    lb   t5, 0(t0)
    beq  t5, x0, parse_done
    li   t6, 10
    beq  t5, t6, parse_done
    li   t6, ' '
    beq  t5, t6, parse_done
    li   t6, '.'
    beq  t5, t6, is_decimal
    addi t5, t5, -'0'
    bnez t4, parse_frac
parse_int_part:
    mul  t1, t1, s3
    add  t1, t1, t5
    j    parse_next
parse_frac:
    mul  t2, t2, s3
    add  t2, t2, t5
    mul  t3, t3, s3
    j    parse_next
is_decimal:
    li   t4, 1
parse_next:
    addi t0, t0, 1
    j    parse_loop
parse_done:
    fcvt.s.w fa1, t1
    fcvt.s.w fa2, t2
    fcvt.s.w fa3, t3
    fdiv.s fa2, fa2, fa3
    fadd.s fa0, fa1, fa2
    beq  s2, x0, parse_ret
    fneg.s fa0, fa0
parse_ret:
    lw   s3, 0(sp)
    lw   s2, 4(sp)
    lw   ra, 8(sp)
    addi sp, sp, 12
    ret

format_float:
    addi sp, sp, -20
    sw   ra, 16(sp)
    sw   s2, 12(sp)
    sw   s3, 8(sp)
    sw   s4, 4(sp)
    sw   s5, 0(sp)
    mv   t0, a1
    la   t1, zero_float
    flw  f12, 0(t1)
    flt.s t1, fa0, f12
    beq   t1, x0, format_positive
    li    t2, '-'
    sb    t2, 0(t0)
    addi  t0, t0, 1
    fabs.s fa0, fa0
format_positive:
    fcvt.w.s s4, fa0, rtz
    mv s5, s4
    beq  s4, x0, print_zero_char
    li   t1, 1
    li   s3, 10
find_divisor_loop:
    mul  t2, t1, s3
    ble  t2, s4, continue_divisor_loop
    j    print_int_digits
continue_divisor_loop:
    mv   t1, t2                      # t1 = t2
    j    find_divisor_loop
print_int_digits:
    beq  t1, x0, int_done
    div  t2, s4, t1
    rem  s4, s4, t1
    addi t2, t2, 48
    sb   t2, 0(t0)
    addi t0, t0, 1
    div  t1, t1, s3
    j    print_int_digits
print_zero_char:
    li t1, '0'
    sb t1, 0(t0)
    addi t0, t0, 1
int_done:
    li   t1, '.'
    sb   t1, 0(t0)
    addi t0, t0, 1
    fcvt.s.w f1, s5
    fsub.s fa0, fa0, f1
    li   t1, 100
    fcvt.s.w f1, t1
    fmul.s fa0, fa0, f1
    la   t1, fp_half
    flw  f1, 0(t1)
    fadd.s fa0, fa0, f1
    fcvt.w.s t1, fa0, rtz
    li   t2, 10
    div  t3, t1, t2
    rem  t4, t1, t2
    addi t3, t3, 48
    sb   t3, 0(t0)
    addi t0, t0, 1
    addi t4, t4, 48
    sb   t4, 0(t0)
    addi t0, t0, 1
    sb   x0, 0(t0)
    lw   s5, 0(sp)
    lw   s4, 4(sp)
    lw   s3, 8(sp)
    lw   s2, 12(sp)
    lw   ra, 16(sp)
    addi sp, sp, 20
    ret


strcmp:
    lb    t0, 0(a0)
    lb    t1, 0(a1)
    sub   t2, t0, t1
    bnez  t2, diff
    beqz  t0, equal
    addi  a0, a0, 1
    addi  a1, a1, 1
    j     strcmp
diff:
    mv    a0, t2
    ret
equal:
    li    a0, 0
    ret