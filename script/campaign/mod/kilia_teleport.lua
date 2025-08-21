-- kilia_teleport.lua
-- PJ_SS (Change Starting Settlement) をベースに Kilia のみを対象にした統合版
-- 保存先: script/campaign/mod/kilia_teleport.lua

PJ_SS = PJ_SS or {}
local mod = PJ_SS

-- 保存用（PJ_SS 元コードの変数）
local original_settlement_buildings = nil
local original_settlement_level = nil

-- 内部状態
mod.are_buttons_always_visible = true
mod.is_in_select_start = false
mod.kilia_check_interval = 1.0 -- 秒単位の定期チェック
mod.kilia_present = false

-- -----------------------
-- ヘルパー: UI コンポーネント検索
-- -----------------------
local function digForComponent(startingComponent, componentName, max_depth)
	local function digForComponent_iter(startingComponent, componentName, max_depth, current_depth)
		if not startingComponent or startingComponent:IsValid() == false then
			return nil
		end
		
		local childCount = startingComponent:ChildCount()
		for i = 0, childCount - 1 do
			local child = UIComponent(startingComponent:Find(i))
			if child and child:Id() == componentName then
				return child
			else
				if not max_depth or current_depth + 1 <= max_depth then
					local dugComponent = digForComponent_iter(child, componentName, max_depth, current_depth + 1)
					if dugComponent then
						return dugComponent
					end
				end
			end
		end
		return nil
	end

	return digForComponent_iter(startingComponent, componentName, max_depth, 1)
end

local function binding_iter(binding)
	if not binding then return function() return nil end end
	local pos = 0
	local num_items = binding:num_items()
	return function()
		if pos < num_items then
			local item = binding:item_at(pos)
			pos = pos + 1
			return item
		end
		return nil
	end
end

-- -----------------------
-- Kilia 関連ユーティリティ
-- -----------------------
-- ローカル勢力内で subtype == "kilia" のキャラクターを返す
local function find_local_kilia_character()
	if not cm then return nil end
	
	local local_faction_name = cm:get_local_faction_name(true)
	if not local_faction_name or local_faction_name == "" then return nil end
	
	local faction = cm:get_faction(local_faction_name)
	if not faction or faction:is_null_interface() then return nil end

	local chars = faction:character_list()
	if not chars then return nil end
	
	for i = 0, chars:num_items() - 1 do
		local char = chars:item_at(i)
		-- 安全にチェック
		if char and not char:is_null_interface() then
			-- subtype_key を使用した比較（より安全）
			local st = char:character_subtype_key()
			if st then
				-- 完全一致または部分一致でkilia を検索
				if st == "kilia" or string.find(string.lower(st), "kilia") then
					return char
				end
			end
		end
	end

	return nil
end

-- Kilia が存在していて生きているかをチェックする (mobile/general 判定)
local function is_kilia_present_and_valid()
	local kilia = find_local_kilia_character()
	if not kilia or kilia:is_null_interface() then
		return false
	end
	-- ここでは「勢力に存在し、削除されていない」ことを満たせば有効とする
	return true
end

-- -----------------------
-- PJ_SS.add_building_to_region 関数（先に定義）
-- -----------------------
PJ_SS.add_building_to_region = function(region)
	if not region or region:is_null_interface() then return end
	if not original_settlement_buildings then return end

	for building_key, _ in pairs(original_settlement_buildings) do
		local settlement = region:settlement()
		if not settlement or settlement:is_null_interface() then return end
		
		local empty_slot = settlement:first_empty_active_secondary_slot()
		if not empty_slot then return end

		if not region:building_exists(building_key) then
			pcall(function()
				cm:region_slot_instantly_upgrade_building(empty_slot, building_key)
				cm:callback(
					function()
						pcall(function()
							cm:region_slot_instantly_repair_building(empty_slot)
						end)
					end,
					0
				)
			end)
		end

		original_settlement_buildings[building_key] = nil
		cm:callback(
			function()
				PJ_SS.add_building_to_region(region)
			end,
			0
		)
		return
	end
end

-- -----------------------
-- 選択状態管理 (PJ_SS と同様)
-- -----------------------
PJ_SS.enter_select_state = function()
	PJ_SS.is_in_select_start = true
	-- オリジナル同様にシャドウを操作
	pcall(function()
		cm:take_shroud_snapshot()
		cm:show_shroud(false)
	end)
end

PJ_SS.exit_select_state = function()
	PJ_SS.is_in_select_start = false
end

-- -----------------------
-- 主要: Kilia 部隊だけを転送する関数
-- -----------------------
PJ_SS.teleport_kilia_army_to_region = function(faction_name, region_name)
	if not faction_name or not region_name then return end
	local faction = cm:get_faction(faction_name)
	if not faction or faction:is_null_interface() then return end
	local region = cm:get_region(region_name)
	if not region or region:is_null_interface() then return end

	-- Kilia を探す（対象はローカル勢力の Kilia の想定）
	local kilia = find_local_kilia_character()
	if not kilia then
		-- 予備: その勢力内の Kilia を探す
		local chars = faction:character_list()
		for i = 0, chars:num_items() - 1 do
			local c = chars:item_at(i)
			if c and not c:is_null_interface() and c:character_subtype("kilia") then
				kilia = c
				break
			end
		end
	end

	if not kilia then
		-- 見つからなければ何もしない
		return
	end

	-- もし軍隊を持っていれば、その軍隊（general with army）をテレポート
	if cm:char_is_mobile_general_with_army(kilia) then
		local cqi = kilia:cqi()
		-- 有効なスポーン位置を得る
		local pos_x, pos_y = cm:find_valid_spawn_location_for_character_from_settlement(faction_name, region_name, false, true, 1)
		if pos_x and pos_y and pos_x >= 0 and pos_y >= 0 then
			-- 少し遅延して順番待ち（オリジナルと同様に）
			cm:callback(function()
				pcall(function()
					cm:teleport_to(cm:char_lookup_str(cqi), pos_x, pos_y, true)
				end)
			end, 0.1)
		end
	else
		-- 軍隊を持っていない (エージェント等) の場合、個別にテレポート
		local cqi = kilia:cqi()
		local pos_x, pos_y = cm:find_valid_spawn_location_for_character_from_settlement(faction_name, region_name, false, true, 1)
		if pos_x and pos_y and pos_x >= 0 and pos_y >= 0 then
			cm:callback(function()
				pcall(function()
					cm:teleport_to(cm:char_lookup_str(cqi), pos_x, pos_y, true)
				end)
			end, 0.1)
		end
	end
end

-- -----------------------
-- on_settlement_chosen を Kilia 用に差し替え
-- -----------------------
PJ_SS.on_settlement_chosen = function(faction_name, region_name)
	local region = cm:get_region(region_name)
	if not region or region:is_null_interface() then return end
	local garrison = region:garrison_residence()
	local previous_faction_owner = region:owning_faction()

	-- ガリソンの将軍を削除（オリジナル準拠）
	if garrison and garrison:has_army() then
		local army = garrison:army()
		if army and not army:is_null_interface() then
			local general = army:general_character()
			if general and not general:is_null_interface() then
				cm:kill_character(general:cqi(), true, true)
			end
		end
	end

	-- Kilia のみを転送
	PJ_SS.teleport_kilia_army_to_region(faction_name, region_name)

	-- 地域移譲処理
	local faction = cm:get_faction(faction_name)
	if faction and not faction:is_null_interface() and faction:subculture() ~= "wh_dlc03_sc_bst_beastmen" then
		cm:transfer_region_to_faction(region_name, faction_name)
		cm:heal_garrison(region:cqi())
		
		-- settlement level / building restore
		cm:callback(function()
			local region2 = cm:get_region(region_name)
			if region2 and not region2:is_null_interface() and region2:owning_faction() and region2:owning_faction():name() == faction_name then
				if original_settlement_level and not mod.skip_settlement_level then
					cm:instantly_set_settlement_primary_slot_level(region2:settlement(), original_settlement_level)
				end
				if original_settlement_buildings and not mod.skip_buildings then
					cm:callback(function()
						-- 関数が存在することを確認してから呼び出し
						if PJ_SS.add_building_to_region then
							PJ_SS.add_building_to_region(region2)
						end
					end, 0)
				end
			end
		end, 0)
	end

	-- 旧勢力の扱い
	local former_regions = {}
	if faction and not faction:is_null_interface() then
		local regions = faction:region_list()
		for i = 0, regions:num_items() - 1 do
			local key = regions:item_at(i):name()
			if key ~= "wh_main_yn_edri_eternos_the_oak_of_ages" then
				table.insert(former_regions, key)
			end
		end
	end

	if mod.switch_places_enabled and previous_faction_owner and not previous_faction_owner:is_null_interface() then
		for _, former_region_name in ipairs(former_regions) do
			cm:transfer_region_to_faction(former_region_name, previous_faction_owner:name())
			local former_region = cm:get_region(former_region_name)
			if former_region then
				cm:heal_garrison(former_region:cqi())
			end
		end
	elseif not mod.do_no_abandon then
		cm:callback(function()
			for _, former_region_name in ipairs(former_regions) do
				if former_region_name ~= "wh3_main_combi_region_the_oak_of_ages" then
					cm:set_region_abandoned(former_region_name)
				end
			end
		end, 0.5)
	end

	-- カメラ移動
	local settlement = region:settlement()
	if settlement and not settlement:is_null_interface() then
		local settlement_display_position_x = settlement:display_position_x()
		local settlement_display_position_y = settlement:display_position_y()
		cm:callback(function()
			cm:scroll_camera_from_current(true, 0.1, {settlement_display_position_x, settlement_display_position_y, 10, d_to_r(0), 10})
			CampaignUI.ClearSelection()
		end, 1)
	end
end

-- -----------------------
-- リスナー設定
-- -----------------------
core:remove_listener("pj_selectable_start_SettlementSelected_Listener_for_kilia")
core:add_listener(
	"pj_selectable_start_SettlementSelected_Listener_for_kilia",
	"SettlementSelected",
	function(context)
		if not PJ_SS.is_in_select_start then return false end
		local garrison = context:garrison_residence()
		if not garrison or garrison:is_null_interface() then return false end
		local settlement = garrison:settlement_interface()
		if not settlement or settlement:is_null_interface() then return false end
		local settlement_faction = settlement:faction()
		if not settlement_faction or settlement_faction:is_null_interface() then return false end
		return settlement_faction:name() ~= cm:get_local_faction_name(true)
	end,
	function(context)
		pcall(function() cm:show_shroud(true) end)
		pcall(function() cm:restore_shroud_from_snapshot() end)
		PJ_SS.exit_select_state()

		local garrison = context:garrison_residence()
		local settlement = garrison:settlement_interface()
		local region_name = settlement:region():name()

		CampaignUI.TriggerCampaignScriptEvent(cm:get_faction(cm:get_local_faction_name(true)):command_queue_index(), "pj_selectable_start_chosen|" .. cm:get_local_faction_name(true) .. "|" .. region_name)
	end,
	true
)

core:remove_listener("pj_selectable_start_settlement_chosen_listener_for_kilia")
core:add_listener(
	"pj_selectable_start_settlement_chosen_listener_for_kilia",
	"UITrigger",
	function(context)
		return context:trigger():starts_with("pj_selectable_start_chosen")
	end,
	function(context)
		local hash_without_prefix = context:trigger():gsub("pj_selectable_start_chosen|", "")

		local args = {}
		hash_without_prefix:gsub("([^|]+)", function(w)
			if (type(w) == "string") then
				table.insert(args, w)
			end
		end)

		local faction_name, region_name = args[1], args[2]
		if not faction_name or not region_name then return end

		-- original_settlement_level/buildings を保持
		local faction = cm:get_faction(faction_name)
		if faction and not faction:is_null_interface() and faction:has_home_region() then
			local home_region = faction:home_region()
			if home_region and not home_region:is_null_interface() then
				local settlement = home_region:settlement()
				if settlement and not settlement:is_null_interface() then
					if original_settlement_level == nil then
						local primary_slot = settlement:primary_slot()
						if primary_slot and primary_slot:has_building() then
							original_settlement_level = primary_slot:building():building_level()
						end
					end
					if original_settlement_buildings == nil then
						original_settlement_buildings = {}
						for slot in binding_iter(settlement:active_secondary_slots()) do
							if slot and slot:has_building() then
								local building = slot:building()
								if building and not building:is_null_interface() then
									original_settlement_buildings[building:name()] = true
								end
							end
						end
					end
				end
			end
		end

		PJ_SS.on_settlement_chosen(faction_name, region_name)
	end,
	true
)

-- -----------------------
-- ボタン関連
-- -----------------------
core:remove_listener("pj_selectable_start_on_main_button_clicked_for_kilia")
core:add_listener(
	"pj_selectable_start_on_main_button_clicked_for_kilia",
	"ComponentLClickUp",
	function(context)
		return context.string == "pj_selectable_start_button"
	end,
	function()
		CampaignUI.ClearSelection()
		PJ_SS.enter_select_state()
		if PJ_SS.dow_main_ui_button then
			PJ_SS.dow_main_ui_button:SetVisible(false)
		end
	end,
	true
)

PJ_SS.create_main_button = function()
	local ui_root = core:get_ui_root()
	if not ui_root then return end

	local dow_main_ui_button = digForComponent(ui_root, "pj_selectable_start_button")
	if not dow_main_ui_button then
		pcall(function()
			ui_root:CreateComponent("pj_selectable_start_button", "ui/templates/round_medium_button")
		end)
		dow_main_ui_button = digForComponent(ui_root, "pj_selectable_start_button")
		PJ_SS.dow_main_ui_button = dow_main_ui_button
	end

	if dow_main_ui_button then
		pcall(function()
			dow_main_ui_button:SetImagePath("ui/skins/default/icon_replace.png")
			dow_main_ui_button:SetVisible(true)
			dow_main_ui_button:Resize(42, 42)
			dow_main_ui_button:MoveTo(16, 50)
			dow_main_ui_button:SetTooltipText("Change Settlement (Kilia target)", true)
		end)
	end

	if not cm:is_new_game() and not mod.are_buttons_always_visible then
		if dow_main_ui_button then 
			dow_main_ui_button:SetVisible(false) 
		end
	end
end

PJ_SS.create_random_button = function()
	local ui_root = core:get_ui_root()
	if not ui_root then return end

	local random_button = digForComponent(ui_root, "pj_selectable_start_random_button")
	if not random_button then
		pcall(function()
			ui_root:CreateComponent("pj_selectable_start_random_button", "ui/templates/round_medium_button")
		end)
		random_button = digForComponent(ui_root, "pj_selectable_start_random_button")
		PJ_SS.random_button = random_button
	end

	if random_button then
		pcall(function()
			random_button:SetImagePath("ui/skins/default/icon_wh_main_lore_light.png")
			random_button:SetVisible(true)
			random_button:Resize(42, 42)
			random_button:MoveTo(16 + 50, 50)
			random_button:SetTooltipText("Change To Random Settlement (Kilia)", true)
		end)
	end

	if not cm:is_new_game() and not mod.are_buttons_always_visible then
		if random_button then 
			random_button:SetVisible(false) 
		end
	end
end

PJ_SS.get_random_region_name = function()
	local region_list = cm:model():world():region_manager():region_list()
	local num_regions = region_list:num_items()
	local random_region_index = math.random(num_regions) - 1
	local region = region_list:item_at(random_region_index)

	if region and not region:is_null_interface() and region:owning_faction() and region:owning_faction():is_human() then
		return PJ_SS.get_random_region_name()
	end

	return region and region:name() or nil
end

core:remove_listener('pj_selectable_start_on_random_button_clicked_for_kilia')
core:add_listener(
	'pj_selectable_start_on_random_button_clicked_for_kilia',
	'ComponentLClickUp',
	function(context)
		return context.string == "pj_selectable_start_random_button"
	end,
	function()
		if PJ_SS.random_button then 
			PJ_SS.random_button:SetVisible(false) 
		end
		cm:callback(function()
			if PJ_SS.random_button then 
				PJ_SS.random_button:SetVisible(true) 
			end
		end, 2)

		local region_name = PJ_SS.get_random_region_name()
		if region_name then
			CampaignUI.TriggerCampaignScriptEvent(cm:get_faction(cm:get_local_faction_name(true)):command_queue_index(), "pj_selectable_start_chosen|" .. cm:get_local_faction_name(true) .. "|" .. region_name)
		end
	end,
	true
)

-- -----------------------
-- FactionTurnStart リスナー
-- -----------------------
core:remove_listener("pj_selectable_start_FactionTurnStart_Listener_for_kilia")
core:add_listener(
	"pj_selectable_start_FactionTurnStart_Listener_for_kilia",
	"FactionTurnStart",
	function(context)
		local faction = context:faction()
		return faction and faction:is_human()
	end,
	function()
		if PJ_SS.dow_main_ui_button then
			if cm:model():turn_number() > 1 and not mod.are_buttons_always_visible then
				PJ_SS.dow_main_ui_button:SetVisible(false)
				if PJ_SS.random_button then 
					PJ_SS.random_button:SetVisible(false) 
				end
			else
				local present = is_kilia_present_and_valid()
				local is_local_turn = cm:is_local_players_turn(true)
				
				PJ_SS.dow_main_ui_button:SetDisabled(not is_local_turn or not present)
				PJ_SS.dow_main_ui_button:SetVisible(present and (mod.are_buttons_always_visible or cm:model():turn_number() == 1))
				
				if PJ_SS.random_button then
					PJ_SS.random_button:SetDisabled(not is_local_turn or not present)
					PJ_SS.random_button:SetVisible(present and (mod.are_buttons_always_visible or cm:model():turn_number() == 1))
				end
			end
		end
	end,
	true
)

-- -----------------------
-- 周期チェック関数
-- -----------------------
local function periodic_kilia_check()
	local present = is_kilia_present_and_valid()
	if present ~= mod.kilia_present then
		mod.kilia_present = present
		if mod.kilia_present then
			if PJ_SS.dow_main_ui_button then
				PJ_SS.dow_main_ui_button:SetVisible(true)
				PJ_SS.dow_main_ui_button:SetDisabled(not cm:is_local_players_turn(true))
			end
			if PJ_SS.random_button then
				PJ_SS.random_button:SetVisible(true)
				PJ_SS.random_button:SetDisabled(not cm:is_local_players_turn(true))
			end
		else
			if PJ_SS.dow_main_ui_button then 
				PJ_SS.dow_main_ui_button:SetVisible(false) 
			end
			if PJ_SS.random_button then 
				PJ_SS.random_button:SetVisible(false) 
			end
		end
	end

	-- 次回チェック
	cm:callback(periodic_kilia_check, mod.kilia_check_interval)
end

-- -----------------------
-- 初期化
-- -----------------------
cm:add_first_tick_callback(function()
	-- 少し遅延してUI作成を実行
	cm:callback(function()
		pcall(function()
			PJ_SS.create_main_button()
			PJ_SS.create_random_button()

			mod.kilia_present = is_kilia_present_and_valid()
			if not mod.kilia_present then
				if PJ_SS.dow_main_ui_button then 
					PJ_SS.dow_main_ui_button:SetVisible(false) 
				end
				if PJ_SS.random_button then 
					PJ_SS.random_button:SetVisible(false) 
				end
			end

			-- 周期チェック開始
			cm:callback(periodic_kilia_check, mod.kilia_check_interval)
		end)
	end, 0.5)
end)

-- MCT 設定ハンドラの修正（最小構成版）
mod.update_settings = function(mct)
    if not mct then return end
    local my_mod = mct:get_mod_by_key("kilia_teleport")
    if not my_mod then return end

    -- 安全な設定取得関数
    local function get_option_safe(key, default_value)
        local option = my_mod:get_option_by_key(key)
        if option then
            return option:get_finalized_setting()
        end
        return default_value or false
    end

    mod.are_buttons_always_visible = get_option_safe("kilia_teleport_is_always_visible", true)
    mod.is_whole_province_takeover_enabled = get_option_safe("kilia_teleport_is_whole_province_takeover_enabled")
    mod.do_no_abandon = get_option_safe("kilia_teleport_do_not_abandon")
    mod.skip_settlement_level = get_option_safe("kilia_teleport_skip_settlement_level")
    mod.skip_buildings = get_option_safe("kilia_teleport_skip_buildings")
    mod.switch_places_enabled = get_option_safe("kilia_teleport_switch_places")
    mod.only_with_army = get_option_safe("kilia_teleport_only_with_army")
    
    -- 間隔設定は固定値を使用（MCT設定なし）
    mod.kilia_check_interval = 1.0
end

core:remove_listener("pj_selectable_start_mct_init_cb_for_kilia")
core:add_listener(
	"pj_selectable_start_mct_init_cb_for_kilia",
	"MctInitialized",
	true,
	function(context)
		local mct = context:mct()
		mod.update_settings(mct)
	end,
	true
)

core:remove_listener("pj_selectable_start_mct_finalized_cb_for_kilia")
core:add_listener(
	"pj_selectable_start_mct_finalized_cb_for_kilia",
	"MctFinalized",
	true,
	function(context)
		local mct = context:mct()
		mod.update_settings(mct)
		cm:callback(function()
			PJ_SS.create_main_button()
			PJ_SS.create_random_button()
		end, 0.2)
	end,
	true
)

-- End of kilia_teleport.lua