// filenames of the input and output roms
// test_gba will be created as a modified copy of rom_gba
rom_gba equ "rom.gba"
test_gba equ "test.gba"

// the number of evolution slots each Pokemon gets
evolutions_per_pokemon equ 5

// the id for this evolution method
// e.g. Level up is 4 and trade is 5
EVO_HELD_ITEM equ 16

// where you want the code to be inserted
// make sure it is word aligned (ends in 0, 4, 8, or C)
.definelabel free_space, 0x08F00000

// hooks are necessary to clear the item at the proper time
// set this to false to not include the hooks (and thus never clear the item at all)
// set this to true to include the hooks (and thus clear the item properly)
hook equ true

// the flag to coordinate clearing the item
// if hook is set to false, it will never be read or set by this code
FLAG_HELD_ITEM_EVOLUTION equ 0x2FF