-- Static data.
-- Color tables! 
local c = {
	t = { -- Transparent colors..
		["red"] = 0x88FF00000,
		["orange"] = 0x88F3784A,
		["yellow"] = 0x88FFFF00,
		["green"] = 0x8800FF00
	};
	o = { -- Opaque colors..
		["red"] = 0xFFFF00000,
		["orange"] = 0xFFF3784A,
		["yellow"] = 0xFFFFFF00,
		["green"] = 0xFF00FF00
	}	
}

-- Some constants for readability
local gba_w = 240
local gba_h = 160

-- 	local player_grounded = 0x205A1

-- Displays RNG as well as as an RNG lookup table.
-- (TODO: implement lookup)
-- ############################################################################
local function RNGTable(x, y)
    local RNG_addr = 0x046C50
    gui.pixelText(x, y,  string.format("%04X", memory.read_u16_le(RNG_addr, "Combined WRAM")))
    
end

-- General overlay, displayed at all times.
-- ############################################################################
local function GeneralOverlay(x, y)
	RNGTable(gba_w - 94, gba_h - 7)
end

-- HUD that displays info in a static way on the screen (position, speed..)
-- ############################################################################
local function EnemyDisplay(x, y)
	local x_pos_addr   = 0x0205C4
	local y_pos_addr   = 0x0205C8
	local x_speed_addr = 0x0205CC
	local y_speed_addr = 0x0205CE
	local player_grounded = 0x205A1

	-- Speed display
	gui.pixelText(x + gba_w - 21, y + gba_h - 14, string.format("%5d", memory.read_s16_le(x_speed_addr, "Combined WRAM")))
	gui.pixelText(x + gba_w - 21, y + gba_h - 7, string.format("%5d", memory.read_s16_le(y_speed_addr, "Combined WRAM")))
	
	-- Position (in subpixels)
	gui.pixelText(x + gba_w - 57, y + gba_h - 14, string.format("%8d", memory.read_s32_le(x_pos_addr, "Combined WRAM")))
	gui.pixelText(x + gba_w - 57, y + gba_h - 7, string.format("%8d", memory.read_s32_le(y_pos_addr, "Combined WRAM")))
	
	-- Subpixel position
	local x_pos_sub = memory.read_u8(x_pos_addr, "Combined WRAM")
	local y_pos_sub = memory.read_u8(y_pos_addr, "Combined WRAM")

	if x_pos_sub >= 240 and x_pos_sub ~= 256 then
		gui.pixelText(x + gba_w - 70, y + gba_h - 14, string.format("%3d", x_pos_sub), 0xFFFFFFFF, c.t.green)
	elseif x_pos_sub >= 224 then
		gui.pixelText(x + gba_w - 70, y + gba_h - 14, string.format("%3d", x_pos_sub), 0xFFFFFFFF, c.t.orange)
	else
		gui.pixelText(x + gba_w - 70, y + gba_h - 14, string.format("%3d", x_pos_sub))
	end

	-- This is reversed because Goku gets higher as Y gets lower. So the carry we want to optimise for for Y sub is as low as possible.
	if y_pos_sub <= 16 and x_pos_sub ~= 0 then
		gui.pixelText(x + gba_w - 70, y + gba_h - 7, string.format("%3d", y_pos_sub), 0xFFFFFFFF, c.t.green)	
	elseif y_pos_sub <= 32 then
		gui.pixelText(x + gba_w - 70, y + gba_h - 7, string.format("%3d", y_pos_sub), 0xFFFFFFFF, c.t.orange)
	else
		gui.pixelText(x + gba_w - 70, y + gba_h - 7, string.format("%3d", y_pos_sub))
	end

	-- Ground counter
	if memory.read_u8(player_grounded, "Combined WRAM") == 1 then
		gui.pixelText(x+165, y + gba_h - 7, "G", 0xFFFFFFFF, c.t.yellow)
	else
		gui.pixelText(x+165, y + gba_h - 7, "A", 0xFFFFFFFF, c.t.orange)
	end

end

-- Overlay for platforming mode.
-- ############################################################################
local function PlatformOverlay()    
    EnemyDisplay(0, 0) -- lol no OOP cause lazy
    
	local camera_x_pos_addr      = 0x029EE8
	local camera_y_pos_addr      = 0x029EEC
	local enemy_pointers_addr    = 0x027E00
	local enemy_obj_HP_offset    = 0xB0
	local enemy_obj_x_pos_offset = 0x1D
	local enemy_obj_y_pos_offset = 0x21
	local enemies_limit          = 10

	local camera_x = memory.read_u24_le(camera_x_pos_addr, "EWRAM")
	local camera_y = memory.read_u24_le(camera_y_pos_addr, "EWRAM")
	
	for i = 0, enemies_limit do
	
		local enemy_obj_addr = memory.read_u32_le(0x027E00 + i*4, "EWRAM")
		if enemy_obj_addr == 0 then
			break
		else
			enemy_obj_addr=enemy_obj_addr - 0x02000000
		end
		
		if enemy_obj_addr >= 0x01000000 then
			enemy_obj_addr = enemy_obj_addr - 0x01000000
			local enemy_HP = memory.read_s16_le(enemy_obj_addr + enemy_obj_HP_offset, "IWRAM")
			if enemy_HP > 0 then
				gui.pixelText(223, 11, string.format("%4s", enemy_HP))
			end
		else
			local enemy_HP = memory.read_s16_le(enemy_obj_addr + enemy_obj_HP_offset, "EWRAM")
			if enemy_HP > 0 then
				local enemy_x = memory.read_u24_le(enemy_obj_addr + enemy_obj_x_pos_offset, "EWRAM")
				local enemy_y = memory.read_u24_le(enemy_obj_addr + enemy_obj_y_pos_offset, "EWRAM")	
				local enemy_x = enemy_x - camera_x
				local enemy_y = enemy_y - camera_y
				
				if enemy_x > 231 then
					enemy_x = 231
				end
				if enemy_x < 0 then
					enemy_x = 0
				end
				
				gui.pixelText(enemy_x, enemy_y, string.format("%d", enemy_HP))
			end
		end
    end
end

-- Overlay for platforming mode.
-- ############################################################################
local function VSOverlay(x, y)
	local enemy_HP = memory.read_s16_le(0x029A56, "EWRAM")
	local enemy_shield = memory.read_s16_le(0x029A58, "EWRAM")
	local enemy_shield_regen_timer = bit.rshift(
		memory.read_u16_le(0x029A5A, "EWRAM"), 4)
	
	gui.pixelText(x + gba_w - 16, y + gba_h - 21, string.format("%4d", enemy_HP))
	
	if enemy_shield > 0 then
		gui.pixelText(x + gba_w - 16, y + gba_h - 28, string.format("%4d", enemy_shield), 0xFF000000, c.t.green)
	else
		gui.pixelText(x + gba_w - 16, y + gba_h - 28, string.format("%4d", enemy_shield))
	end
	
	gui.pixelText(x + gba_w - 16, y + gba_h - 35, string.format("%4d", enemy_shield_regen_timer), 0xFFFFFFFF, c.t.orange)
end

-- ############################################################################
while true do
	GeneralOverlay(0, 0)
	if memory.read_s16_le(0x029A56, "EWRAM") ~= 0  then -- Does VS enemy have HP?
		VSOverlay(0, 0)
	else
		PlatformOverlay()
	end
	
	emu.frameadvance()
end
