--- Mystic Capitalist Deck
--- Duplicate any joker or consumable for a rarity-based price.
--- Each duplication destroys one other random card.

SMODS.Back{
    key = "mystic_capitalist",
    atlas = "back",
    pos = { x = 0, y = 0 },
    config = {},
    loc_txt = {
        name = "Mystic Capitalist Deck",
        text = {
            "{C:attention}Duplicate{} any Joker or Consumable",
            "for a price based on {C:attention}rarity{}.",
            "{s:0.8,C:inactive}($10/$20/$30/$50 for C/UC/R/L){}",
            "Each duplication {C:red}destroys{} one",
            "other random Joker or Consumable."
        }
    },
    apply = function(self, back)
        G.GAME.mystic_capitalist = true
    end
}

--- Price Table ---

local DUPE_PRICES = {
    [1] = 10,  -- Common
    [2] = 20,  -- Uncommon
    [3] = 30,  -- Rare
    [4] = 50,  -- Legendary
}

local function get_dupe_price(card)
    local rarity = card.config and card.config.center and card.config.center.rarity
    return DUPE_PRICES[rarity] or 20
end

local function get_all_inventory_cards()
    local cards = {}
    if G.jokers and G.jokers.cards then
        for _, c in ipairs(G.jokers.cards) do
            cards[#cards + 1] = c
        end
    end
    if G.consumeables and G.consumeables.cards then
        for _, c in ipairs(G.consumeables.cards) do
            cards[#cards + 1] = c
        end
    end
    return cards
end

local function can_duplicate(card)
    if not G.GAME or not G.GAME.mystic_capitalist then return false end
    if not card or not card.area then return false end

    local is_joker = card.area == G.jokers
    local is_consumable = card.area == G.consumeables
    if not is_joker and not is_consumable then return false end

    local price = get_dupe_price(card)
    if (G.GAME.dollars or 0) < price then return false end

    local all_cards = get_all_inventory_cards()
    if #all_cards < 2 then return false end

    if is_joker and #G.jokers.cards >= (G.jokers.config.card_limit or 5) then return false end
    if is_consumable and #G.consumeables.cards >= (G.consumeables.config.card_limit or 2) then return false end

    return true
end

--- G.FUNCS ---

local BAZR_PURPLE = HEX("8a2be2")

G.FUNCS.bazr_can_duplicate_card = function(e)
    local card = e.config.ref_table
    if can_duplicate(card) then
        e.config.colour = BAZR_PURPLE
        e.config.button = "bazr_duplicate_card"
    else
        e.config.colour = G.C.UI.BACKGROUND_INACTIVE
        e.config.button = nil
    end
end

G.FUNCS.bazr_duplicate_card = function(e)
    local card = e.config.ref_table
    if not can_duplicate(card) then return end

    local price = get_dupe_price(card)
    local is_joker = card.area == G.jokers

    local candidates = {}
    local all_cards = get_all_inventory_cards()
    for _, c in ipairs(all_cards) do
        if c ~= card then
            candidates[#candidates + 1] = c
        end
    end
    if #candidates == 0 then return end

    local victim = pseudorandom_element(candidates, pseudoseed("bazr_destroy"))

    ease_dollars(-price)

    G.E_MANAGER:add_event(Event({
        trigger = "after",
        delay = 0.15,
        func = function()
            card:juice_up(0.3, 0.5)
            return true
        end
    }))

    G.E_MANAGER:add_event(Event({
        trigger = "after",
        delay = 0.3,
        func = function()
            if victim and victim.start_dissolve then
                victim:start_dissolve(nil, nil, 3)
            end
            return true
        end
    }))

    G.E_MANAGER:add_event(Event({
        trigger = "after",
        delay = 0.5,
        func = function()
            local new_card = copy_card(card, nil)
            if is_joker then
                new_card:add_to_deck()
                G.jokers:emplace(new_card)
            else
                new_card:add_to_deck()
                G.consumeables:emplace(new_card)
            end

            card_eval_status_text(card, "extra", nil, nil, nil, {
                message = "Duplicated!",
                colour = G.C.GREEN
            })
            return true
        end
    }))
end

--- UI: Dupe Button (Card:highlight hook, Ortalab pattern) ---

function G.UIDEF.bazr_dupe_button(card)
    local dupe_price = get_dupe_price(card)
    local is_consumable = card.ability and card.ability.consumeable

    local dupe = {n=G.UIT.C, config={align = "cr"}, nodes={
        {n=G.UIT.C, config={
            ref_table = card,
            align = "cr",
            maxw = 1.25,
            padding = 0.1,
            r = 0.08,
            minw = 1.25,
            minh = (card.area and card.area.config.type == 'joker') and 0 or 1,
            hover = true,
            shadow = true,
            colour = G.C.UI.BACKGROUND_INACTIVE,
            button = "bazr_duplicate_card",
            func = "bazr_can_duplicate_card"
        }, nodes={
            {n=G.UIT.B, config = {w=0.1, h=0.6}},
            {n=G.UIT.T, config={
                text = "Dupe $" .. dupe_price,
                colour = G.C.UI.TEXT_LIGHT,
                scale = 0.45,
                shadow = true
            }}
        }}
    }}

    local sell = {n=G.UIT.C, config={align = "cr"}, nodes={
        {n=G.UIT.C, config={
            ref_table = card,
            align = "cr",
            maxw = 1.25,
            padding = 0.1,
            r = 0.08,
            minw = 1.25,
            minh = (card.area and card.area.config.type == 'joker') and 0 or 1,
            hover = true,
            shadow = true,
            colour = G.C.UI.BACKGROUND_INACTIVE,
            one_press = true,
            button = "sell_card",
            func = "can_sell_card"
        }, nodes={
            {n=G.UIT.B, config = {w=0.1, h=0.6}},
            {n=G.UIT.T, config={
                text = localize('b_sell'),
                colour = G.C.UI.TEXT_LIGHT,
                scale = 0.45,
                shadow = true
            }}
        }}
    }}

    local use = is_consumable and {n=G.UIT.C, config={align = "cr"}, nodes={
        {n=G.UIT.C, config={
            ref_table = card,
            align = "cr",
            maxw = 1.25,
            padding = 0.1,
            r = 0.08,
            minw = 1.25,
            minh = 1,
            hover = true,
            shadow = true,
            colour = G.C.UI.BACKGROUND_INACTIVE,
            one_press = true,
            button = "use_card",
            func = "can_use_consumeable"
        }, nodes={
            {n=G.UIT.B, config = {w=0.1, h=0.6}},
            {n=G.UIT.T, config={
                text = localize('b_use'),
                colour = G.C.UI.TEXT_LIGHT,
                scale = 0.45,
                shadow = true
            }}
        }}
    }} or nil

    local rows = {
        {n=G.UIT.R, config={align = "cl"}, nodes={dupe}},
        {n=G.UIT.R, config={align = "cl"}, nodes={sell}},
    }
    if use then
        table.insert(rows, 2, {n=G.UIT.R, config={align = "cl"}, nodes={use}})
    end

    return {
        n = G.UIT.ROOT,
        config = {padding = 0, colour = G.C.CLEAR},
        nodes = {
            {n=G.UIT.C, config={padding = 0.15, align = "cl"}, nodes=rows},
        }
    }
end

local bazr_card_highlight_ref = Card.highlight
function Card:highlight(is_highlighted)
    bazr_card_highlight_ref(self, is_highlighted)

    if not G.GAME or not G.GAME.mystic_capitalist then return end
    if not self.area then return end
    if self.area ~= G.jokers and self.area ~= G.consumeables then return end

    if is_highlighted then
        if self.children.use_button then
            self.children.use_button:remove()
            self.children.use_button = nil
        end

        local x_off = (self.ability and self.ability.consumeable and -0.1 or 0)
        self.children.use_button = UIBox{
            definition = G.UIDEF.bazr_dupe_button(self),
            config = {
                align = "cr",
                offset = {x = x_off - 0.4, y = 0},
                parent = self
            }
        }
    elseif self.children.use_button then
        self.children.use_button:remove()
        self.children.use_button = nil
    end
end
