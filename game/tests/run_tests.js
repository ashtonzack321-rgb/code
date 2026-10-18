#!/usr/bin/env node
/*
 * run_tests.js: the test runner for the Steal a Beast map.
 *
 *   1. Syntax-checks every .lua file with luaparse (luaVersion 5.3) and rejects Lua 5.3
 *      features that Luau does not have (goto, labels, //, bitwise operators) plus a few
 *      library calls that only exist in one of the two.
 *   2. Checks that tools/BuildMap.command.lua is up to date with the sources.
 *   3. Runs the REAL tools/BuildMap.command.lua twice under fengari (Lua 5.3) against
 *      tests/mock_roblox.lua, with the checks in tests/map_tests.lua.
 *
 * Prints PASS/FAIL lines and exits with code 1 if anything failed.
 * Usage: node tests/run_tests.js   (or: npm test, which rebuilds the command file first)
 */
'use strict';

const fs = require('fs');
const path = require('path');
const luaparse = require('luaparse');
const { createMapEnv, PATHS } = require('./lua_env');
const { generate } = require('../tools/build_command_bar');

let passed = 0;
let failed = 0;

function report(name, ok, detail) {
  if (ok) {
    passed += 1;
    console.log(`PASS  ${name}`);
  } else {
    failed += 1;
    console.log(`FAIL  ${name}${detail ? `\n        ${detail}` : ''}`);
  }
}

function listLuaFiles(dir) {
  const out = [];
  for (const entry of fs.readdirSync(dir, { withFileTypes: true })) {
    if (entry.name === 'node_modules' || entry.name.startsWith('.')) continue;
    const full = path.join(dir, entry.name);
    if (entry.isDirectory()) out.push(...listLuaFiles(full));
    else if (entry.name.endsWith('.lua')) out.push(full);
  }
  return out.sort();
}

// Lua 5.3 syntax that Luau rejects, and library members that only one of them has.
const FORBIDDEN_BINARY = new Set(['//', '&', '|', '~', '<<', '>>']);
const FORBIDDEN_MEMBERS = new Set([
  'math.type', 'math.tointeger', 'math.ult', 'string.pack', 'string.unpack', 'string.packsize',
  // Luau-only helpers that plain Lua 5.3 lacks (the tests would crash on them)
  'math.clamp', 'math.sign', 'math.round', 'table.find', 'table.create', 'table.clear', 'string.split',
  'task.wait', 'task.spawn', 'task.delay',
]);
const FORBIDDEN_GLOBALS = new Set(['setfenv', 'getfenv', 'loadstring', 'unpack', 'typeof', 'tick', 'wait', 'spawn', 'delay']);

function walk(node, visit) {
  if (!node || typeof node !== 'object') return;
  if (Array.isArray(node)) {
    node.forEach((n) => walk(n, visit));
    return;
  }
  if (typeof node.type === 'string') visit(node);
  for (const key of Object.keys(node)) {
    if (key === 'loc' || key === 'range') continue;
    walk(node[key], visit);
  }
}

function checkLuauSubset(ast, isTestFile) {
  const problems = [];
  const declared = new Set();
  walk(ast, (node) => {
    const line = node.loc ? node.loc.start.line : '?';
    if (node.type === 'GotoStatement' || node.type === 'LabelStatement') {
      problems.push(`line ${line}: goto/label`);
    } else if ((node.type === 'BinaryExpression' && FORBIDDEN_BINARY.has(node.operator))
      || (node.type === 'UnaryExpression' && node.operator === '~')) {
      problems.push(`line ${line}: operator ${node.operator}`);
    } else if (node.type === 'MemberExpression' && node.base.type === 'Identifier' && node.identifier) {
      const name = `${node.base.name}.${node.identifier.name}`;
      if (FORBIDDEN_MEMBERS.has(name)) problems.push(`line ${line}: ${name}`);
    } else if (node.type === 'LocalStatement' || node.type === 'LocalFunctionStatement') {
      (node.variables || []).forEach((v) => declared.add(v.name));
      if (node.identifier) declared.add(node.identifier.name);
    } else if (node.type === 'CallExpression' && node.base.type === 'Identifier') {
      const name = node.base.name;
      if (FORBIDDEN_GLOBALS.has(name) && !declared.has(name) && !(isTestFile && name === 'typeof')) {
        problems.push(`line ${line}: global ${name}()`);
      }
    }
  });
  return problems;
}

function syntaxChecks() {
  const files = listLuaFiles(PATHS.root);
  for (const file of files) {
    const rel = path.relative(PATHS.root, file);
    const source = fs.readFileSync(file, 'utf8');
    let ast;
    try {
      ast = luaparse.parse(source, { luaVersion: '5.3', locations: true, comments: false, encodingMode: 'x-user-defined' });
    } catch (err) {
      report(`luaparse 5.3 syntax: ${rel}`, false, err.message);
      continue;
    }
    const problems = checkLuauSubset(ast, rel.startsWith('tests'));
    report(`luaparse 5.3 syntax + Luau-compatible subset: ${rel}`, problems.length === 0, problems.slice(0, 8).join('; '));
  }
  return files.length;
}

function freshnessCheck() {
  const current = fs.existsSync(PATHS.command) ? fs.readFileSync(PATHS.command, 'utf8') : '';
  report('tools/BuildMap.command.lua is generated from the current sources', current === generate(),
    'run: node tools/build_command_bar.js');
}

function luaTests() {
  let result;
  try {
    const env = createMapEnv();
    result = env.runFile(PATHS.tests);
  } catch (err) {
    report('Lua map tests ran to completion', false, err.message);
    return null;
  }
  const [luaPassed, luaFailed, parts] = String(result).split(' ').map(Number);
  passed += luaPassed;
  failed += luaFailed;
  return parts;
}

function main() {
  const started = Date.now();
  console.log('== Lua syntax (luaparse, Lua 5.3) ==');
  const fileCount = syntaxChecks();
  console.log('\n== Generated command-bar file ==');
  freshnessCheck();
  console.log('\n== Map build tests (fengari + mock Roblox API) ==');
  const parts = luaTests();
  const seconds = ((Date.now() - started) / 1000).toFixed(1);
  console.log(`\n${failed === 0 ? 'ALL TESTS PASSED' : 'TESTS FAILED'}: ${passed} passed, ${failed} failed `
    + `(${fileCount} Lua files checked, ${parts === null ? '?' : parts} parts built) in ${seconds}s`);
  process.exit(failed === 0 ? 0 : 1);
}

main();
