<?php
return array (
  'cache' => 
  array (
    'value' => 
    array (
      'type' => 'redis',
      'host' => '10.0.1.210',
      'port' => 6379,
      'password' => 'B1tr1x_R3d1s_S3cur3_P@ssw0rd_2026!',
    ),
  ),
  'session' => 
  array (
    'value' => 
    array (
      'mode' => 'default',
      'check_ip' => false,
      'check_ua' => false,
      'handlers' => 
      array (
        'general' => 
        array (
          'type' => 'redis',
          'host' => '10.0.1.210',
          'port' => 6379,
          'password' => 'B1tr1x_R3d1s_S3cur3_P@ssw0rd_2026!',
        ),
      ),
    ),
  ),
  'connections' => 
  array (
    'value' => 
    array (
      'default' => 
      array (
        'host' => '10.0.1.200',
        'database' => 'prostory',
        'login' => 'bitrix',
        'password' => 'S0m3_Str0ng_Pass!',
        'options' => 2,
        'className' => '\\Bitrix\\Main\\DB\\MysqliConnection',
      ),
    ),
    'readonly' => true,
  ),
  'pull' => 
  array (
    'value' => 
    array (
      'default' => 'websocket',
      'publishing_mode' => 'immediate',
      'path_to_listener' => 'https://b24.ahprostory.ru/bitrix/sub/',
      'path_to_listener_secure' => 'https://b24.ahprostory.ru/bitrix/sub/',
      'path_to_modern_listener' => 'https://b24.ahprostory.ru/bitrix/sub/',
      'path_to_modern_listener_secure' => 'https://b24.ahprostory.ru/bitrix/sub/',
      'path_to_mobile_listener' => 'https://b24.ahprostory.ru/bitrix/sub/',
      'path_to_mobile_listener_secure' => 'https://b24.ahprostory.ru/bitrix/sub/',
      'path_to_publish' => 'http://10.0.1.230:8895/bitrix/pub/',
      'websocket' => 
      array (
        'enabled' => true,
        'host' => 'b24.ahprostory.ru',
        'port' => 443,
        'secure' => true,
      ),
      'signature_key' => 'azTw0fWfYZeOU4JrzXu3UTXtcrWZePoRuAnYCNn9oKRwQIfLqmOYvqRVfJ9s1lZyj5B1L9AWDlFKgpQgX7xEa1MzEUkrkg8suA4qcQVl7UnvJwHoibkhSyvHho6kOGuE',
    ),
    'readonly' => false,
  ),
  'cache_flags' => 
  array (
    'value' => 
    array (
      'config_options' => 3600.0,
    ),
    'readonly' => false,
  ),
  'cookies' => 
  array (
    'value' => 
    array (
      'secure' => true,
      'http_only' => true,
    ),
    'readonly' => false,
  ),
  'exception_handling' => 
  array (
    'value' => 
    array (
      'debug' => false,
    ),
    'readonly' => false,
  ),
  'crypto' => 
  array (
    'value' => 
    array (
      'crypto_key' => '1ae2c326ae753ac5bb2443c20305a477',
    ),
    'readonly' => true,
  ),
  'web_server_name' => 
  array (
    'value' => 'b24.ahprostory.ru',
    'readonly' => false,
  ),
);