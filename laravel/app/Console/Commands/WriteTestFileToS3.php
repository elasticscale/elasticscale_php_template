<?php

namespace App\Console\Commands;

use Illuminate\Console\Command;
use Illuminate\Support\Facades\Storage;

class WriteTestFileToS3 extends Command
{
    /**
     * The name and signature of the console command.
     *
     * You will run it as: php artisan s3:test-write
     */
    protected $signature = 's3:test-write';

    /**
     * The console command description.
     */
    protected $description = 'Write a test file to the configured S3 bucket';

    /**
     * Execute the console command.
     */
    public function handle(): int
    {
        // Define file content and path
        $filePath = 'test/testfile.txt';
        $fileContent = 'This is a test file written to S3 at ' . now();

        try {
            // Write the file to S3 disk
            Storage::disk('s3')->put($filePath, $fileContent);

            $this->info("Successfully wrote file to S3: {$filePath}");
            return Command::SUCCESS;
        } catch (\Exception $e) {
            $this->error('Error writing to S3: ' . $e->getMessage());
            return Command::FAILURE;
        }
    }
}
