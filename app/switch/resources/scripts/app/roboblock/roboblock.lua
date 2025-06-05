
-- roboblock.lua
-- Path: /var/www/fusionpbx/app/switch/resources/scripts/app/roboblock/roboblock.lua

local dbh = require "resources.functions.database_handle"
local uuid = require "resources.functions.uuid"
local log = require "resources.functions.log".roboblock

math.randomseed(os.time())

-- Get caller ID from session
local function get_caller_id()
  local cid = session:getVariable("caller_id_number") or ""
  return cid ~= "" and cid or nil
end

-- Create or fetch caller record from DB
local function get_or_create_caller(caller_id)
  local sql_select = [[
    SELECT id, trust_percent, times_blocked, times_allowed
    FROM roboblock_callers WHERE caller_id_number = :caller_id_number
  ]]
  local row = dbh:first_row(sql_select, {caller_id_number = caller_id})

  if row then
    return tonumber(row.trust_percent), tonumber(row.times_blocked), tonumber(row.times_allowed)
  else
    local new_id = uuid()
    local sql_insert = [[
      INSERT INTO roboblock_callers (id, caller_id_number, trust_percent, times_blocked, times_allowed)
      VALUES (:id, :caller_id_number, 50, 0, 0)
    ]]
    dbh:query(sql_insert, {id = new_id, caller_id_number = caller_id})
    return 50, 0, 0
  end
end

-- Update caller record
local function update_caller(caller_id, trust, blocked, allowed)
  if trust < 0 then trust = 0 end
  if trust > 100 then trust = 100 end

  local sql_update = [[
    UPDATE roboblock_callers
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

-- CAPTCHA Phase using playAndGetDigits
local function run_captcha()
  local pin = tostring(math.random(100, 999))
  session:answer()
  session:sleep(1000)

  local prompt = table.concat({
    "ivr/ivr-please_enter_the_following_digits.wav",
    "digits/" .. pin:sub(1,1) .. ".wav",
    "digits/" .. pin:sub(2,2) .. ".wav",
    "digits/" .. pin:sub(3,3) .. ".wav",
    "ivr/ivr-followed_by_the_pound_key.wav"
  }, "!")

  for attempt = 1, 3 do
    local input = session:playAndGetDigits(3, 3, 1, 5000, "#", prompt, "", "\\d+")
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
  local caller_id = get_caller_id()
  if not caller_id then return end

  local trust, blocked, allowed = get_or_create_caller(caller_id)

  if trust > 80 then
    allow_call(caller_id, trust, blocked, allowed)
  else
    challenge_call(caller_id, trust, blocked, allowed)
  end
end

main()