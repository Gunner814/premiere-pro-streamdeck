import streamDeck from "@elgato/streamdeck";
import { spawn, type ChildProcessWithoutNullStreams } from "node:child_process";
import { fileURLToPath } from "node:url";

/** Modifier bitmask understood by helpers/keys.ps1. */
export const Mod = { Shift: 1, Ctrl: 2, Alt: 4 } as const;

/**
 * Sends keystrokes to Premiere Pro through a single long-running PowerShell helper
 * (helpers/keys.ps1). One persistent process keeps per-tick latency low; the helper
 * itself ignores input unless Premiere Pro is the foreground window.
 */
class KeySender {
	private proc: ChildProcessWithoutNullStreams | undefined;

	private ensure(): ChildProcessWithoutNullStreams {
		if (this.proc && this.proc.exitCode === null && !this.proc.killed) {
			return this.proc;
		}
		const script = fileURLToPath(new URL("../helpers/keys.ps1", import.meta.url));
		const p = spawn("powershell.exe", ["-NoProfile", "-ExecutionPolicy", "Bypass", "-File", script], {
			windowsHide: true
		});
		p.stdout.on("data", (d) => streamDeck.logger.debug(`keys.ps1: ${String(d).trim()}`));
		p.stderr.on("data", (d) => streamDeck.logger.warn(`keys.ps1 stderr: ${String(d).trim()}`));
		p.stdin.on("error", (err) => streamDeck.logger.warn(`keys.ps1 stdin: ${err.message}`));
		p.on("error", (err) => {
			streamDeck.logger.error(`keys.ps1 failed to start: ${err.message}`);
			this.proc = undefined;
		});
		p.on("exit", (code) => {
			streamDeck.logger.info(`keys.ps1 exited (${code})`);
			if (this.proc === p) {
				this.proc = undefined;
			}
		});
		this.proc = p;
		return p;
	}

	/** Tap `vk` (Windows virtual-key code) `count` times with optional modifiers. */
	tap(vk: number, mods = 0, count = 1): void {
		if (count < 1) {
			return;
		}
		this.ensure().stdin.write(`${vk} ${mods} ${count}\n`);
	}

	/** Spin the helper up ahead of the first keystroke so the first tick isn't slow. */
	warm(): void {
		this.ensure();
	}

	dispose(): void {
		this.proc?.kill();
		this.proc = undefined;
	}
}

export const keys = new KeySender();
