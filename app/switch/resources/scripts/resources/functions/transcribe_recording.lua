local M = {}

local Database = require "resources.functions.database"
local send_mail = require "resources.functions.send_mail"

function M.transcribe_and_notify(recording_uuid, domain_name, file_path)
	-- Step 1: Transcribe
	local handle = io.popen("/usr/local/bin/speech-to-text.sh '" .. file_path .. "'")
	local transcription = handle:read("*a")
	handle:close()

	if not transcription or transcription == '' then
		freeswitch.consoleLog("ERR", "[transcribe] Transcription failed or empty\n")
		return
	end

	-- Step 2: Save transcription to DB
	local dbh = Database.new('system')
	local sql = [[
		UPDATE v_recordings
		SET transcription = :transcription
		WHERE recording_uuid = :recording_uuid
	]]
	dbh:query(sql, {
		transcription = transcription,
		recording_uuid = recording_uuid
	})
	dbh:release()

	-- Step 3: Fetch email from default settings
	local email
	dbh = Database.new('system')
	sql = [[
		SELECT default_setting_value FROM v_default_settings
		WHERE default_setting_category = 'call_recordings'
			AND default_setting_subcategory = 'email'
			AND default_setting_enabled = 'true'
		LIMIT 1
	]]
	dbh:query(sql, {}, function(row)
		email = row.default_setting_value
	end)
	dbh:release()

	if not email or email == '' then
		freeswitch.consoleLog("NOTICE", "[transcribe] No email configured. Skipping notification.\n")
		return
	end

	-- Step 4: Send transcription email
	local subject = "Call Recording Transcription"
	local body = [[
		<p>Hello,</p>
		<p>Here is the transcription of your call recording:</p>
		<pre style="background:#f0f0f0;padding:10px;border-radius:5px;">]] .. transcription .. [[</pre>
		<p>— FusionPBX</p>
	]]
	local headers = {}
	local from = 'noreply@' .. domain_name
	local to = email

	send_mail(headers, from, to, {subject, body}, nil)
end

return M