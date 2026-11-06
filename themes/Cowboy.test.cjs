const { test } = require('node:test');
const assert = require('node:assert/strict');
const fs = require('node:fs');
const path = require('node:path');

test('Cowboy artwork is local, small, and has no external dependencies', () => {
    for (const name of ['CowboyWood.svg', 'CowboyHole.svg']) {
        const svg = fs.readFileSync(path.join(__dirname, name), 'utf8');
        assert.match(svg, /<svg /);
        assert.ok(Buffer.byteLength(svg) < 16000, `${name} stays small`);
        assert.doesNotMatch(svg, /<(?:script|image|foreignObject|filter)\b/i);
        assert.doesNotMatch(svg, /\bhref\s*=/i);
    }
    assert.ok(fs.existsSync(path.join(__dirname, 'CowboyBoard.qml')));
});

for (const [name, expectedDuration, peakLimit] of [
    ['cowboy-creak.wav', 0.18, 0.12],
    ['cowboy-shot.wav', 0.3, 0.36],
]) {
    test(`${name} is short, quiet mono PCM with a clean ending`, () => {
        const wav = fs.readFileSync(path.join(__dirname, '../sounds', name));
        assert.equal(wav.toString('ascii', 0, 4), 'RIFF');
        assert.equal(wav.toString('ascii', 8, 12), 'WAVE');
        assert.equal(wav.toString('ascii', 12, 16), 'fmt ');
        assert.equal(wav.readUInt16LE(20), 1, 'PCM');
        assert.equal(wav.readUInt16LE(22), 1, 'mono');
        assert.equal(wav.readUInt32LE(24), 48000, '48 kHz');
        assert.equal(wav.readUInt16LE(34), 16, '16-bit');
        assert.equal(wav.toString('ascii', 36, 40), 'data');
        assert.equal(wav.readUInt32LE(40), wav.length - 44);
        const count = (wav.length - 44) / 2;
        assert.equal(count / 48000, expectedDuration);
        const samples = Array.from({ length: count }, (_, i) => wav.readInt16LE(44 + i * 2));
        const peak = Math.max(...samples.map(Math.abs)) / 32768;
        const rms = Math.sqrt(samples.reduce((sum, value) => sum + value * value, 0) / count) / 32768;
        assert.ok(peak > 0 && peak < peakLimit, `peak ${peak.toFixed(3)}`);
        assert.ok(rms < 0.08, `RMS ${rms.toFixed(3)}`);
        assert.ok(samples.slice(0, 48).some(value => value !== 0), 'no leading silence');
        assert.ok(samples.slice(-48).every(value => Math.abs(value) < 50), 'quiet tail');
    });
}
