<?php

//application details
$apps[$x]['name'] = "TTS Manager";
$apps[$x]['uuid'] = "f2c7a7b4-c4e0-48fd-85fd-d7608b2c1f99";
$apps[$x]['category'] = "Media";
$apps[$x]['subcategory'] = "";
$apps[$x]['version'] = "1.0";
$apps[$x]['license'] = "Mozilla Public License 1.1";
$apps[$x]['url'] = "https://github.com/fusionpbx";
$apps[$x]['description']['en-us'] = "Manages text-to-speech configuration and audio file caching.";

//schema for v_tts_settings
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
$apps[$x]['db'][$y]['fields'][$z]['default'] = "openai";
$z++;
$apps[$x]['db'][$y]['fields'][$z]['name'] = "language";
$apps[$x]['db'][$y]['fields'][$z]['type'] = "text";
$apps[$x]['db'][$y]['fields'][$z]['default'] = "en-us";
$z++;
$apps[$x]['db'][$y]['fields'][$z]['name'] = "voice";
$apps[$x]['db'][$y]['fields'][$z]['type'] = "text";
$apps[$x]['db'][$y]['fields'][$z]['default'] = "default";
$z++;
$apps[$x]['db'][$y]['fields'][$z]['name'] = "speed";
$apps[$x]['db'][$y]['fields'][$z]['type'] = "numeric";
$apps[$x]['db'][$y]['fields'][$z]['default'] = "140";
$z++;
$apps[$x]['db'][$y]['fields'][$z]['name'] = "sample_rate";
$apps[$x]['db'][$y]['fields'][$z]['type'] = "numeric";
$apps[$x]['db'][$y]['fields'][$z]['default'] = "8000";
$z++;
$apps[$x]['db'][$y]['fields'][$z]['name'] = "date_created";
$apps[$x]['db'][$y]['fields'][$z]['type'] = "timestamp";
$apps[$x]['db'][$y]['fields'][$z]['default'] = "now()";
$z++;
$apps[$x]['db'][$y]['fields'][$z]['name'] = "date_updated";
$apps[$x]['db'][$y]['fields'][$z]['type'] = "timestamp";
$apps[$x]['db'][$y]['fields'][$z]['default'] = "now()";

//schema for v_tts_audio_cache
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
$apps[$x]['db'][$y]['fields'][$z]['name'] = "domain_uuid";
$apps[$x]['db'][$y]['fields'][$z]['type'] = "uuid";
$z++;
$apps[$x]['db'][$y]['fields'][$z]['name'] = "text";
$apps[$x]['db'][$y]['fields'][$z]['type'] = "text";
$z++;
$apps[$x]['db'][$y]['fields'][$z]['name'] = "text_hash";
$apps[$x]['db'][$y]['fields'][$z]['type'] = "text";
$z++;
$apps[$x]['db'][$y]['fields'][$z]['name'] = "audio_file";
$apps[$x]['db'][$y]['fields'][$z]['type'] = "text";
$z++;
$apps[$x]['db'][$y]['fields'][$z]['name'] = "voice";
$apps[$x]['db'][$y]['fields'][$z]['type'] = "text";
$z++;
$apps[$x]['db'][$y]['fields'][$z]['name'] = "language";
$apps[$x]['db'][$y]['fields'][$z]['type'] = "text";
$z++;
$apps[$x]['db'][$y]['fields'][$z]['name'] = "speed";
$apps[$x]['db'][$y]['fields'][$z]['type'] = "numeric";
$z++;
$apps[$x]['db'][$y]['fields'][$z]['name'] = "engine_type";
$apps[$x]['db'][$y]['fields'][$z]['type'] = "text";
$z++;
$apps[$x]['db'][$y]['fields'][$z]['name'] = "sample_rate";
$apps[$x]['db'][$y]['fields'][$z]['type'] = "numeric";
$z++;
$apps[$x]['db'][$y]['fields'][$z]['name'] = "date_created";
$apps[$x]['db'][$y]['fields'][$z]['type'] = "timestamp";
$apps[$x]['db'][$y]['fields'][$z]['default'] = "now()";
$z++;
$apps[$x]['db'][$y]['fields'][$z]['name'] = "date_accessed";
$apps[$x]['db'][$y]['fields'][$z]['type'] = "timestamp";
$apps[$x]['db'][$y]['fields'][$z]['default'] = "now()";

$x++;