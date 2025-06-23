local Database = require "resources.functions.database"

local function file_exists(path)
    local f = io.open(path, "rb")
    if f then f:close() return true else return false end
end

local function ensure_directory(path)
    os.execute(string.format('mkdir -p "%s"', path))
end

local tts = {}

function tts.speak(session, text, save_flag, custom_name, sample_rate)
    local domain_uuid = session:getVariable("domain_uuid") or ''
    local dbh = Database.new('system')

    local settings = {}

    -- Fetch settings from database
    local found = false
    dbh:query([[
        SELECT tts_setting_uuid, engine_type, api_key, language, voice, speed
        FROM v_tts_settings
        WHERE domain_uuid = :domain_uuid
        LIMIT 1
    ]], {domain_uuid = domain_uuid}, function(row)
        settings = row
        found = true
    end)

    -- Insert default settings if missing
    if not found then
        settings = {
            tts_setting_uuid = freeswitch.API():execute("create_uuid"),
            engine_type = "espeak",
            api_key = nil,
            language = "en-us",
            voice = "mb-en1",
            speed = 140
        }

        dbh:query([[
            INSERT INTO v_tts_settings (
                tts_setting_uuid, domain_uuid, engine_type, api_key, language, voice, speed
            ) VALUES (
                :uuid, :domain_uuid, :engine_type, :api_key, :language, :voice, :speed
            )
        ]], {
            uuid = settings.tts_setting_uuid,
            domain_uuid = domain_uuid,
            engine_type = settings.engine_type,
            api_key = settings.api_key,
            language = settings.language,
            voice = settings.voice,
            speed = settings.speed
        })
    end

    settings.engine_type = settings.engine_type or "espeak"
    settings.language = settings.language or "en-us"
    settings.voice = settings.voice or "mb-en1"
    settings.speed = tonumber(settings.speed) or 140
    sample_rate = tostring(sample_rate or "8000")

    local base_path = "/usr/share/freeswitch/sounds/en/us/callie"
    local audio_path = base_path .. "/tts/" .. sample_rate .. "/"
    ensure_directory(audio_path)

    local api = freeswitch.API()
    local uuid = api:execute("create_uuid")
    local filename = (custom_name and (custom_name .. "_" .. uuid) or uuid) .. ".wav"
    local audio_file = audio_path .. filename

    local cached = file_exists(audio_file)

    if not cached then
        freeswitch.consoleLog("NOTICE", "[TTS] Generating audio via: " .. settings.engine_type .. "\n")

        if settings.engine_type == "espeak" then
            local cmd = string.format(
                'espeak -v "%s" -s %d -w "%s" "%s"',
                settings.voice, settings.speed, audio_file, text:gsub('"', '\\"')
            )
            os.execute(cmd)
        else
            freeswitch.consoleLog("ERR", "[TTS] Unsupported engine: " .. tostring(settings.engine_type) .. "\n")
            return
        end

        if save_flag then
            dbh:query([[
                INSERT INTO v_tts_audio_cache (
                    tts_audio_uuid, tts_setting_uuid, text_hash, audio_file
                ) VALUES (
                    :uuid, :tts_setting_uuid, :text_hash, :audio_file
                )
            ]], {
                uuid = uuid,
                tts_setting_uuid = settings.tts_setting_uuid,
                text_hash = custom_name or uuid,
                audio_file = audio_file
            })
        end
    else
        freeswitch.consoleLog("NOTICE", "[TTS] Using cached audio: " .. audio_file .. "\n")
        if save_flag then
            dbh:query([[
                UPDATE v_tts_audio_cache
                SET date_accessed = NOW()
                WHERE text_hash = :hash
            ]], { hash = custom_name or uuid })
        end
    end

    -- Play file
    session:streamFile(audio_file)

    -- Cleanup if not saving
    if not save_flag and file_exists(audio_file) then
        os.remove(audio_file)
    end

    if dbh then dbh:release() end
end

return tts