true equ 1
false equ 0

.include "config.asm"

.definelabel Task_EvolutionScene_hook_addr, 0x080CED62
.definelabel Task_EvolutionScene_hook_return, 0x080CED6E

.definelabel GetEvolutionTargetSpecies_hook1_addr, 0x08043110
.definelabel GetEvolutionTargetSpecies_hook1_return1, 0x08042F96
.definelabel GetEvolutionTargetSpecies_hook1_return2, 0x0804311C

.definelabel GetEvolutionTargetSpecies_hook2_addr, 0x08042F08
.definelabel GetEvolutionTargetSpecies_hook2_return, 0x08042F12

.definelabel GetMonData, 0x0803FBE8
.definelabel SetMonData, 0x0804037C

.definelabel FlagGet, 0x0806E6D0
.definelabel FlagSet, 0x0806E680
.definelabel FlagClear, 0x0806E6A8

.definelabel noevo, 0x08043110
.definelabel yesevo, 0x08043008

.definelabel off_8042FC0, 0x08042FC0
.definelabel jpt_8042FB8, readu32(rom_gba, off_8042FC0 & 0x1FFFFFF)

.definelabel rtc_hour, 0x03005542

MON_DATA_SPECIES equ 11
MON_DATA_HELD_ITEM equ 12
MON_DATA_BEAUTY equ 23

// -----------------------------------------------------------------------------

.gba
.thumb

.open rom_gba, test_gba, 0x08000000

.org free_space

.area 236
    .align 2

    level_with_item:
        push {r1-r5}
        mov r4, r2
        mov r5, r3

        // GetMonData(pokemon, MON_DATA_HELD_ITEM)
        mov r0, r8
        mov r1, MON_DATA_HELD_ITEM
        ldr r3, =GetMonData |1
        bl @@call

        mov r1, r7
        mov r2, EVOLUTIONS_PER_POKEMON * 8
        mul r1, r2
        add r1, r4      
        add r1, r5

        ldrh r1, [r1, #2]
        cmp r0, r1
        bne @@noevo

    .if hook
        // FlagSet(FLAG_HELD_ITEM_EVOLUTION)
        ldr r0, =FLAG_HELD_ITEM_EVOLUTION
        ldr r3, =FlagSet |1
        bl @@call
    .endif

    @@yesevo:
        pop {r1-r5}
        ldr r0, =yesevo |1
        bx r0

    @@noevo:
        pop {r1-r5}
        ldr r0, =noevo |1
        bx r0

    @@call:
        bx r3

    level_with_item_at_night:
        ldr r0, =rtc_hour
        ldrb r0, [r0]
        cmp r0, night_start
        bhs level_with_item
        cmp r0, night_end
        blo level_with_item
        ldr r0, =noevo |1
        bx r0

    level_with_item_during_day:
        ldr r0, =rtc_hour
        ldrb r0, [r0]
        cmp r0, night_start
        bhs @@noevo
        cmp r0, night_end
        blo @@noevo
        b level_with_item
    @@noevo:
        ldr r0, =noevo |1
        bx r0

    // intercepts the code responsible for updating the species after a
    // successful evolution, to conditionally remove the held item
    Task_EvolutionScene_hook:
        // this is code from the offset we hooked
        add r2, r1
        add r2, #0xC
        mov r0, r9
        mov r1, #MON_DATA_SPECIES
        ldr r3, =SetMonData |1
        bl @@call

        // return early if the flag isn't set
        ldr r0, =FLAG_HELD_ITEM_EVOLUTION
        ldr r3, =FlagGet |1
        bl @@call
        cmp r0, #0
        beq @@return

        // remove item if we're still here (e.g. flag was set)
        mov r0, r9
        mov r1, #MON_DATA_HELD_ITEM
        ldr r2, =@@zero
        ldr r3, =SetMonData |1
        bl @@call

    @@return:
        ldr r3, =Task_EvolutionScene_hook_return |1
    @@call:
        bx r3
    @@zero:
        .halfword 0x0

    // prevents level-triggered evolutions from overriding one another
    // first match gets priority
    GetEvolutionTargetSpecies_hook1:
        // this is adapted from code at the offset we hooked
        ldr r0, [sp, #4]
        add r0, #1
        str r0, [sp, #4]
        cmp r0, EVOLUTIONS_PER_POKEMON - 1
        bgt @@return2
        mov r0, r10
        cmp r0, #0
        bne @@return2

    @@return1:
        ldr r0, =GetEvolutionTargetSpecies_hook1_return1 |1
        bx r0

    @@return2:
        ldr r0, =GetEvolutionTargetSpecies_hook1_return2 |1
        bx r0

    GetEvolutionTargetSpecies_hook2:
        // FlagClear(FLAG_HELD_ITEM_EVOLUTION)
        ldr r0, =FLAG_HELD_ITEM_EVOLUTION
        ldr r3, =FlagClear |1
        bl @@call

        // GetMonData(pokemon, MON_DATA_BEAUTY)
        mov r0, r8
        mov r1, MON_DATA_BEAUTY
        ldr r3, =GetMonData |1
        bl @@call

        ldr r3, =GetEvolutionTargetSpecies_hook2_return |1

    @@call:
        bx r3

    .pool
.endarea

.org jpt_8042FB8 + (EVO_HELD_ITEM -1) * 4
.word level_with_item

.org jpt_8042FB8 + (EVO_HELD_ITEM_DAY -1) * 4
.word level_with_item_during_day

.org jpt_8042FB8 + (EVO_HELD_ITEM_NIGHT -1) * 4
.word level_with_item_at_night

.if hook
    .org Task_EvolutionScene_hook_addr
    .area 0xC, 0xFE
        ldr r3, =Task_EvolutionScene_hook |1
        bx r3
        .pool
    .endarea

    .org GetEvolutionTargetSpecies_hook1_addr
    .area 0xC, 0xFE
        ldr r0, =GetEvolutionTargetSpecies_hook1 |1
        bx r0
        .pool
    .endarea

    .org GetEvolutionTargetSpecies_hook2_addr
    .area 0xA, 0xFF
        ldr r3, =GetEvolutionTargetSpecies_hook2 |1
        bx r3
        .pool
    .endarea
.endif

.close
