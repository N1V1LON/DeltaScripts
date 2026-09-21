const assert = require('assert');
const fs = require('fs');
const path = require('path');
const { createRobloxEnvironment } = require('../src/roblox_env');

console.log('=== RUNNING ROBLOX ENV & LUA SCRIPT COMPATIBILITY TESTS ===');

// Test 1: Basic Roblox API Mocks
const env = createRobloxEnvironment();
assert.ok(env, 'Roblox Environment should be instantiated');

env.execute(`
	local frame = Instance.new("Frame")
	frame.Name = "TestFrame"
	frame.Size = UDim2.fromOffset(100, 200)
	frame.Position = UDim2.fromOffset(50, 50)
	frame.BackgroundColor3 = Color3.fromRGB(255, 0, 0)
	frame.Parent = game:GetService("Players").LocalPlayer.PlayerGui

	_G.testFrame = frame
`);

const tree1 = env.getTreeState();
assert.ok(tree1, 'Tree state should be non-null');
assert.strictEqual(tree1.name, 'PlayerGui');
assert.strictEqual(tree1.children.length, 1);
assert.strictEqual(tree1.children[0].name, 'TestFrame');
assert.strictEqual(tree1.children[0].size.x.offset, 100);
assert.strictEqual(tree1.children[0].size.y.offset, 200);
console.log('✓ Test 1 Passed: Roblox Instance creation and tree state hierarchy');

// Test 2: ControlerScript.lua Execution & Module System
const scriptPath = path.join(__dirname, '..', 'Scripts', 'ControlerScript.lua');
const luaCode = fs.readFileSync(scriptPath, 'utf8');

env.execute(luaCode, 'ControlerScript.lua');

const tree2 = env.getTreeState();
assert.ok(tree2, 'Tree state after ControlerScript execution should be non-null');
assert.ok(tree2.children.length > 0, 'PlayerGui should contain created ScreenGui');

const screenGui = tree2.children.find(c => c.name === 'ScriptsWindowGui');
assert.ok(screenGui, 'ScriptsWindowGui should exist in PlayerGui');

const scriptsRoot = screenGui.children.find(c => c.name === 'ScriptsRoot');
assert.ok(scriptsRoot, 'ScriptsRoot frame should exist inside ScriptsWindowGui');

console.log('✓ Test 2 Passed: ControlerScript.lua & modular script registry loaded successfully');

// Test 3: Event Triggering (Clicking Module Button in UI)
const contentFrame = scriptsRoot.children.find(c => c.name === 'Content');
assert.ok(contentFrame, 'Content frame should exist');

const listFrame = contentFrame.children.find(c => c.name === 'List');
assert.ok(listFrame, 'List scrolling frame should exist');

const speedModuleBtn = listFrame.children.find(c => c.name === 'Module_1');
assert.ok(speedModuleBtn, 'Module_1 button should exist');

// Fire click on Module_1 (Speed Interface)
env.triggerEvent(speedModuleBtn.id, 'MouseButton1Click', {});

const tree3 = env.getTreeState();
const speedWindow = tree3.children.find(c => c.name === 'SpeedWindowGui');
assert.ok(speedWindow, 'SpeedWindowGui window should open on clicking Speed module');

console.log('✓ Test 3 Passed: UI button click event triggering and window creation');

console.log('=== ALL ENGINE & ROBLOX SCRIPT TESTS PASSED SUCCESSFULLY! ===');
