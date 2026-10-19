const { test } = require('node:test');
const assert = require('node:assert/strict');
const fs = require('node:fs');
const path = require('node:path');
const vm = require('node:vm');

const model = vm.createContext({});
vm.runInContext(fs.readFileSync(path.join(__dirname, '../AppNames.js'), 'utf8')
    .replace(/^\.pragma library\s*/, ''), model);
const summarize = (windows, entries = []) =>
    JSON.parse(JSON.stringify(model.workspaceApps(windows, entries)));

test('includes background apps and puts the focused app first', () => {
    assert.deepEqual(summarize([
        { appId: 'kitty', title: 'Private shell command' },
        { appId: 'chatgpt', focused: true },
        { appId: 'Chromium', title: 'Private conversation - Factory' },
    ]), [
        { name: 'ChatGPT', count: 1, focused: true },
        { name: 'Factory', count: 1, focused: false },
        { name: 'Kitty', count: 1, focused: false },
    ]);
});

test('groups multiple windows and retains focus on the grouped app', () => {
    assert.deepEqual(summarize([
        { appId: 'kitty' },
        { appId: 'kitty', focused: true },
        { appId: 'kitty' },
    ]), [{ name: 'Kitty', count: 3, focused: true }]);
});

test('distinguishes web apps sharing Chromium while hiding private titles', () => {
    assert.deepEqual(summarize([
        { appId: 'Chromium', title: 'Private document - Factory', focused: true },
        { appId: 'Chromium', title: 'Private contact | Microsoft Teams' },
    ]), [
        { name: 'Factory', count: 1, focused: true },
        { name: 'Microsoft Teams', count: 1, focused: false },
    ]);
});

test('handles an empty workspace', () => {
    assert.deepEqual(summarize([]), []);
});

test('resolves desktop names and falls back to an app ID', () => {
    assert.deepEqual(summarize([
        { appId: 'org.example.Editor', focused: true },
        { appId: 'unlisted-app' },
    ], [{ id: 'org.example.Editor.desktop', name: 'Example Editor' }]), [
        { name: 'Example Editor', count: 1, focused: true },
        { name: 'unlisted-app', count: 1, focused: false },
    ]);
});
