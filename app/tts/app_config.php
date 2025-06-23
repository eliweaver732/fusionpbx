<?php

//application details
$apps[$x]['name'] = "Text to Speech";
$apps[$x]['uuid'] = "a9f1e3b4-2c9a-48f9-88b0-6dcd74e3a7b5";
$apps[$x]['category'] = "Applications";
$apps[$x]['subcategory'] = "";
$apps[$x]['version'] = "1.0";
$apps[$x]['license'] = "Mozilla Public License 1.1";
$apps[$x]['url'] = "https://github.com/fusionpbx";
$apps[$x]['description']['en-us'] = "Manage Text-to-Speech engines, API keys, and cached audio.";

//permissions
$y = 0;
$apps[$x]['permissions'][$y]['name'] = "tts_view";
$apps[$x]['permissions'][$y]['groups'][] = "superadmin";
$y++;
$apps[$x]['permissions'][$y]['name'] = "tts_add";
$apps[$x]['permissions'][$y]['groups'][] = "superadmin";
$y++;
$apps[$x]['permissions'][$y]['name'] = "tts_edit";
$apps[$x]['permissions'][$y]['groups'][] = "superadmin";
$y++;
$apps[$x]['permissions'][$y]['name'] = "tts_delete";
$apps[$x]['permissions'][$y]['groups'][] = "superadmin";

//default settings
$y = 0;
$apps[$x]['default_settings'][$y]['default_setting_uuid'] = "b6d3f8e4-1b2c-4c45-85a4-1a2b3c4d5e6f";
$apps[$x]['default_settings'][$y]['default_setting_category'] = "TTS";
$apps[$x]['default_settings'][$y]['default_setting_subcategory'] = "default_audio_path";
$apps[$x]['default_settings'][$y]['default_setting_name'] = "string";
$apps[$x]['default_settings'][$y]['default_setting_value'] = "/tmp/tts_audio/";
$apps[$x]['default_settings'][$y]['default_setting_enabled'] = "true";
$apps[$x]['default_settings'][$y]['default_setting_description']['en-us'] = "Default directory to store TTS audio files.";

//schema
$y = 0;
$apps[$x]['db'][$y]['table']['name'] = "v_tts_settings";
$apps[$x]['db'][$y]['table']['parent'] = "";

$z = 0;
$apps[$x]['db'][$y]['fields'][$z]['name'] = "tts_setting_uuid";
$apps[$x]['db'][$y]['fields'][$z]['type'] = "uuid";
$apps[$x]['db'][$y]['fields'][$z]['key']['type'] = "primary";
$z++;
$apps[$x]['db'][$y]['fields'][$z]['name'] = "domain_uuid";
$apps[$x]['db'][$y]['fields'][$z]['type'] = "uuid";
$apps[$x]['db'][$y]['fields'][$z]['key']['type'] = "foreign";
$z++;
$apps[$x]['db'][$y]['fields'][$z]['name'] = "engine_type";
$apps[$x]['db'][$y]['fields'][$z]['type'] = "text";
$apps[$x]['db'][$y]['fields'][$z]['default'] = "espeak";
$z++;
$apps[$x]['db'][$y]['fields'][$z]['name'] = "api_key";
$apps[$x]['db'][$y]['fields'][$z]['type'] = "text";
$z++;
$apps[$x]['db'][$y]['fields'][$z]['name'] = "language";
$apps[$x]['db'][$y]['fields'][$z]['type'] = "text";
$z++;
$apps[$x]['db'][$y]['fields'][$z]['name'] = "voice";
$apps[$x]['db'][$y]['fields'][$z]['type'] = "text";
$z++;
$apps[$x]['db'][$y]['fields'][$z]['name'] = "speed";
$apps[$x]['db'][$y]['fields'][$z]['type'] = "numeric";
$z++;
$apps[$x]['db'][$y]['fields'][$z]['name'] = "audio_path";
$apps[$x]['db'][$y]['fields'][$z]['type'] = "text";

$y++;
$apps[$x]['db'][$y]['table']['name'] = "v_tts_audio_cache";
$apps[$x]['db'][$y]['table']['parent'] = "";

$z = 0;
$apps[$x]['db'][$y]['fields'][$z]['name'] = "tts_audio_uuid";
$apps[$x]['db'][$y]['fields'][$z]['type'] = "uuid";
$apps[$x]['db'][$y]['fields'][$z]['key']['type'] = "primary";
$z++;
$apps[$x]['db'][$y]['fields'][$z]['name'] = "tts_setting_uuid";
$apps[$x]['db'][$y]['fields'][$z]['type'] = "uuid";
$apps[$x]['db'][$y]['fields'][$z]['key']['type'] = "foreign";
$z++;
$apps[$x]['db'][$y]['fields'][$z]['name'] = "text_hash";
$apps[$x]['db'][$y]['fields'][$z]['type'] = "text";
$z++;
$apps[$x]['db'][$y]['fields'][$z]['name'] = "audio_file";
$apps[$x]['db'][$y]['fields'][$z]['type'] = "text";

$x++;

?>
