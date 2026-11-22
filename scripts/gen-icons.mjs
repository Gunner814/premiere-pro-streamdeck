// Generates the plugin's placeholder PNG icons (no dependencies): a Premiere-purple
// rounded square with a white play triangle and a playhead line.
import { deflateSync } from "node:zlib";
import { mkdirSync, writeFileSync } from "node:fs";
import { dirname } from "node:path";

const SD = "com.gunner814.premiere-pro.sdPlugin";

const CRC = (() => {
	const t = new Uint32Array(256);
	for (let n = 0; n < 256; n++) {
		let c = n;
		for (let k = 0; k < 8; k++) c = c & 1 ? 0xedb88320 ^ (c >>> 1) : c >>> 1;
		t[n] = c >>> 0;
	}
	return t;
})();
const crc32 = (b) => {
	let c = 0xffffffff;
	for (const x of b) c = CRC[(c ^ x) & 0xff] ^ (c >>> 8);
	return (c ^ 0xffffffff) >>> 0;
};
const chunk = (type, data) => {
	const t = Buffer.from(type, "ascii");
	const len = Buffer.alloc(4);
	len.writeUInt32BE(data.length);
	const crc = Buffer.alloc(4);
	crc.writeUInt32BE(crc32(Buffer.concat([t, data])));
	return Buffer.concat([len, t, data, crc]);
};
function png(w, h, rgba) {
	const ihdr = Buffer.alloc(13);
	ihdr.writeUInt32BE(w, 0);
	ihdr.writeUInt32BE(h, 4);
	ihdr[8] = 8;
	ihdr[9] = 6;
	const raw = Buffer.alloc((w * 4 + 1) * h);
	for (let y = 0; y < h; y++) {
		raw[y * (w * 4 + 1)] = 0;
		rgba.copy(raw, y * (w * 4 + 1) + 1, y * w * 4, (y + 1) * w * 4);
	}
	return Buffer.concat([
		Buffer.from([0x89, 0x50, 0x4e, 0x47, 0x0d, 0x0a, 0x1a, 0x0a]),
		chunk("IHDR", ihdr),
		chunk("IDAT", deflateSync(raw)),
		chunk("IEND", Buffer.alloc(0))
	]);
}

function draw(size, { background }) {
	const buf = Buffer.alloc(size * size * 4);
	const r = size * 0.18;
	const inTri = (x, y) => {
		// right-pointing triangle, centred
		const ax = size * 0.38, ay = size * 0.28, bx = size * 0.38, by = size * 0.72, cx = size * 0.72, cy = size * 0.5;
		const d = (px, py, qx, qy, rx, ry) => (px - rx) * (qy - ry) - (qx - rx) * (py - ry);
		const d1 = d(x, y, ax, ay, bx, by), d2 = d(x, y, bx, by, cx, cy), d3 = d(x, y, cx, cy, ax, ay);
		const neg = d1 < 0 || d2 < 0 || d3 < 0, pos = d1 > 0 || d2 > 0 || d3 > 0;
		return !(neg && pos);
	};
	for (let y = 0; y < size; y++) {
		for (let x = 0; x < size; x++) {
			const i = (y * size + x) * 4;
			// rounded-corner mask
			const dx = Math.max(r - x, 0, x - (size - 1 - r)), dy = Math.max(r - y, 0, y - (size - 1 - r));
			if (dx * dx + dy * dy > r * r) continue;
			const line = x >= size * 0.2 && x <= size * 0.2 + Math.max(1, size * 0.045) && y > size * 0.18 && y < size * 0.82;
			const white = inTri(x, y) || line;
			const [R, G, B] = white ? [255, 255, 255] : background;
			buf[i] = R; buf[i + 1] = G; buf[i + 2] = B; buf[i + 3] = 255;
		}
	}
	return buf;
}

function write(path, size, opts = { background: [43, 20, 110] }) {
	mkdirSync(dirname(path), { recursive: true });
	writeFileSync(path, png(size, size, draw(size, opts)));
}

const sets = [
	[`${SD}/imgs/plugin/marketplace`, 256],
	[`${SD}/imgs/plugin/category-icon`, 28],
	[`${SD}/imgs/actions/timeline-dial/icon`, 20],
	[`${SD}/imgs/actions/timeline-dial/encoder-icon`, 40],
	[`${SD}/imgs/actions/timeline-dial/key`, 72]
];
for (const [base, size] of sets) {
	write(`${base}.png`, size);
	write(`${base}@2x.png`, size * 2);
}
console.log(`Wrote ${sets.length * 2} icons under ${SD}/imgs`);
