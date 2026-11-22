import { Mod } from "./keys";

/** A key to tap: Windows virtual-key code plus optional modifier bitmask. */
export type Key = { vk: number; mods?: number };

export interface Mode {
	/** Shown on the dial's touch strip. */
	label: string;
	/** Short hint under the label. */
	hint: string;
	/** Key sent per tick clockwise / counter-clockwise. */
	cw: Key;
	ccw: Key;
	/** Key sent when the dial is pressed (optional). */
	push?: Key;
	/** Fast spins arrive as ticks > 1; presses = round(ticks ^ curve). 1 = linear. */
	curve: number;
	/** Hard cap on keystrokes per rotate event. */
	max: number;
}

// Virtual-key codes (Premiere Pro default Windows shortcuts).
const LEFT = 37, UP = 38, RIGHT = 39, DOWN = 40;
const K = 75, J = 74, L = 76, Z = 90, S = 83;
const EQUALS = 187, MINUS = 189, BACKSLASH = 220;

export const MODES = {
	frame: {
		label: "Frame",
		hint: "Press: Cut",
		cw: { vk: RIGHT },
		ccw: { vk: LEFT },
		push: { vk: K, mods: Mod.Ctrl }, // Add Edit: cut at playhead
		curve: 1.3,
		max: 15
	},
	frame5: {
		label: "Fast Scrub",
		hint: "Press: Cut",
		cw: { vk: RIGHT, mods: Mod.Shift },
		ccw: { vk: LEFT, mods: Mod.Shift },
		push: { vk: K, mods: Mod.Ctrl }, // Add Edit: cut at playhead
		curve: 1.2,
		max: 10
	},
	edit: {
		label: "Edits",
		hint: "Press: Cut all",
		cw: { vk: DOWN },
		ccw: { vk: UP },
		push: { vk: K, mods: Mod.Ctrl | Mod.Shift }, // Add Edit to All Tracks
		curve: 1,
		max: 1
	},
	zoom: {
		label: "Zoom",
		hint: "Press: Fit",
		cw: { vk: EQUALS },
		ccw: { vk: MINUS },
		push: { vk: BACKSLASH }, // Zoom to sequence
		curve: 1,
		max: 3
	},
	shuttle: {
		label: "Shuttle",
		hint: "Press: Stop",
		cw: { vk: L },
		ccw: { vk: J },
		push: { vk: K },
		curve: 1,
		max: 1
	},
	undo: {
		label: "Undo",
		hint: "Press: Save",
		cw: { vk: Z, mods: Mod.Ctrl | Mod.Shift },
		ccw: { vk: Z, mods: Mod.Ctrl },
		push: { vk: S, mods: Mod.Ctrl }, // Save
		curve: 1,
		max: 1
	}
} satisfies Record<string, Mode>;

export type ModeId = keyof typeof MODES;

export const DEFAULT_MODE: ModeId = "frame";

export function modeOf(id: string | undefined): Mode {
	return (id && id in MODES ? MODES[id as ModeId] : MODES[DEFAULT_MODE]) as Mode;
}
