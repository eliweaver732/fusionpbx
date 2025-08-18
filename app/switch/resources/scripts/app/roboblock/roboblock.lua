
-- roboblock.lua
-- Path: app/switch/resources/scripts/app/roboblock/roboblock.lua

Database = require "resources.functions.database"
local log = require "resources.functions.log".roboblock
local api = freeswitch.API()
require "resources.functions.settings";

domain_uuid = session:getVariable("domain_uuid");
dbh = Database.new('system');
settings = settings(domain_uuid);
is_global = true;
if (settings['roboblock'] ~= nil) then
  if (settings['roboblock']['is_global']['boolean'] ~= nil) then
    is_global = settings['roboblock']['is_global']['boolean'];
  end
  if (settings['switch']['roboblock']['greeting_file'] ~= nil) then
    greeting_file = settings['switch']['roboblock']['greeting_file'];
  end
end

math.randomseed(os.time())

-- Get caller ID and domain UUID from session
local function get_call_info()
  local cid = session:getVariable("caller_id_number") or ""
  if (cid == nil or string.len(cid) < 10) then
    caller_id_number = string.match(session:getVariable("caller_id"), '<(%d+)>')
  end
  if (cid == "" or cid == nil) then return nil end
  
  --add USA country code to 10 digit cid
  if (string.len(cid) == 10 and string.sub(cid, 1, 1) ~= "1") then
    cid = "1" .. cid
  end
  return cid
end

-- Create or fetch caller record from DB
local function get_or_create_caller(caller_id, domain_uuid)
  if not (is_global) then
    local sql_select = [[
      SELECT uuid, trust_percent, times_blocked, times_allowed
      FROM v_roboblock WHERE caller_id_number = :caller_id_number
      AND domain_uuid = :domain_uuid
    ]]
  else
    local sql_select = [[
      SELECT uuid, trust_percent, times_blocked, times_allowed
      FROM v_roboblock WHERE caller_id_number = :caller_id_number
      AND domain_uuid IS NULL
    ]]
  end

  dbh:query(sql_select, {caller_id_number = caller_id, domain_uuid = domain_uuid}, function(row)
    result = row;
  end);

  if result then
    return tonumber(result.trust_percent), tonumber(result.times_blocked), tonumber(result.times_allowed)
  else
    local new_uuid = api:execute("create_uuid")
    if (is_global) then
      local sql_insert = [[
        INSERT INTO v_roboblock (uuid, caller_id_number, trust_percent, times_blocked, times_allowed, insert_date)
        VALUES (:uuid, :caller_id_number, 50, 0, 0, now())
      ]]
    else
      local sql_insert = [[
        INSERT INTO v_roboblock (uuid, domain_uuid, caller_id_number, trust_percent, times_blocked, times_allowed, insert_date)
        VALUES (:uuid, :domain_uuid, :caller_id_number, 50, 0, 0, now())
      ]]
    end
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

  if (is_global) then
    local sql_update = [[
      UPDATE v_roboblock
      SET trust_percent = :trust,
          times_blocked = :blocked,
          times_allowed = :allowed,
          update_date = now()
      WHERE caller_id_number = :caller_id_number 
      AND domain_uuid IS NULL
    ]]
  else
    local sql_update = [[
      UPDATE v_roboblock
      SET trust_percent = :trust,
          times_blocked = :blocked,
          times_allowed = :allowed,
          update_date = now()
      WHERE caller_id_number = :caller_id_number 
      AND domain_uuid = :domain_uuid
    ]]
  dbh:query(sql_update, {
    domain_uuid = domain_uuid,
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

  --if trust is too low simply hangup
  if (trust <= 20) then
    session:hangup()
    return false, "hangup"
  end

  -- Play the greeting once
  if (greeting_file == nil or string.len(greeting_file) == 0) then
    greeting_file = "roboblock/Roboblocker_captcha_greeting.wav"
  end

  session:streamFile(greeting_file)

  -- Play digits BEFORE the beep
  session:streamFile("digits/" .. pin:sub(1,1) .. ".wav")
  session:streamFile("digits/" .. pin:sub(2,2) .. ".wav")
  session:streamFile("digits/" .. pin:sub(3,3) .. ".wav")

  -- Then play the beep
  session:streamFile("tone_stream://%(1000, 0, 640)")
  
  local input = session:getDigits(3, "", 10000)
  if not (session:ready()) then
    return false, "hangup"
  elseif (not input or input == "") then
    return false, "fail"
  elseif (input == pin) then
    return true, nil
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

    --hangup the call as the default blocking procedure
    if (session:ready()) then
      session:hangup()
    end
  end

  update_caller(caller_id, trust, blocked, allowed)
end

local function get_phone_number()
  if (session:ready()) then
  --flush dtmf digits from the input buffer
    session:flushDigits();
  --set phone_number valitity in case of hangup
    valid_phone_number = "false";
    dtmf_digits = '';
    timeouts = 0;
    dtmf_digits = session:playAndGetDigits(11, 11, 3, 5000, "#", "phrase:voicemail_enter_phone_number", "", "\\d+|\\*");

    if (session:ready()) then
      if (string.len(dtmf_digits) == 11) then
        if (string.sub( dtmf_digits, 2, 2 ) ~= "1") then
          if (string.sub( dtmf_digits, 5, 5 ) ~= "1") then
            valid_phone_number = "true";
          end
        end
      end
    end
      
    if (valid_phone_number == "true") then 
      return dtmf_digits;
    else
      session:hangup();
      return
    end
  end
end

--logic starts here
--arg[2] always overrides session info
if (arg[2]) then
  if (string.len(arg[2]) == 10 and string.sub(arg[2], 1, 1) ~= "1") then
    caller_id = "1" .. arg[2]
  elseif (arg[2] ~= nil) then
    if not (string.len(arg[2]) == 11) then
      session:hangup()
      return
    end
  end
else
  if (session:ready()) then
    caller_id = get_call_info()
  end
end

-- USAGE: "roboblock.lua block 1234567890"
-- soft blocks this number until it verifies again
if (arg and arg[1] == "block" and arg[2]) then
  trust, blocked, allowed = get_or_create_caller(caller_id, domain_uuid)
  update_caller(arg[2], 70, blocked + 1, allowed)

-- USAGE: "roboblock.lua allow 1234567890"
-- allows this number to call through
elseif (arg and arg[1] == "allow" and arg[2]) then
  trust, blocked, allowed = get_or_create_caller(caller_id, domain_uuid)
  update_caller(arg[2], 80, blocked, allowed)

-- USAGE: "roboblock.lua allow"
-- requests a number to allow through
elseif (arg and arg[1] == "allow" and not arg[2]) then
  caller_id = get_phone_number()
  trust, blocked, allowed = get_or_create_caller(caller_id, domain_uuid)
  if (string.len(caller_id) > 9) then
    update_caller(caller_id, 80, blocked, allowed);
  end

-- USAGE: "roboblock.lua reset 1234567890"
-- resets a callers trust to 50%
elseif (arg and arg[1] == "reset" and arg[2]) then
  trust, blocked, allowed = get_or_create_caller(caller_id, domain_uuid)
  update_caller(arg[2], 50, 0, 0)

elseif (arg and arg[1] == "update") then
  -- not implemented
  trust, blocked, allowed = get_or_create_caller(1234567890, domain_uuid)

-- USAGE: "roboblock.lua"
-- send to here from dialplan to do auth on current caller
else
  if (session:ready()) then
    trust, blocked, allowed = get_or_create_caller(caller_id, domain_uuid)
    if trust > 80 then
      allow_call(caller_id, trust, blocked, allowed)
    else
      challenge_call(caller_id, trust, blocked, allowed)
    end
  end
end
