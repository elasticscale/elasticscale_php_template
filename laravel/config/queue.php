<?php
return [
    'default' => env('QUEUE_CONNECTION', 'redis'),
    'connections' => [
        'sync' => [
            'driver' => 'sync',
        ],
        'redis' => [
            'driver' => 'redis',
            'connection' => 'default',
            'queue' => env('REDIS_QUEUE', 'default'),
            'retry_after' => 90,
            'block_for' => null,
        ],
    ],
    'failed' => [
        'driver' => 'database',
        'table' => 'failed_jobs',
        'queue' => 'failed',
    ],
];