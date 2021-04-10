## Evolve by Leveling Up While Holding An Item

Adds evolution methods to allow Pokémon to evolve by leveling up while holding a particular item.

This branch includes day and night variations for use with Happiny, Gligar, and Sneasel. The RTC itself is not included.

Other implementations of this evolution method have subtle bugs - they remove the item even if the player hits Ⓑ to cancel the evolution. This avoids that.

### How do I insert this?

First, make sure you've repointed the table mentioned in the first part of [this](https://www.pokecommunity.com/showpost.php?p=8309246&postcount=1) post.

Open `config.asm` in your preferred text editor.

Normally, each Pokémon only gets `5` evolution slots. If you've changed this at all, make sure to update the definition of `evolutions_per_pokemon`.

Pick an evolution id for `Level w/ Item`. In a vanilla game, the first unused one is `16`, so use that if this is the first evolution method you're adding. Make the definition of `EVO_HELD_ITEM` match your choice.

Pick an evolution id for `Level w/ Item (Day)`. Make the definition of `EVO_HELD_ITEM_DAY` match your choice.

Pick an evolution id for `Level w/ Item (Night)`. Make the definition of `EVO_HELD_ITEM_NIGHT` match your choice.

Decide where you want the code to be inserted. This requires `236` bytes of free space, starting from a word-aligned (ending in `0`, `4`, `8`, or `C`) offset. Record your choice in the definition of `free_space`.

In order to coordinate removing the item at the right time, a few hooks and an otherwise unused scripting flag are required. Update the definition of `FLAG_HELD_ITEM_EVOLUTION` to your choice of flag if the default `0x2FF` doesn't work for you.

If, however, you don't care about removing the item, you can disable that entirely by changing the definition of `hook` to `false`. If you do this, `FLAG_HELD_ITEM_EVOLUTION` will never be read or set, Pokémon will not have their item removed upon evolving using this method, and the actual used space in your ROM will be somewhat smaller. To be clear, the Pokémon will still be required to be holding the specified item in order to evolve.

You can modify what counts as night with `night_start` and `night_end`. By default, night starts at 9pm and lasts until 6am.

Place your ROM into this folder and rename it `rom.gba`.

You'll need [armips](https://github.com/Kingcom/armips) for the next part.

Open a command prompt / terminal, and run `armips level-with-item.asm`. Your output will be in `test.gba`; `rom.gba` will not be modified.

### How do I modify PGE's ini to match this?

The relevant keys in the ini are `NumberOfEvolutionTypes`, `EvolutionNameX` and `EvolutionXParam`.

For the sake of example, I will assume these were the first evolution methods you've added and they were added 16, 17, and 18. I would do:

```ini
NumberOfEvolutionTypes=18
EvolutionName16=Level w/ Item
Evolution16Param=item
EvolutionName17=Level w/ Item (Day)
Evolution17Param=item
EvolutionName18=Level w/ Item (Night)
Evolution18Param=item
```

Now you can set up these evolutions in PGE.

### Notes

One of the hooks required to make the item removal work properly prevents level-triggered evolutions (e.g. happiness, specific level, beauty) from overriding one another.

Normally, if a Pokémon qualifies for multiple LTEs, it is the lastmost slot that actually determines the evolution. For example, if you had a Pokémon with a friendship evolution in slot 1 and a beauty evolution in slot 2, if the Pokémon was both friendly and beautiful, it would always take the beauty evolution.

This complicates the item removal, so for the sake of having it work properly, it was changed so that the first LTE a Pokémon qualifies for is always taken instead. So, in our above example, the friendly and beautiful Pokémon would now always take the friendship evolution.

The only Pokémon capable of qualifying for multiple LTEs simultaneously is Eevee (arguably also Cubone), so keep this change in mind when setting Eevee's evolution slots.
