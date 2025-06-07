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

-- load config
local dbh = Database.new('system')
local settings = Settings.new(dbh, domain_name, nil)
local email_to = settings:get('call_recordings', 'email', 'text') or ''
local recordings_dir = settings:get('recordings', 'storage_path') or '/var/lib/freeswitch/recordings'

-- validate inputs
if not domain_name or not uuid then
    freeswitch.consoleLog("ERR", "[call_recording_email] Missing domain_name or uuid\n")
    return
end

if email_to == '' then
    freeswitch.consoleLog("NOTICE", "[call_recording_email] No email destination configured. Skipping.\n")
    return
end

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

-- insert into v_email_queue
local email_queue_uuid = utils.uuid()

local sql = [[
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

dbh:query(sql, {
    email_queue_uuid = email_queue_uuid,
    hostname = freeswitch.getGlobalVariable("hostname"),
    email_from = "noreply@" .. domain_name,
    email_to = email_to,
    email_subject = "Call Recording",
    email_body = "Call recording attached.\n\n${message_text}",
    email_uuid = uuid,
    domain_name = domain_name
})

-- insert attachment record
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
    attachment_path = file_path,
    attachment_name = file_name,
    domain_name = domain_name
})

freeswitch.consoleLog("NOTICE", "[call_recording_email] Enqueued call recording email for: " .. email_to .. "\n")