local kilia_avatar_set = false;

function kilia_avatar()
	local avatar_alliance = bm:local_alliance();
	local kilia_table = {};
	local sunits_atk_table = {};
	local sunits_def_table = {};
	local alliances = bm:alliances();
	for i = 1, alliances:count() do
		local alliance = alliances:item(i);
		local armies = alliance:armies();
		for j = 1, armies:count() do
			local army = armies:item(j);
			local units = army:units();
			for k = 1, units:count() do
				local unit = units:item(k);
				local sunit = script_unit:new(unit);
				if i == 1 then
					table.insert(sunits_atk_table, sunit);
					if table.contains(unit:owned_special_abilities(), "kilia_ability_avatar") then
						unit:heal_hitpoints_unary(1);
						unit:disable_passive_special_abilities(false);
						unit:disable_non_passive_special_abilities(false);
						unit:disable_special_ability("kilia_ability_avatar", false);
						table.insert(kilia_table, sunit);
					end
				elseif i == 2 then
					table.insert(sunits_def_table, sunit);
					if table.contains(unit:owned_special_abilities(), "kilia_ability_avatar") then
						unit:heal_hitpoints_unary(1);
						unit:disable_passive_special_abilities(false);
						unit:disable_non_passive_special_abilities(false);
						unit:disable_special_ability("kilia_ability_avatar", false);
						table.insert(kilia_table, sunit);
					end
				end
			end
		end
	end
	local sunits_kilia = script_units:new("sunits_kilia", kilia_table);
	local sunits_atk = script_units:new("sunits_atk", sunits_atk_table);
	local sunits_def = script_units:new("sunits_def", sunits_def_table);
	sunits_kilia:invincible_if_standing(true);
	if kilia_avatar_set == true then
		if avatar_alliance == 1 then
			sunits_def:set_invincible(false);
			sunits_def:kill();
		elseif avatar_alliance == 2 then
			sunits_atk:set_invincible(false);
			sunits_atk:kill();
		end
	end
end;

bm:repeat_callback(kilia_avatar, 1000, "kilia_avatar_callback");

bm:register_command_handler_callback(
	"Special Ability",
	function(event)
		local event_ability = event:get_string1();
		if event_ability == "kilia_ability_avatar" then
			kilia_avatar_set = true;
			kilia_avatar();
			bm:remove_process("kilia_avatar_callback");
			bm:repeat_callback(kilia_avatar, 100, "kilia_avatar_callback");
		end
	end
);
