--- Balatro Bazaar: A mystical marketplace of decks, jokers, and consumables.

--- Atlases ---

SMODS.Atlas{
    key = "decks",
    path = "mystic_capitalist.png",
    px = 71,
    py = 95
}

--- Load Decks ---

assert(SMODS.load_file("decks/mystic_capitalist.lua"))()

--- Load Jokers ---
-- Future: assert(SMODS.load_file("jokers/example.lua"))()

--- Load Consumables ---
-- Future: assert(SMODS.load_file("consumables/example.lua"))()
