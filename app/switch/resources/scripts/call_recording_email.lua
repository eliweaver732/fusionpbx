-- call_recording_email.lua
-- Usage: run with domain_name and uuid as arguments

local json = require "resources.functions.file_ex"

-- includes
local Database = require "resources.functions.database"
local Settings = require "resources.functions.settings"
local file = require "resources.functions.file"
local utils = require "resources.functions.trim"

-- get argv
local domain_name = argv[1]
local uuid = argv[2]

-- wait to ensure recording is complete
session:sleep(2000)

-- validate inputs
if not domain_name or not uuid then
    freeswitch.consoleLog("ERR", "[call_recording_email] Missing domain_name or uuid\n")
    return
end

-- load config and database handle
local dbh = Database.new('system')
local settings = Settings.new(dbh, domain_name, nil)

local email_to = settings:get('call_recordings', 'email', 'text') or ''
if email_to == '' then
    freeswitch.consoleLog("NOTICE", "[call_recording_email] No email destination configured. Skipping.\n")
    return
end

local transcription_enabled = settings:get('call_recordings', 'transcription_enabled', 'boolean') == 'true'
local recordings_dir = settings:get('recordings', 'storage_path') or '/var/lib/freeswitch/recordings'

-- construct recording file path
local date = os.date("*t")
local file_path = string.format("%s/%s/archive/%04d/%s/%02d", recordings_dir, domain_name, date.year, os.date("%b"), date.day)
local file_name = uuid .. ".wav"
local full_path = file_path .. "/" .. file_name

-- check file exists
if not file.exists(full_path) then
    freeswitch.consoleLog("ERR", "[call_recording_email] Recording not found at: " .. full_path .. "\n")
    return
end

-- Determine template subcategory
local template_subcategory = transcription_enabled and "transcription" or "default"

-- Fetch email template from database
local email_subject = "Call Recording"
local email_body = "Call recording attached.\n\n${message_text}"

local tmpl_sql = [[
	SELECT subject, body
	FROM v_email_templates
	WHERE template_category = 'call_recording'
	AND template_subcategory = :subcategory
	AND template_enabled = 'true'
	LIMIT 1
]]

dbh:query(tmpl_sql, {subcategory = template_subcategory}, function(row)
    email_subject = row.subject or email_subject
    email_body = row.body or email_body
end)

-- Fetch call details and transcription from v_xml_cdr
local caller_id_name = ""
local caller_id_number = ""
local start_stamp = ""
local end_stamp = ""
local transcription = ""

local cdr_sql = [[
	SELECT caller_id_name, caller_id_number, start_stamp, end_stamp, record_transcription
	FROM v_xml_cdr
	WHERE domain_name = :domain_name
	AND uuid = :uuid
	LIMIT 1
]]

dbh:query(cdr_sql, {domain_name = domain_name, uuid = uuid}, function(row)
    caller_id_name = row.caller_id_name or ""
    caller_id_number = row.caller_id_number or ""
    start_stamp = row.start_stamp or ""
    end_stamp = row.end_stamp or ""
    transcription = row.record_transcription or ""
end)

-- Calculate call recording length in seconds
local call_recording_length = ""

local function parse_date(d)
    if #d < 19 then return nil end
    local y = tonumber(d:sub(1,4))
    local m = tonumber(d:sub(6,7))
    local day = tonumber(d:sub(9,10))
    local h = tonumber(d:sub(12,13))
    local min = tonumber(d:sub(15,16))
    local s = tonumber(d:sub(18,19))
    return os.time({year = y, month = m, day = day, hour = h, min = min, sec = s})
end

local start_time = parse_date(start_stamp)
local end_time = parse_date(end_stamp)
if start_time and end_time then
    call_recording_length = tostring(os.difftime(end_time, start_time))
end

-- Replace variables in subject and body
local replacements = {
    ["${message_text}"] = transcription,
    ["${caller_id_number}"] = caller_id_number,
    ["${caller_id_name}"] = caller_id_name,
    ["${uuid}"] = uuid,
    ["${call_recording_length}"] = call_recording_length
}

for k, v in pairs(replacements) do
    if v == nil then v = "" end
    email_subject = email_subject:gsub(k, v)
    email_body = email_body:gsub(k, v)
end

-- Insert into v_email_queue
local email_queue_uuid = utils.uuid()

local insert_sql = [[
INSERT INTO v_email_queue (
    email_queue_uuid, domain_uuid, hostname, email_date, email_from, email_to,
    email_subject, email_body, email_status, email_retry_count,
    email_job_type, email_uuid
)
SELECT
    :email_queue_uuid, d.domain_uuid, :hostname, now(), :email_from, :email_to,
    :email_subject, :email_body, 'waiting', 0, 'call_recording', :email_uuid
FROM v_domains d
WHERE d.domain_name = :domain_name
]]

dbh:query(insert_sql, {
    email_queue_uuid = email_queue_uuid,
    hostname = freeswitch.getGlobalVariable("hostname"),
    email_from = "noreply@" .. domain_name,
    email_to = email_to,
    email_subject = email_subject,
    email_body = email_body,
    email_uuid = uuid,
    domain_name = domain_name
})

-- Insert attachment record
local attach_sql = [[
INSERT INTO v_email_queue_attachments (
    email_queue_attachment_uuid, domain_uuid, email_queue_uuid,
    email_attachment_type, email_attachment_path, email_attachment_name
)
SELECT
    :attachment_uuid, d.domain_uuid, :email_queue_uuid,
    'wav', :attachment_path, :attachment_name
FROM v_domains d
WHERE d.domain_name = :domain_name
]]

dbh:query(attach_sql, {
    attachment_uuid = utils.uuid(),
    email_queue_uuid = email_queue_uuid,
    attachment_path = full_path,
    attachment_name = file_name,
    domain_name = domain_name
})

freeswitch.consoleLog("NOTICE", "[call_recording_email] Enqueued call recording email for: " .. email_to .. "\n")