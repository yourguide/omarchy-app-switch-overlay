const { test } = require('node:test');
const assert = require('node:assert/strict');
const fs = require('node:fs');
const path = require('node:path');

// Every themes/*.json must describe a theme the Service can load.
const dir = path.join(__dirname, '../themes');
const descriptors = fs.readdirSync(dir).filter((f) => f.endsWith('.json'));
const types = ['bool', 'number', 'slider', 'choice', 'enum', 'color'];

test('base and hulk-smash themes are present', () => {
    const ids = descriptors.map((f) => JSON.parse(fs.readFileSync(path.join(dir, f), 'utf8')).id);
    assert.ok(ids.includes('base'));
    assert.ok(ids.includes('hulk-smash'));
    assert.equal(new Set(ids).size, ids.length, 'theme ids are unique');
});

for (const file of descriptors) {
    test(`${file} is a valid theme descriptor`, () => {
        const t = JSON.parse(fs.readFileSync(path.join(dir, file), 'utf8'));
        assert.match(t.id, /^[a-z0-9-]+$/);
        assert.ok(t.name && typeof t.name === 'string');
        const qml = t.qml || file.replace(/\.json$/, '.qml');
        assert.ok(fs.existsSync(path.join(dir, qml)), `${qml} exists`);
        const src = fs.readFileSync(path.join(dir, qml), 'utf8');
        for (const member of ['property var host', 'property var options', 'property bool primary',
            'bool active', 'function show()', 'function pulse()', 'function hide()']) {
            assert.ok(src.includes(member), `${qml} declares ${member}`);
        }
        for (const s of src.matchAll(/sound:\s*"([^"]+)"/g)) {
            assert.ok(fs.existsSync(path.join(__dirname, '../sounds', s[1])), `sounds/${s[1]} exists`);
        }
        const keys = new Set();
        for (const e of t.settings || []) {
            assert.ok(e.key && !keys.has(e.key), `unique key ${e.key}`);
            keys.add(e.key);
            assert.ok(types.includes(e.type), `${e.key} has a known type`);
            if (e.type === 'number' || e.type === 'slider') {
                assert.ok(e.min < e.max && e.default >= e.min && e.default <= e.max, `${e.key} range`);
            }
            if (e.type === 'choice' || e.type === 'enum') {
                const values = e.choices.map((c) => (c && typeof c === 'object' ? c.value : c));
                assert.ok(values.includes(e.default), `${e.key} default is a choice`);
            }
            if (e.type === 'bool') assert.equal(typeof e.default, 'boolean');
            if (e.type === 'color') assert.match(e.default, /^(|#[0-9a-fA-F]{6}|#[0-9a-fA-F]{8})$/);
        }
    });
}
