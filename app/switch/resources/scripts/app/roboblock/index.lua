-- tts.lua

local Database = require "resources.functions.database"

local function file_exists(path)
    local f = io.open(path, "rb")
    if f then f:close() return true else return false end
end

local function ensure_directory(path)
    os.execute("mkdir -p " .. path)
end

-- Inputs
local domain_uuid     = session:getVariable("domain_uuid")
local text            = argv[1] or "No text provided."
local save_flag       = argv[2] == "true"
local custom_filename = argv[3] or nil

-- DB connection
local dbh = Database.new('system')

-- Fetch TTS settings
local settings = {}
dbh:query([[SELECT tts_setting_uuid, engine_type, api_key, language, voice, speed, audio_path
             FROM v_tts_settings
             WHERE domain_uuid = :domain_uuid
             LIMIT 1]],
             {domain_uuid = domain_uuid},
             function(row)
                 settings = row
             end)

-- Apply defaults
settings.engine_type = settings.engine_type or "espeak"
settings.language    = settings.language or "en-us"
settings.voice       = settings.voice or "default"
settings.speed       = tonumber(settings.speed) or 140
settings.audio_path  = settings.audio_path or "/tmp/tts_audio/"

ensure_directory(settings.audio_path)

-- Create UUID using FreeSWITCH API
local api = freeswitch.API()
local unique_id = api:execute("create_uuid")

-- Determine filename
local filename = custom_filename and (custom_filename .. ".wav") or (unique_id .. ".wav")
local audio_file = settings.audio_path .. filename

-- Check for cached file
local cached = file_exists(audio_file)

if not cached then
    freeswitch.consoleLog("NOTICE", "[TTS] Generating audio via: " .. settings.engine_type .. "\n")

    if settings.engine_type == "espeak" then
        local cmd = string.format('espeak -v %s -s %d -w "%s" "%s"',
            settings.language, settings.speed, audio_file, text)
        os.execute(cmd)
    elseif settings.engine_type == "aws" then
        freeswitch.consoleLog("ERR", "[TTS] AWS engine not implemented yet.\n")
        return
    elseif settings.engine_type == "google" then
        freeswitch.consoleLog("ERR", "[TTS] Google engine not implemented yet.\n")
        return
    elseif settings.engine_type == "azure" then
        freeswitch.consoleLog("ERR", "[TTS] Azure engine not implemented yet.\n")
        return
    else
        freeswitch.consoleLog("ERR", "[TTS] Unsupported engine: " .. tostring(settings.engine_type) .. "\n")
        return
    end

    if save_flag then
        -- Save to DB cache
        dbh:query([[INSERT INTO v_tts_audio_cache (tts_audio_uuid, tts_setting_uuid, text_hash, audio_file)
                    VALUES (:uuid, :tts_setting_uuid, :text_hash, :audio_file)]],
                  {
                    uuid = unique_id,
                    tts_setting_uuid = settings.tts_setting_uuid,
                    text_hash = custom_filename or unique_id,
                    audio_file = audio_file
                  })
    end
else
    freeswitch.consoleLog("NOTICE", "[TTS] Using cached file: " .. audio_file .. "\n")
    if save_flag then
        dbh:query("UPDATE v_tts_audio_cache SET date_accessed = NOW() WHERE text_hash = :hash", {
            hash = custom_filename or unique_id
        })
    end
end

-- Playback
session:streamFile(audio_file)

-- Remove file if not saving
if not save_flag and file_exists(audio_file) then
    os.remove(audio_file)
end

if dbh then dbh:release() end
