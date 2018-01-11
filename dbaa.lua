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

-- A class for y subpixels
-- ############################################################################
local YSubpixelClass = {}

function YSubpixelClass:add (number)
	self.subpixel = (self.subpixel + number) % 256
end

local subpixel_auto = {subpixel = 0, add = SubpixelClass.add}
-- Stores a register for how much the last jump changed Y-subpixel, and returns that register
-- ############################################################################
local function GetYSubpixelChangeValue()
	local player_grounded = 0x205A1
	local y_sx_addr = 0x0205C8
	local pastYsx = {[0] = 0, [1] = 0}
	local pastYsx = memory.read_u8(y_sx_addr)

	pastYsx[1] = pastYsx[0]

	local delta_Y_sx = pastYsx[1] - pastYsx[0]

	if player_grounded ~= 0 then
		subpixel_auto.add(delta_Y_sx)
	end

	return delta_Y_sx
end
	
-- Records how much a subpixel value changed when player character is in the air and returns that value


-- HUD that displays info in a static way on the screen (position, speed..)
-- ############################################################################
local function Display(x, y)
	local x_pos_addr   = 0x0205C4
	local y_pos_addr   = 0x0205C8
	local x_speed_addr = 0x0205CC
	local y_speed_addr = 0x0205CE
	local y_subpixel_change_value_auto = GetYSubpixelChangeValue()

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

	-- Auto delta!
	gui.pixelText(x + gba_w - 80, y + gba_h - 14, string.format("%3d", y_subpixel_change_value_auto), 0xFFFFFFFF, c.t.green)

end

-- Overlay on various objects.
-- ############################################################################
local function Overlay(x, y)
	
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
	
		local enemy_HP = memory.read_s16_le(enemy_obj_addr + enemy_obj_HP_offset, "EWRAM")
		if enemy_HP > 0 then
			local enemy_x = memory.read_u24_le(enemy_obj_addr + enemy_obj_x_pos_offset, "EWRAM")
			local enemy_y = memory.read_u24_le(enemy_obj_addr + enemy_obj_y_pos_offset, "EWRAM")	
			gui.pixelText(enemy_x - camera_x, enemy_y - camera_y, enemy_HP)
		end
	
	end
end
 
-- Main loop.
-- ############################################################################
while true do
	Overlay(0, 0)
	Display(0, 0)
  	emu.frameadvance()
end