
-- roboblock.lua
-- Path: app/switch/resources/scripts/app/roboblock/roboblock.lua

local dbh = require "resources.functions.database_handle"
local log = require "resources.functions.log".roboblock
local api = freeswitch.API()

math.randomseed(os.time())

-- Get caller ID and domain UUID from session
local function get_call_info()
  local cid = session:getVariable("caller_id_number") or ""
  local domain_uuid = session:getVariable("domain_uuid") or ""
  if cid == "" then return nil, nil end
  return cid, domain_uuid
end

-- Create or fetch caller record from DB
local function get_or_create_caller(caller_id, domain_uuid)
  local sql_select = [[
    SELECT uuid, trust_percent, times_blocked, times_allowed
    FROM v_roboblock WHERE caller_id_number = :caller_id_number
  ]]
  local row = dbh:first_row(sql_select, {caller_id_number = caller_id})

  if row then
    return tonumber(row.trust_percent), tonumber(row.times_blocked), tonumber(row.times_allowed)
  else
    local new_uuid = api:execute("create_uuid")
    local sql_insert = [[
      INSERT INTO v_roboblock (uuid, domain_uuid, caller_id_number, trust_percent, times_blocked, times_allowed)
      VALUES (:uuid, :domain_uuid, :caller_id_number, 50, 0, 0)
    ]]
    dbh:query(sql_insert, {
      uuid = new_uuid,
      domain_uuid = domain_uuid,
      caller_id_number = caller_id
    })
    return 50, 0, 0
  end
end

-- Update caller record
local function update_caller(caller_id, trust, blocked, allowed)
  if trust < 0 then trust = 0 end
  if trust > 100 then trust = 100 end

  local sql_update = [[
    UPDATE v_roboblock
    SET trust_percent = :trust,
        times_blocked = :blocked,
        times_allowed = :allowed
    WHERE caller_id_number = :caller_id_number
  ]]
  dbh:query(sql_update, {
    trust = trust,
    blocked = blocked,
    allowed = allowed,
    caller_id_number = caller_id
  })
end

-- CAPTCHA Phase
local function run_captcha()
  local pin = tostring(math.random(100, 999))
  session:answer()
  session:sleep(1000)

  -- Play the greeting once
  session:streamFile("roboblock/Roboblocker_captcha_greeting.wav")

  -- Play digits BEFORE the beep
  session:streamFile("digits/" .. pin:sub(1,1) .. ".wav")
  session:streamFile("digits/" .. pin:sub(2,2) .. ".wav")
  session:streamFile("digits/" .. pin:sub(3,3) .. ".wav")

  -- Then play the beep
  session:streamFile("tone_stream://%(1000, 0, 640)")
  -- Play digits each attempt using getDigits
  for attempt = 1, 3 do
    session:streamFile("digits/" .. pin:sub(1,1) .. ".wav")
    session:streamFile("digits/" .. pin:sub(2,2) .. ".wav")
    session:streamFile("digits/" .. pin:sub(3,3) .. ".wav")
    local input = session:getDigits(3, "", 5000)
    if not input or input == "" then
      return false, "hangup"
    elseif input == pin then
      return true, nil
    end
  end

  return false, "fail"
end

-- Handle high trust caller
local function allow_call(caller_id, trust, blocked, allowed)
  allowed = allowed + 1
  update_caller(caller_id, trust, blocked, allowed)
end

-- Handle low trust caller
local function challenge_call(caller_id, trust, blocked, allowed)
  local success, reason = run_captcha()

  if success then
    allowed = allowed + 1
    if trust < 100 then trust = math.min(100, trust + 20) end
  else
    blocked = blocked + 1
    if reason == "hangup" then
      trust = trust - (5 * blocked)
    elseif reason == "fail" then
      trust = trust - 15
    end
  end

  update_caller(caller_id, trust, blocked, allowed)
end

-- Main logic
local function main()
  local caller_id, domain_uuid = get_call_info()
  if not caller_id then return end

  local trust, blocked, allowed = get_or_create_caller(caller_id, domain_uuid)

  if trust > 80 then
    allow_call(caller_id, trust, blocked, allowed)
  else
    challenge_call(caller_id, trust, blocked, allowed)
  end
end

main()