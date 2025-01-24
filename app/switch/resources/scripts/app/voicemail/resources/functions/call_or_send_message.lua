--	Part of FusionPBX - Central Phone addon
--	Copyright (C) 2025 Eli S Weaver <eli@weaverenterprise.net>
--	All rights reserved.
--
--	Redistribution and use in source and binary forms, with or without
--	modification, are permitted provided that the following conditions are met:
--
--	1. Redistributions of source code must retain the above copyright notice,
--	  this list of conditions and the following disclaimer.
--
--	2. Redistributions in binary form must reproduce the above copyright
--	  notice, this list of conditions and the following disclaimer in the
--	  documentation and/or other materials provided with the distribution.
--
--	THIS SOFTWARE IS PROVIDED ``AS IS'' AND ANY EXPRESS OR IMPLIED WARRANTIES,
--	INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY
--	AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE
--	AUTHOR BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY,
--	OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
--	SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
--	INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
--	CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
--	ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
--	POSSIBILITY OF SUCH DAMAGE.

-- call a phone number or a voicemail
    function call_or_send_message(destination)
        if (destination ~= nil) then
            return_call(destination);
            return;
        end

    --flush dtmf digits from the input buffer
		session:flushDigits();

    --request the destination
        if (session:ready()) then
            dtmf_digits = '';
            destination = session:playAndGetDigits(1, 20, max_tries, digit_timeout, "#", "phrase:voicemail_forward_message_enter_extension:#", "", "\\d+");
            if (session:ready()) then
                if (string.len(destination) == 0) then
                    dtmf_digits = '';
                    destination = session:playAndGetDigits(1, 20, max_tries, digit_timeout, "#", "phrase:voicemail_forward_message_enter_extension:#", "", "\\d+");
                end
            end
        end
        if (session:ready()) then
            if (string.len(destination) == 0) then
                dtmf_digits = '';
                destination = session:playAndGetDigits(1, 20, max_tries, digit_timeout, "#", "phrase:voicemail_forward_message_enter_extension:#", "", "\\d+");
            end
        end
    
    --confirm the destination
        if (session:ready()) then
            if (string.len(destination) > 3) then
                dtmf_digits = session:playAndGetDigits(1, 1, 1, 3000, "#", "phrase:voicemail_say_number:" .. destination, "", "\\d+")
            end
        end

        if (dtmf_digits == "1") then
            return_call(destination);
            return;
        else
            call_or_send_message();
        end
    end
