import {
	action,
	DialAction,
	DialDownEvent,
	DialRotateEvent,
	DidReceiveSettingsEvent,
	SingletonAction,
	TouchTapEvent,
	WillAppearEvent
} from "@elgato/streamdeck";
import { keys } from "../keys";
import { modeOf } from "../modes";

type TimelineDialSettings = {
	mode?: string;
};

const SPACE = 32;

function paint(dial: DialAction<TimelineDialSettings>, settings: TimelineDialSettings): Promise<void> {
	const mode = modeOf(settings.mode);
	return dial.setFeedback({ title: mode.label, value: mode.hint });
}

/**
 * A Stream Deck+ dial that drives Premiere Pro's timeline with keystrokes.
 * Rotate = the mode's key per tick (accelerated on fast spins), press = the mode's
 * secondary key, tap the touch strip = Play/Pause. The mode (frame scrub, 5-frame
 * scrub, edit-to-edit, zoom, JKL shuttle, undo/redo) is picked in the property inspector.
 */
@action({ UUID: "com.gunner814.premiere-pro.timeline-dial" })
export class TimelineDial extends SingletonAction<TimelineDialSettings> {
	override onWillAppear(ev: WillAppearEvent<TimelineDialSettings>): Promise<void> | void {
		keys.warm();
		if (ev.action.isDial()) {
			return paint(ev.action, ev.payload.settings);
		}
	}

	override onDidReceiveSettings(ev: DidReceiveSettingsEvent<TimelineDialSettings>): Promise<void> | void {
		if (ev.action.isDial()) {
			return paint(ev.action, ev.payload.settings);
		}
	}

	override onDialRotate(ev: DialRotateEvent<TimelineDialSettings>): void {
		const mode = modeOf(ev.payload.settings.mode);
		const ticks = ev.payload.ticks;
		if (ticks === 0) {
			return;
		}
		const key = ticks > 0 ? mode.cw : mode.ccw;
		const count = Math.min(mode.max, Math.max(1, Math.round(Math.abs(ticks) ** mode.curve)));
		keys.tap(key.vk, key.mods ?? 0, count);
	}

	override onDialDown(ev: DialDownEvent<TimelineDialSettings>): void {
		const push = modeOf(ev.payload.settings.mode).push;
		if (push) {
			keys.tap(push.vk, push.mods ?? 0, 1);
		}
	}

	override onTouchTap(_ev: TouchTapEvent<TimelineDialSettings>): void {
		keys.tap(SPACE, 0, 1);
	}
}
