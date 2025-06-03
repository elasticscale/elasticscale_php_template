# Laravel Dockerized Template

This is a production-grade Docker template for Laravel applications running on Apache with PHP 8.3, designed to work seamlessly with Laravel Vite, non-root execution, and optimized for LocalStack and modern DevOps pipelines.

## Features

- PHP 8.3 with Apache in Debian slim
- Laravel + Vite support
- `.env` secrets injection support
- Non-root execution using `www-data`
- Composer with `--apcu-autoloader` and no dev dependencies in production
- Vite `npm run build` at image build time
- Apache `mod_rewrite`, custom ports
- Stateless containers (runtime storage + logs writeable)
- Laravel storage symlink `public/storage -> storage/app/public`
- LocalStack support (S3 etc.)
- phpMyAdmin support
- Memcached support
- Mailpit and MockServer containers
- GitHub Actions deployment to Amazon ECR via IAM OIDC

## Requirements

- Docker
- Docker Compose
- Laravel 10+
- Node.js 18+, npm
- A `.env` file

## Usage

```bash
git clone https://github.com/elasticscale/laravel-docker-template.git
cd laravel-docker-template
cp .env.example .env
docker compose up -d --build
```

### Generating Laravel Key

```bash
docker compose exec php php artisan key:generate
```

### Checking Routes

```bash
docker compose exec php php artisan route:list
```

### Testing Database Connection

You can add a quick route to test DB access:

```php
Route::get('/test-db', function () {
    \DB::statement('CREATE TABLE IF NOT EXISTS test_table (id INT AUTO_INCREMENT PRIMARY KEY, name VARCHAR(50))');
    \DB::table('test_table')->insert(['name' => 'ElasticScale']);
    return \DB::table('test_table')->get();
});
```

### Using Tinker

If `psysh` throws a permission error, make sure `$HOME` is set to a writeable directory like `/tmp`.

```Dockerfile
ENV HOME=/tmp
```

## Apache Ports

- HTTP: `8080`
- HTTPS: `8081`

## Notes

- This image uses `composer install` and `npm run build` during build time. Ensure `package.json`, `composer.lock`, and `vendor/` exist.
- Apache `DocumentRoot` is set to `/var/app/public`.
