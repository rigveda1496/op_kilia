-- kilia_teleport_mct.lua
-- Kilia Teleport MOD の MCT 設定ファイル（最小構成版）
-- 保存先: script/mct/settings/kilia_teleport_mct.lua

if not get_mct then return end

local mct = get_mct()
local mct_mod = mct:register_mod("kilia_teleport")

-- MOD基本情報
mct_mod:set_title("Kilia Teleport")
mct_mod:set_author("Your Name")
mct_mod:set_description("Teleport Kilia to any settlement. Only works when Kilia is present in your faction.")

-- ボタン常時表示オプション
local option_always_visible = mct_mod:add_new_option("kilia_teleport_is_always_visible", "checkbox")
option_always_visible:set_default_value(true)
option_always_visible:set_text("Buttons Always Visible")
option_always_visible:set_tooltip_text("Keep the Kilia teleport buttons visible even after turn 1. Buttons will still hide if Kilia is not present.")

-- 州全体取得オプション
local option_province = mct_mod:add_new_option("kilia_teleport_is_whole_province_takeover_enabled", "checkbox")
option_province:set_default_value(false)
option_province:set_text("Take Over Whole Province")
option_province:set_tooltip_text("Receive all the settlements in the province the selected settlement belongs to when teleporting Kilia.")

-- 入植地レベルスキップ
local option_skip_level = mct_mod:add_new_option("kilia_teleport_skip_settlement_level", "checkbox")
option_skip_level:set_default_value(false)
option_skip_level:set_text("Don't Upgrade New Settlement")
option_skip_level:set_tooltip_text("If enabled, your new settlement won't have the same level as the original home settlement.")

-- 建物再現スキップ
local option_skip_buildings = mct_mod:add_new_option("kilia_teleport_skip_buildings", "checkbox")
option_skip_buildings:set_default_value(false)
option_skip_buildings:set_text("Don't Recreate Buildings")
option_skip_buildings:set_tooltip_text("Will try to recreate buildings from the original settlement in your new settlement, if there are empty building slots. Landmarks cannot be recreated.")

-- 放棄しないオプション
local option_no_abandon = mct_mod:add_new_option("kilia_teleport_do_not_abandon", "checkbox")
option_no_abandon:set_default_value(false)
option_no_abandon:set_text("Do Not Abandon Original Settlements")
option_no_abandon:set_tooltip_text("Skip abandoning your original settlements when Kilia teleports.")

-- 場所交換オプション
local option_switch = mct_mod:add_new_option("kilia_teleport_switch_places", "checkbox")
option_switch:set_default_value(false)
option_switch:set_text("Switch Places With Target Owner")
option_switch:set_tooltip_text("The owner of the taken region gets ownership of your old regions when Kilia teleports.")

-- Kilia専用の追加オプション
local option_army_only = mct_mod:add_new_option("kilia_teleport_only_with_army", "checkbox")
option_army_only:set_default_value(false)
option_army_only:set_text("Only Allow When Kilia Has Army")
option_army_only:set_tooltip_text("Only enable teleport buttons when Kilia is a general with an army, not as an agent.")