<?php

//application details
$apps[$x]['name'] = "RoboBlock";
$apps[$x]['uuid'] = "7d2ba9b9-5d66-4df4-a71e-67fe74d418a0";
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
$apps[$x]['default_settings'][$y]['default_setting_uuid'] = "be4d17e4-8dcb-48ea-8197-7012c8bbbb6b";
$apps[$x]['default_settings'][$y]['default_setting_category'] = "roboblock";
$apps[$x]['default_settings'][$y]['default_setting_subcategory'] = "greeting_file";
$apps[$x]['default_settings'][$y]['default_setting_name'] = "string";
$apps[$x]['default_settings'][$y]['default_setting_value'] = "roboblock/Roboblocker_captcha_greeting.wav";
$apps[$x]['default_settings'][$y]['default_setting_enabled'] = "false";
$apps[$x]['default_settings'][$y]['default_setting_description']['en-us'] = "Greeting WAV file to play during CAPTCHA phase.";
$y++;
$apps[$x]['default_settings'][$y]['default_setting_uuid'] = "be4417a4-8dcb-48ea-8197-7012d82bbb6b";
$apps[$x]['default_settings'][$y]['default_setting_category'] = "roboblock";
$apps[$x]['default_settings'][$y]['default_setting_subcategory'] = "is_global";
$apps[$x]['default_settings'][$y]['default_setting_name'] = "boolean";
$apps[$x]['default_settings'][$y]['default_setting_value'] = "true";
$apps[$x]['default_settings'][$y]['default_setting_enabled'] = "false";
$apps[$x]['default_settings'][$y]['default_setting_description']['en-us'] = "Whether roboblock is just for this domain or global;";

//schema
$y = 0;
$apps[$x]['db'][$y]['table']['name'] = "v_roboblock";
$apps[$x]['db'][$y]['table']['parent'] = "";

$z = 0;
$apps[$x]['db'][$y]['fields'][$z]['name'] = "roboblock_uuid";
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
$z++;
$apps[$x]['db'][$y]['fields'][$z]['name'] = "insert_date";
$apps[$x]['db'][$y]['fields'][$z]['type']['pgsql'] = 'timestamptz';
$apps[$x]['db'][$y]['fields'][$z]['type']['sqlite'] = 'date';
$apps[$x]['db'][$y]['fields'][$z]['type']['mysql'] = 'date';
$apps[$x]['db'][$y]['fields'][$z]['description']['en-us'] = "";
$z++;
$apps[$x]['db'][$y]['fields'][$z]['name'] = "update_date";
$apps[$x]['db'][$y]['fields'][$z]['type']['pgsql'] = 'timestamptz';
$apps[$x]['db'][$y]['fields'][$z]['type']['sqlite'] = 'date';
$apps[$x]['db'][$y]['fields'][$z]['type']['mysql'] = 'date';
$apps[$x]['db'][$y]['fields'][$z]['description']['en-us'] = "";
$x++;

?>