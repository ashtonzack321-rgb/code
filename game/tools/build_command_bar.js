#!/usr/bin/env node
/*
 * build_command_bar.js
 *
 * Joins AreasConfig.lua and MapBuilder/init.lua into ONE self-contained Lua file,
 * tools/BuildMap.command.lua, that you paste into Roblox Studio's Command Bar
 * (View > Command Bar). Running it builds the whole map in the open place.
 *
 * Usage:  node tools/build_command_bar.js          (writes the file)
 *         node tools/build_command_bar.js --check  (exits 1 if the file is out of date)
 */
'use strict';

const fs = require('fs');
const path = require('path');

const ROOT = path.resolve(__dirname, '..');
const CONFIG_PATH = path.join(ROOT, 'src', 'ReplicatedStorage', 'Shared', 'AreasConfig.lua');
const BUILDER_PATH = path.join(ROOT, 'src', 'ServerStorage', 'MapBuilder', 'init.lua');
const OUT_PATH = path.join(ROOT, 'tools', 'BuildMap.command.lua');

function indent(source) {
  return source
    .replace(/\r\n/g, '\n')
    .replace(/\s+$/, '')
    .split('\n')
    .map((line) => (line.length ? '\t' + line : line))
    .join('\n');
}

function generate() {
  const config = fs.readFileSync(CONFIG_PATH, 'utf8');
  const builder = fs.readFileSync(BUILDER_PATH, 'utf8');
  if (!/\breturn AreasConfig\s*$/.test(config.trim())) {
    throw new Error('AreasConfig.lua must end with "return AreasConfig"');
  }
  if (!/\breturn MapBuilder\s*$/.test(builder.trim())) {
    throw new Error('MapBuilder/init.lua must end with "return MapBuilder"');
  }

  return [
    '--[[',
    '\tSteal a Beast: BUILD THE MAP',
    '',
    '\tGENERATED FILE: do not edit. It is made by game/tools/build_command_bar.js from',
    '\tgame/src/ReplicatedStorage/Shared/AreasConfig.lua and game/src/ServerStorage/MapBuilder/init.lua.',
    '',
    '\tHow to use it:',
    '\t  1. Open your place in Roblox Studio.',
    '\t  2. View tab > Command Bar.',
    '\t  3. Select ALL of this file, copy it, paste it into the Command Bar and press Enter.',
    '\t  4. Wait for "[MapBuilder] Built workspace.Map ..." in the Output window, then File > Save.',
    '',
    '\tRunning it again rebuilds the map (the old workspace.Map is deleted first).',
    '\tCtrl+Z undoes the whole build in one step.',
    ']]',
    '',
    'local AreasConfig = (function()',
    indent(config),
    'end)()',
    '',
    'local MapBuilder = (function()',
    indent(builder),
    'end)()',
    '',
    '-- Build, recorded as one undo step when Studio allows it',
    'local ChangeHistoryService = nil',
    'pcall(function()',
    '\tChangeHistoryService = game:GetService("ChangeHistoryService")',
    'end)',
    'local recording = nil',
    'if ChangeHistoryService then',
    '\tpcall(function()',
    '\t\trecording = ChangeHistoryService:TryBeginRecording("Build Steal a Beast map")',
    '\tend)',
    'end',
    'local ok, result = pcall(MapBuilder.build, AreasConfig)',
    'if ChangeHistoryService and recording then',
    '\tpcall(function()',
    '\t\tif ok then',
    '\t\t\tChangeHistoryService:FinishRecording(recording, Enum.FinishRecordingOperation.Commit)',
    '\t\telse',
    '\t\t\tChangeHistoryService:FinishRecording(recording, Enum.FinishRecordingOperation.Cancel)',
    '\t\tend',
    '\tend)',
    'end',
    'if not ok then',
    '\terror("[MapBuilder] Build failed: " .. tostring(result), 0)',
    'end',
    'return result',
    '',
  ].join('\n');
}

function main() {
  const output = generate();
  if (process.argv.includes('--check')) {
    const current = fs.existsSync(OUT_PATH) ? fs.readFileSync(OUT_PATH, 'utf8') : '';
    if (current !== output) {
      console.error('tools/BuildMap.command.lua is out of date. Run: node tools/build_command_bar.js');
      process.exit(1);
    }
    console.log('tools/BuildMap.command.lua is up to date.');
    return;
  }
  fs.writeFileSync(OUT_PATH, output);
  const lines = output.split('\n').length;
  console.log(`Wrote ${path.relative(ROOT, OUT_PATH)} (${lines} lines, ${Buffer.byteLength(output)} bytes).`);
}

module.exports = { generate, OUT_PATH };

if (require.main === module) {
  main();
}
