/*
 * lua_env.js: a tiny wrapper around fengari (Lua 5.3 in JavaScript) shared by
 * run_tests.js and render_preview.js. It loads the Roblox mock and the generated
 * BuildMap.command.lua into one Lua state.
 */
'use strict';

const fs = require('fs');
const path = require('path');
const { lua, lauxlib, lualib, to_luastring } = require('fengari');

const ROOT = path.resolve(__dirname, '..');
const PATHS = {
  root: ROOT,
  mock: path.join(ROOT, 'tests', 'mock_roblox.lua'),
  tests: path.join(ROOT, 'tests', 'map_tests.lua'),
  export: path.join(ROOT, 'tests', 'export_parts.lua'),
  command: path.join(ROOT, 'tools', 'BuildMap.command.lua'),
  config: path.join(ROOT, 'src', 'ReplicatedStorage', 'Shared', 'AreasConfig.lua'),
  builder: path.join(ROOT, 'src', 'ServerStorage', 'MapBuilder', 'init.lua'),
  shared: path.join(ROOT, 'src', 'ReplicatedStorage', 'Shared'),
  economyTests: path.join(ROOT, 'tests', 'economy_tests.lua'),
};

class LuaEnv {
  constructor() {
    this.L = lauxlib.luaL_newstate();
    lualib.luaL_openlibs(this.L);
  }

  // Compiles a chunk and leaves the function on the stack.
  load(source, chunkName) {
    const L = this.L;
    const buf = to_luastring(source);
    const status = lauxlib.luaL_loadbuffer(L, buf, buf.length, to_luastring('@' + chunkName));
    if (status !== lua.LUA_OK) {
      const msg = lua.lua_tojsstring(L, -1);
      lua.lua_pop(L, 1);
      throw new Error(`Lua syntax error in ${chunkName}: ${msg}`);
    }
  }

  // Compiles a chunk and stores the function in a global (without running it).
  defineChunk(globalName, source, chunkName) {
    this.load(source, chunkName);
    lua.lua_setglobal(this.L, to_luastring(globalName));
  }

  // Runs a chunk with a traceback handler; returns its first result as a JS value
  // (string, number, boolean or null).
  run(source, chunkName) {
    const L = this.L;
    lua.lua_getglobal(L, to_luastring('debug'));
    lua.lua_getfield(L, -1, to_luastring('traceback'));
    lua.lua_remove(L, -2);
    const handlerIndex = lua.lua_gettop(L);
    this.load(source, chunkName);
    const status = lua.lua_pcall(L, 0, 1, handlerIndex);
    if (status !== lua.LUA_OK) {
      const msg = lua.lua_tojsstring(L, -1);
      lua.lua_settop(L, handlerIndex - 1);
      throw new Error(`Lua error in ${chunkName}:\n${msg}`);
    }
    let value = null;
    const t = lua.lua_type(L, -1);
    if (t === lua.LUA_TSTRING) value = lua.lua_tojsstring(L, -1);
    else if (t === lua.LUA_TNUMBER) value = lua.lua_tonumber(L, -1);
    else if (t === lua.LUA_TBOOLEAN) value = lua.lua_toboolean(L, -1);
    lua.lua_settop(L, handlerIndex - 1);
    return value;
  }

  runFile(file) {
    return this.run(fs.readFileSync(file, 'utf8'), path.relative(ROOT, file));
  }
}

// A Lua state with the mock loaded, CONFIG = AreasConfig and BUILD_MAP = the command-bar chunk.
function createMapEnv() {
  const env = new LuaEnv();
  env.runFile(PATHS.mock);
  env.defineChunk('LOAD_CONFIG', fs.readFileSync(PATHS.config, 'utf8'), 'src/ReplicatedStorage/Shared/AreasConfig.lua');
  env.run('CONFIG = LOAD_CONFIG()', 'load-config');
  env.defineChunk('BUILD_MAP', fs.readFileSync(PATHS.command, 'utf8'), 'tools/BuildMap.command.lua');
  return env;
}

// A plain Lua state (no Roblox mock) with the shared gameplay modules loaded as globals.
function createEconomyEnv() {
  const env = new LuaEnv();
  const modules = { AREAS_CONFIG: 'AreasConfig', GAME_CONFIG: 'GameConfig', ECONOMY: 'Economy', NUMBER_FORMAT: 'NumberFormat' };
  for (const [globalName, file] of Object.entries(modules)) {
    const rel = `src/ReplicatedStorage/Shared/${file}.lua`;
    env.defineChunk(`LOAD_${globalName}`, fs.readFileSync(path.join(PATHS.shared, `${file}.lua`), 'utf8'), rel);
    env.run(`${globalName} = LOAD_${globalName}()`, `load-${file}`);
  }
  return env;
}

module.exports = { LuaEnv, createMapEnv, createEconomyEnv, PATHS };
