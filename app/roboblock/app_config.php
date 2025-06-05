<?php

//application details
$apps[$x]['name'] = "RoboBlock";
$apps[$x]['uuid'] = "f51d2f40-8d30-4b2f-9f14-2e8caa5b0d12";
$apps[$x]['category'] = "Security";
$apps[$x]['subcategory'] = "";
$apps[$x]['version'] = "1.0";
$apps[$x]['license'] = "Mozilla Public License 1.1";
$apps[$x]['url'] = "https://github.com/fusionpbx";
$apps[$x]['description']['en-us'] = "Block robocallers using a trust score and audio CAPTCHA.";

//permissions (optional placeholder)
$y = 0;
$apps[$x]['permissions'][$y]['name'] = "roboblock_view";
$apps[$x]['permissions'][$y]['groups'][] = "superadmin";
$y++;
$apps[$x]['permissions'][$y]['name'] = "roboblock_add";
$apps[$x]['permissions'][$y]['groups'][] = "superadmin";
$y++;
$apps[$x]['permissions'][$y]['name'] = "roboblock_edit";
$apps[$x]['permissions'][$y]['groups'][] = "superadmin";
$y++;
$apps[$x]['permissions'][$y]['name'] = "roboblock_delete";
$apps[$x]['permissions'][$y]['groups'][] = "superadmin";

//default settings
$y = 0;
$apps[$x]['default_settings'][$y]['default_setting_uuid'] = "b42c00d0-0c9c-4a3d-8f7e-roboblockgreetfile";
$apps[$x]['default_settings'][$y]['default_setting_category'] = "RoboBlock";
$apps[$x]['default_settings'][$y]['default_setting_subcategory'] = "greeting_file";
$apps[$x]['default_settings'][$y]['default_setting_name'] = "string";
$apps[$x]['default_settings'][$y]['default_setting_value'] = "";
$apps[$x]['default_settings'][$y]['default_setting_enabled'] = "false";
$apps[$x]['default_settings'][$y]['default_setting_description']['en-us'] = "Greeting WAV file to play during CAPTCHA phase.";

//schema
$y = 0;
$apps[$x]['db'][$y]['table']['name'] = "roboblock_callers";
$apps[$x]['db'][$y]['table']['parent'] = "";

$z = 0;
$apps[$x]['db'][$y]['fields'][$z]['name'] = "uuid";
$apps[$x]['db'][$y]['fields'][$z]['type'] = "uuid";
$apps[$x]['db'][$y]['fields'][$z]['key']['type'] = "primary";
$z++;
$apps[$x]['db'][$y]['fields'][$z]['name'] = "domain_uuid";
$apps[$x]['db'][$y]['fields'][$z]['type'] = "uuid";
$apps[$x]['db'][$y]['fields'][$z]['key']['type'] = "foreign";
$z++;
$apps[$x]['db'][$y]['fields'][$z]['name'] = "caller_id_number";
$apps[$x]['db'][$y]['fields'][$z]['type'] = "text";
$z++;
$apps[$x]['db'][$y]['fields'][$z]['name'] = "trust_percent";
$apps[$x]['db'][$y]['fields'][$z]['type'] = "numeric";
$z++;
$apps[$x]['db'][$y]['fields'][$z]['name'] = "times_blocked";
$apps[$x]['db'][$y]['fields'][$z]['type'] = "numeric";
$z++;
$apps[$x]['db'][$y]['fields'][$z]['name'] = "times_allowed";
$apps[$x]['db'][$y]['fields'][$z]['type'] = "numeric";

$x++;

?>