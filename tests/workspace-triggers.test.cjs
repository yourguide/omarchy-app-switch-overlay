const { test } = require('node:test');
const assert = require('node:assert/strict');
const fs = require('node:fs');
const path = require('node:path');
const vm = require('node:vm');

// Exercise the service's actual JavaScript handlers without requiring a display.
const source = fs.readFileSync(path.join(__dirname, '../Service.qml'), 'utf8');
const contextBody = source.match(/function contextKey\(\) \{([\s\S]*?)\n    \}/)[1];
const focusHandler = source.match(/^    onActiveChanged: (.*)$/m)[1];
const workspaceHandler = source.match(/^    onWorkspaceChanged: (.*)$/m)[1];
const settleBody = source.match(/id: settleTimer[\s\S]*?onTriggered: \{([\s\S]*?)\n        \}/)[1];

function service() {
    const state = vm.createContext({
        workspace: { id: 5 }, ready: true, opened: false,
        lastContext: '5', switchCount: 0, shows: 0, scheduled: 0, refreshes: 0,
        showWorkspace() { this.shows++; this.opened = true; },
    });
    state.root = state;
    state.settleTimer = { restart() { state.scheduled++; } };
    vm.runInContext(`
        function contextKey() { ${contextBody} }
        function workspaceApps() { refreshes++; return []; }
    `, state);
    return state;
}

test('focus changes between tiled apps never schedule or show the overlay', () => {
    const state = service();
    for (const opened of [false, true]) {
        state.opened = opened;
        for (const app of ['Grok Bot', 'Google Chrome', 'Grok Bot']) {
            state.active = { appId: app };
            vm.runInContext(focusHandler, state);
            assert.equal(vm.runInContext('contextKey()', state), '5');
        }
    }
    assert.equal(state.scheduled, 0);
    assert.equal(state.shows, 0);
    assert.equal(state.refreshes, 3);
});

test('desktop changes trigger once even when the focused app stays the same', () => {
    const state = service();
    state.active = { appId: 'Google Chrome' };
    state.workspace = { id: 6 };
    vm.runInContext(workspaceHandler, state);
    assert.equal(state.scheduled, 1);
    vm.runInContext(settleBody, state);
    assert.equal(state.shows, 1);
    assert.equal(state.switchCount, 1);
    assert.equal(state.lastContext, '6');
    vm.runInContext(settleBody, state);
    assert.equal(state.shows, 1);
    assert.equal(state.switchCount, 1);
});
