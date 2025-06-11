<?php
return [
    'default' => env('LOG_CHANNEL', 'stack'),
    'channels' => [
        'stack' => [
            'driver' => 'stack',
            'channels' => ['sentry'],
            'ignore_exceptions' => false,
        ],
        'sentry' => [
            'driver' => 'sentry',
            'level' => env('LOG_LEVEL', 'error'),
            'dsn' => env('SENTRY_LARAVEL_DSN', null),
        ],
    ],
];
