function campaign_kilia()
	-- 最もシンプルな解決策：プレイヤー派閥のみに初期生成
	if cm:get_saved_value("kilia_spawn") == nil then
		local faction_list = cm:get_human_factions();
		for i = 1, #faction_list do
			local faction_obj = cm:get_faction(faction_list[i]);
			if faction_obj:is_human() then
				local faction = faction_list[i];
				cm:spawn_character_to_pool(
					faction,
					"Kilia",
					"",
					"",
					"",
					18,
					true,
					"general",
					"kilia",
					true,
					""
				);
			end
		end
		cm:set_saved_value("kilia_spawn", true);
	end

	-- CharacterCreatedリスナー：AI派閥での生成を完全阻止
	core:add_listener(
		"prevent_ai_kilia",
		"CharacterCreated",
		function(context)
			local char = context:character();
			return char:character_subtype("kilia") or char:character_subtype("kilia_dragon");
		end,
		function(context)
			local character = context:character();
			local faction = character:faction();
			
			-- プレイヤー派閥以外では即削除
			if not faction:is_human() then
				cm:callback(function()
					if not character:is_null_interface() then
						cm:kill_character(cm:char_lookup_str(character), true, true);
					end
				end, 0.1);
				return;
			end
			
			-- プレイヤー派閥の場合は正規処理
			if character:character_subtype("kilia") then
				-- 名前を強制変更
				cm:change_character_custom_name(character, "Kilia");
				
				-- 既存のトレイト追加処理
				cm:set_character_unique(cm:char_lookup_str(character), true);
				for i = 1, 50 do
					cm:force_add_trait(cm:char_lookup_str(character), "kilia_dummy_trait_" .. string.format("%02d", i));
				end
				cm:stop_character_convalescing(character:command_queue_index());
			end
		end,
		true
	);
	
	-- 雇用時の最終チェック（二重保険）
	core:add_listener(
		"kilia_recruitment_final_check",
		"CharacterRecruited",
		function(context)
			local char = context:character();
			return char:character_subtype("kilia") or char:character_subtype("kilia_dragon");
		end,
		function(context)
			local character = context:character();
			local faction = character:faction();
			
			-- AI派閥が何らかの方法でkiliaを雇用した場合、即削除
			if not faction:is_human() then
				cm:callback(function()
					if not character:is_null_interface() then
						cm:kill_character(cm:char_lookup_str(character), true, true);
					end
				end, 0.1);
			end
		end,
		true
	);

	-- 既存のその他のリスナー（省略なし）
	core:add_listener(
		"kilia_replenish",
		"CharacterSelected",
		function(context)
			return context:character():character_subtype("kilia");
		end,
		function(context)
			local character = context:character();
			cm:replenish_action_points(cm:char_lookup_str(character));
			cm:set_unit_hp_to_unary_of_maximum(character:military_force():unit_list():item_at(0), 1);
		end,
		true
	);
	
	core:add_listener(
		"kilia_autoresolve",
		"PendingBattle",
		function(context)
			local attacker_subtype = context:pending_battle():attacker():character_subtype_key();
			local secondary_attackers = context:pending_battle():secondary_attackers();
			local defender_subtype = context:pending_battle():defender():character_subtype_key();
			local secondary_defenders = context:pending_battle():secondary_defenders();
			if attacker_subtype == "kilia" then
				return true;
			end
			for i = 0, secondary_attackers:num_items() - 1 do
				local sec_attacker_subtype = secondary_attackers:item_at(i):character_subtype_key();
				if sec_attacker_subtype == "kilia" then
					return true;
				end
			end
			if defender_subtype == "kilia" then
				return true;
			end
			for i = 0, secondary_defenders:num_items() - 1 do
				local sec_defender_subtype = secondary_defenders:item_at(i):character_subtype_key();
				if sec_defender_subtype == "kilia" then
					return true;
				end
			end
			return false;
		end,
		function(context)
			local attacker_subtype = context:pending_battle():attacker():character_subtype_key();
			local secondary_attackers = context:pending_battle():secondary_attackers();
			local defender_subtype = context:pending_battle():defender():character_subtype_key();
			local secondary_defenders = context:pending_battle():secondary_defenders();
			if attacker_subtype == "kilia" then
				cm:set_unit_hp_to_unary_of_maximum(context:pending_battle():attacker():military_force():unit_list():item_at(0), 1);
				cm:win_next_autoresolve_battle(context:pending_battle():attacker():faction():name());
				cm:modify_next_autoresolve_battle(1, 0, 0, 1000000, true);
				cm:override_attacker_win_chance_prediction(100);
				return;
			end
			for i = 0, secondary_attackers:num_items() - 1 do
				local sec_attacker_subtype = secondary_attackers:item_at(i):character_subtype_key();
				if sec_attacker_subtype == "kilia" then
					cm:set_unit_hp_to_unary_of_maximum(secondary_attackers:item_at(i):military_force():unit_list():item_at(0), 1);
					cm:win_next_autoresolve_battle(context:pending_battle():attacker():faction():name());
					cm:modify_next_autoresolve_battle(1, 0, 0, 1000000, true);
					cm:override_attacker_win_chance_prediction(100);
					return;
				end
			end
			if defender_subtype == "kilia" then
				cm:set_unit_hp_to_unary_of_maximum(context:pending_battle():defender():military_force():unit_list():item_at(0), 1);
				cm:win_next_autoresolve_battle(context:pending_battle():defender():faction():name());
				cm:modify_next_autoresolve_battle(0, 1, 1000000, 0, true);
				cm:override_attacker_win_chance_prediction(0);
				return;
			end
			for i = 0, secondary_defenders:num_items() - 1 do
				local sec_defender_subtype = secondary_defenders:item_at(i):character_subtype_key();
				if sec_defender_subtype == "kilia" then
					cm:set_unit_hp_to_unary_of_maximum(secondary_defenders:item_at(i):military_force():unit_list():item_at(0), 1);
					cm:win_next_autoresolve_battle(context:pending_battle():defender():faction():name());
					cm:modify_next_autoresolve_battle(0, 1, 1000000, 0, true);
					cm:override_attacker_win_chance_prediction(0);
					return;
				end
			end
		end,
		true
	);
	
	core:add_listener(
		"kilia_selected",
		"CharacterSelected",
		function(context)
			return true;
		end,
		function(context)
			-- UIコンポーネントの安全チェックを追加
			if not context:character() then
				return;
			end
			
			local parent_button = find_uicomponent(
				core:get_ui_root(),
				"hud_campaign",
				"hud_center_docker",
				"hud_center",
				"small_bar",
				"button_subpanel_parent",
				"button_subpanel",
				"button_group_army"
			);
			
			if context:character():character_subtype("kilia") then
				if is_uicomponent(parent_button) then
					local existing_button = find_uicomponent(parent_button, "kilia_button");
					local kilia_button;
					if existing_button then
						kilia_button = existing_button;
					else
						kilia_button = UIComponent(parent_button:CreateComponent("kilia_button", "ui/templates/square_medium_button"));
						kilia_button:SetImagePath("ui/skins/default/icon_cross_square.png", 0, true);
					end
					kilia_button:SetState("active");
					kilia_button:SetTooltipText(common.get_localised_string("kilia_button_title"), true);
					local kilia_faction = context:character():faction();
					core:remove_listener("kilia_clicked");
					core:add_listener(
						"kilia_clicked",
						"ComponentLClickUp",
						function(context)
							return context.string == "kilia_button";
						end,
						function(context)
							core:add_listener(
								"kilia_destroy",
								"CharacterSelected",
								true,
								function(context)
									if not context:character() then
										return;
									end
									local faction = context:character():faction();
									if faction ~= kilia_faction then
										local region_list = faction:region_list();
										cm:kill_all_armies_for_faction(faction);
										if region_list:num_items() > 0 then
											for i = 0, region_list:num_items() - 1 do
												cm:set_region_abandoned(region_list:item_at(i):name());
											end
										end
									end
									cm:restore_shroud_from_snapshot();
									cm:release_escape_key_with_callback("kilia_destroy_cancel");
									core:remove_listener("kilia_destroy");
								end,
								true
							);
							core:add_listener(
								"kilia_destroy",
								"SettlementSelected",
								true,
								function(context)
									local faction = context:garrison_residence():faction();
									if faction ~= kilia_faction then
										CampaignUI.ClearSelection();
										local region_list = faction:region_list();
										cm:kill_all_armies_for_faction(faction);
										if region_list:is_empty() == false then
											for i = 0, region_list:num_items() - 1 do
												cm:set_region_abandoned(region_list:item_at(i):name());
											end
										end
									end
									cm:restore_shroud_from_snapshot();
									cm:release_escape_key_with_callback("kilia_destroy_cancel");
									core:remove_listener("kilia_destroy");
								end,
								true
							);
							core:add_listener(
								"kilia_destroy",
								"PanelOpenedCampaign",
								true,
								function(context)
									if context.string ~= "events" then
										cm:restore_shroud_from_snapshot();
										cm:release_escape_key_with_callback("kilia_destroy_cancel");
										core:remove_listener("kilia_destroy");
									end;
								end,
								true
							);
							core:add_listener(
								"kilia_destroy",
								"FactionTurnEnd",
								true,
								function(context)
									cm:restore_shroud_from_snapshot();
									cm:release_escape_key_with_callback("kilia_destroy_cancel");
									core:remove_listener("kilia_destroy");
								end,
								true
							);
							CampaignUI.ClearSelection();
							cm:take_shroud_snapshot();
							cm:show_shroud(false);
							cm:steal_escape_key_with_callback(
								"kilia_destroy_cancel",
								function()
									cm:restore_shroud_from_snapshot();
									cm:release_escape_key_with_callback("kilia_destroy_cancel");
								end
							);
						end,
						false
					);
				end
			else
				if is_uicomponent(parent_button) then
					local kilia_button = find_uicomponent(parent_button, "kilia_button");
					if kilia_button then
						kilia_button:Destroy();
					end
				end
			end
		end,
		true
	);
end