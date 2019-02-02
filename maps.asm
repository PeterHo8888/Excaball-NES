 ; Figure out a way to use offsets instead
loadMap:
    LDA room_num
    CMP #$00
    BNE .second
    LDA #LOW(firstmap)
    STA pointerLo
    LDA #HIGH(firstmap)
    STA pointerHi
    JMP .endLoadMap
.second
    LDA room_num
    CMP #$01
    BNE .third
    LDA #LOW(secondmap)
    STA pointerLo
    LDA #HIGH(secondmap)
    STA pointerHi
    JMP .endLoadMap
.third
    LDA room_num
    CMP #$02
    BNE .fourth
    LDA #LOW(thirdmap)
    STA pointerLo
    LDA #HIGH(thirdmap)
    STA pointerHi
    JMP .endLoadMap
.fourth
.endLoadMap
    RTS
    

switchMap:
    LDA #$04
    STA sprite_RAM_offset
    JSR ClearMap
    JSR LoadBkg
    JSR Init_player
    ;JSR Init_coins_gems
    JSR UpdateCOINS
    ;JSR UpdateSPIKES
    JSR UpdateDOORS
    LDA #$01
    STA NMI_flag 
    RTS

NextRoom:
    INC room_num
    JSR switchMap
    RTS

LoadBkg:
    ;INC room_num
    LDA room_num
    CMP #02
    BNE .dochange
    LDA #$00
    STA room_num
.dochange
    JSR loadMap
.end
    RTS
    
    
ClearMap:
    LDX #$00
    LDY #$00
    LDA #$00
.loop
    STA $0200, X
    INX
    CPX #0
    BEQ .endclear
    JMP .loop
        
.endclear
    RTS
    
; Direction: 
; 0 - right
; 1 - down
; 2 - left
; 3 - up

GetPixel:                       ; to do: GetPixelLow and GetPixelHi?
    ; A set from prev call
    STA maps_dir
    LDX ball_y
    STX temp_y                  ; keep local copy of X and Y
    LDX ball_x
    STX temp_x

.increase_y                     ; increase y by 1 if down
    LDA maps_dir
    CMP #$01
    BNE .increase_y2
    INC temp_y
    JMP .next
    ;INC temp_x
    ;JMP .increase_x
    ;JMP .next
.increase_y2                    ; increase y by 4 if up
    CMP #$03
    BNE .increase_x
    INC temp_y
    INC temp_y
    INC temp_y
    INC temp_y
    INC temp_y
    JMP .next
    ;DEC temp_x
.increase_x
    CMP #$00
    BNE .increase_x2
    ;DEC temp_x
    ;DEC temp_x
    ;DEC temp_x
    ;DEC temp_x
    ;DEC temp_x
    ;DEC temp_x
    ;DEC temp_x
    ;INC temp_y
    ;INC temp_y
    ;INC temp_y
    ;INC temp_y
    ;INC temp_y
    ;INC temp_y
    JMP .next
.increase_x2
.next
    LDX #$00
    LDY #$00
    LDA pointerHi
    PHA
	LDA #$00
	;JMP .loop_y
    LDA temp_y
    
    ; A = temp_y / 64
    LSR A
    LSR A
    LSR A
    LSR A
    LSR A
    LSR A
    
	    
	; temp_maps += A
	STA temp_var

	;LDA temp_maps
	;CLC
	;ADC temp_var
	;STA temp_maps
	
	;LDA temp_x
	;CLC
	;ADC temp_var
	STA temp_maps
    
    LDA pointerHi
	CLC
    ADC temp_var
    STA pointerHi
	
	
	LDA #$00
	JMP .start_lower_y
    
	
    
;.loop_y             ; don't touch because this at least works
;    CMP temp_y
;    BCS .done_y
;    INC pointerHi
;    INX
;    CLC
;    ADC #64         ; #240 / #4 = #60  screen_height / 4 pixels per sprite
;    JMP .loop_y
;.done_y             ; i think it's finding which vertical quarter of the screen we're in.  not sure what #64 is for
;    DEC pointerHi
;    DEX
;    STX temp_maps
; pointerLo = (y/8)*32 + (x/8)
;    LDA #$00    
    
.start_lower_y
    CMP temp_y
    BCS .end_lower_y
    CLC
    ADC #8         ; #240 / #4 = #60
    INY
    JMP .start_lower_y
.end_lower_y                ; Don't touch
    DEY
    TYA
    SEC
    SBC temp_maps
    SEC
    SBC temp_maps
    SEC
    SBC temp_maps
    SEC
    SBC temp_maps
    SEC
    SBC temp_maps
    SEC
    SBC temp_maps
    SEC
    SBC temp_maps
    SEC
    SBC temp_maps
    
    STA temp_maps
    LDA #$00
    LDX #$00
.loop32
    CPX #32
    BEQ .done_loop32
    CLC
    ADC temp_maps
    INX
    JMP .loop32
.done_loop32
    STA temp_maps
    LDX #$00
    LDA #$00
.loop_x                 ; TODO: we need to account for TWO locations (ball-4 and ball+4)
    CMP temp_x
    BCS .done
    INX
    INC temp_maps
    CLC
    ADC #8         ; #256 / #8 = #32
    JMP .loop_x
.done
    DEX
    DEC temp_maps
    LDY temp_maps
    LDA maps_dir
    CMP #$00
    BEQ .add_right
    CMP #$01
    BEQ .add_down
    CMP #$03
    BEQ .add_up
    JMP .done_next
.add_right
    INY
;    TYA
;    CLC
;    ADC #32
;    TAY
;    BCS .fix_carry_right
    JMP .done_next
.fix_carry_right
;    INC pointerHi
;    JMP .done_next
.add_down
    TYA
    CLC
    ADC #32
    TAY
    JMP .done_next
.add_up
;    DEY
;    TYA
;    SEC
;    SBC #32
;    TAY
;    BCC .fix_carry_up
    JMP .done_next
;.fix_carry_up
;    DEC pointerHi
;    JMP .done_next
.done_next

    LDA maps_dir
    CMP #$00
    BEQ .is_right_or_left
    CMP #$02
    BEQ .is_right_or_left
    
    LDA [pointerLo], Y
    
    ; NEW STUFF: CHECK CURRENT X COORD AND ONE NEXT TO IT (X+1)
    ; ONLY FOR UP AND DOWN
    CMP #1
    BEQ .already_found_block_to_right
    INY
    ; continue to LDA[pointerLo], Y
    
.is_right_or_left
    LDA [pointerLo], Y
.already_found_block_to_right
    TAX
    PLA
    STA pointerHi
    TXA
    STA current_block
    LDA maps_dir
    CMP #$00
    BEQ .done_right
    CMP #$01
    BEQ .done_down
    CMP #$02
    BEQ .done_left
    CMP #$03
    BEQ .done_up
    JMP .done_done
.done_right
    LDA current_block
    STA block_right
    CMP #$01
    BNE .done_done
    JMP .done_done
.done_down
    LDA current_block
    STA block_down
    JMP .done_done
.done_left
    LDA current_block
    STA block_left
    CMP #$01
    BNE .done_done
    JMP .done_done
.done_up
    LDA current_block
    STA block_up
.done_done
    RTS  
    
; pointerHi = +1
; pointerLo = 67 = (y/8 - 8 * overflows_in_y) * 32 + x/8 = 80-64*1 + 24/8    
; X holds overflows over .loop_y, then is counter in .loop32
; RULE: X holds result of multiplication and division, but X is compared in mult
;       and A is compared in division
    
mapconstants:
    .db $00, $02
    