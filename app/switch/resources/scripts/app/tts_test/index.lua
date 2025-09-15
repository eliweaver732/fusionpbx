-- tts-test/index.lua

local tts = require "resources.functions.tts"

-- Hardcoded config
local text            = "Welcome to TTS function, This is test for TTS function."
local save_flag       = true
local custom_filename = "welcome_test"
local sample_rate     = "8000" -- or "16000", etc.

tts.speak(session, text, save_flag, custom_filename, sample_rate)