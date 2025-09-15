
-- resources/functions/tts.lua

local Database = require "resources.functions.database"
local sha256 = require "resources.functions.sha256"

local function file_exists(path)
    local f = io.open(path, "rb")
    if f then f:close() return true else return false end
end

local function ensure_directory(path)
    os.execute("mkdir -p " .. path)
end

local function generate_espeak(text, voice, speed, path)
    local cmd = string.format('espeak-ng -v %s -s %d -w "%s" "%s"', voice, speed, path, text)
    return os.execute(cmd) == 0
end

local function generate_openai(text, voice, path)
    local https = require "ssl.https"
    local ltn12 = require "ltn12"
    local json = require "resources.functions.json"
    local api_key = os.getenv("OPENAI_API_KEY")
    if not api_key then
        freeswitch.consoleLog("ERR", "[TTS] Missing OPENAI_API_KEY env variable.\n")
        return false
    end

    local body = json.encode({
        input = text,
        model = "tts-1",
        voice = voice or "nova"
    })

    local response = {}
    local _, code = https.request{
        url = "https://api.openai.com/v1/audio/speech",
        method = "POST",
        headers = {
            ["Authorization"] = "Bearer " .. api_key,
            ["Content-Type"] = "application/json",
            ["Content-Length"] = tostring(#body)
        },
        source = ltn12.source.string(body),
        sink = ltn12.sink.file(io.open(path, "wb"))
    }

    return code == 200
end

local function generate_aws(text, voice, path)
    local cmd = string.format('aws polly synthesize-speech --output-format pcm --voice-id "%s" --text "%s" "%s"', voice, text, path)
    return os.execute(cmd) == 0
end

local function generate_google(text, voice, path)
    local tmpfile = "/tmp/google_response.json"
    local cmd = string.format(
        [[curl -s -X POST "https://texttospeech.googleapis.com/v1/text:synthesize" \
        -H "Authorization: Bearer $(gcloud auth print-access-token)" \
        -H "Content-Type: application/json" \
        -d '{"input":{"text":"%s"},"voice":{"languageCode":"en-US","name":"%s"},"audioConfig":{"audioEncoding":"LINEAR16"}}' \
        -o %s]],
        text, voice, tmpfile
    )

    if os.execute(cmd) ~= 0 then return false end
    return os.execute(string.format("jq -r .audioContent %s | base64 -d > '%s'", tmpfile, path)) == 0
end

local function generate_azure(text, voice, path)
    local ssml = string.format([[
        <speak version='1.0' xml:lang='en-US'>
            <voice xml:lang='en-US' name='%s'>%s</voice>
        </speak>]], voice, text)

    local cmd = string.format([[
        curl -s -X POST "https://%s.tts.speech.microsoft.com/cognitiveservices/v1" \
        -H "Content-Type: application/ssml+xml" \
        -H "X-Microsoft-OutputFormat: riff-24khz-16bit-mono-pcm" \
        -H "Ocp-Apim-Subscription-Key: %s" \
        -d '%s' -o "%s"]],
        os.getenv("AZURE_REGION") or "eastus",
        os.getenv("AZURE_KEY") or "",
        ssml, path
    )
    return os.execute(cmd) == 0
end

local tts = {}

function tts.speak(session, text, save_flag, custom_name, sample_rate)
    local domain_uuid = session:getVariable("domain_uuid") or ''
    local dbh = Database.new('system')

    local settings = {}
    dbh:query([[
        SELECT tts_setting_uuid, engine_type, language, voice, speed
        FROM v_tts_settings
        WHERE domain_uuid = :domain_uuid
        LIMIT 1
    ]], {domain_uuid = domain_uuid}, function(row)
        settings = row
    end)

    -- Defaults
    local engine = settings.engine_type or "openai"
    local voice = settings.voice or "nova"
    local speed = tonumber(settings.speed) or 140
    local rate = sample_rate or "24000"

    local api = freeswitch.API()
    local uuid = api:execute("create_uuid")
    local hash = sha256.sha256hex(text)
    local base_path = "/usr/share/freeswitch/sounds/en/us/callie/tts/" .. rate .. "/"
    ensure_directory(base_path)
    local filename = (custom_name and custom_name .. "_" .. uuid or uuid) .. ".wav"
    local audio_file = base_path .. filename

    if not file_exists(audio_file) then
        freeswitch.consoleLog("NOTICE", "[TTS] Generating new audio using " .. engine .. "\n")

        local ok = false
        if engine == "espeak" then
            ok = generate_espeak(text, voice, speed, audio_file)
        elseif engine == "openai" then
            ok = generate_openai(text, voice, audio_file)
        elseif engine == "aws" then
            ok = generate_aws(text, voice, audio_file)
        elseif engine == "google" then
            ok = generate_google(text, voice, audio_file)
        elseif engine == "azure" then
            ok = generate_azure(text, voice, audio_file)
        end

        if not ok then
            freeswitch.consoleLog("ERR", "[TTS] Failed to generate audio for engine: " .. engine .. "\n")
            return
        end
    else
        freeswitch.consoleLog("NOTICE", "[TTS] Using cached audio: " .. audio_file .. "\n")
    end

    session:streamFile(audio_file)
    if not save_flag and file_exists(audio_file) then
        os.remove(audio_file)
    end
    if save_flag then
        dbh:query([[
            INSERT INTO v_tts_audio_cache (tts_audio_uuid, tts_setting_uuid, text_hash, audio_file)
            VALUES (:uuid, :tts_setting_uuid, :text_hash, :audio_file)
        ]], {
            uuid = uuid,
            tts_setting_uuid = settings.tts_setting_uuid,
            text_hash = hash,
            audio_file = audio_file
        })
    end
    if dbh then dbh:release() end
end