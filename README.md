# Laravel Stateless Template

Welcome to the **Laravel Stateless Template**! This repository provides a flexible, production-ready Docker-based setup for developing and deploying a Laravel application. Designed for beginners and advanced users alike, it ensures consistency between development and production environments while keeping configurations stateless. Follow this guide to get started, manage your project, and extend it as needed.

## Directory Structure

Below is the directory structure and the purpose of each file/directory:

- **`laravel/`**: This is where the Laravel project is initialized. The `setup.sh` script populates it with a fresh Laravel app on first run.
- **`config-stateless/`**: Contains stateless configuration files (e.g., `app.php`, `logging.php`) that override Laravel's defaults. Copied to `laravel/config/` during setup for flexible, environment-agnostic settings.
- **`.env.example`**: A template for the `.env` file, defining environment variables (e.g., database, Redis, AWS) for local development. Copy to `.env` and customize as needed.
- **`setup.sh`**: A script that runs post-container creation to initialize a new Laravel project, set permissions, copy configs, and validate connections (e.g., Redis, MySQL).
- **`Dockerfile`**: Defines the container image for the PHP application (using `php:8.3.7-apache`). Used for both dev and prod to ensure consistency.
- **`docker-compose.yml`**: Configures services (PHP, MySQL, phpMyAdmin, LocalStack, Redis) for local development, with ports and volumes for easy access.

## Getting Started

### First-Time Setup
1. **Clone the Repository**
   ```bash
   git clone <your-repo-url> my-laravel-project
   cd my-laravel-project
   ```
2. **Copy .env.example**
   - Create your `.env` file:
     ```bash
     cp .env.example .env
     ```
   - Review and customize `.env` (e.g., `DB_DATABASE`, `REDIS_HOST`, etc.) if needed.
3. **Run Docker Compose**
   - Build and start the services:
     ```bash
     docker compose --project-name laravel_template -f docker-compose.yml up --build
     ```
   - This builds the PHP app image, starts MySQL, Redis, phpMyAdmin, and LocalStack, and runs `setup.sh` to initialize the Laravel project.
4. **Check Setup Log**
   - If setup fails, inspect the log:
     ```bash
     docker exec -it laravel_template-app-1 cat /tmp/setup.log
     ```
   - Look for errors (e.g., Redis or MySQL connection issues) and ensure "Setup completed successfully" appears.
5. **Access the App**
   - Open `http://localhost:8000` in your browser to see the Laravel welcome page.

### Subsequent Use
- **Start the Project**
  - If the `laravel` directory already contains `composer.json` and `artisan`, `setup.sh` skips initialization to preserve your existing project:
    ```bash
    docker compose --project-name laravel_template -f docker-compose.yml up
    ```
- **Check Logs**
  - Always review `/tmp/setup.log` inside the container for issues:
    ```bash
    docker exec -it laravel_template-app-1 cat /tmp/setup.log
    ```

## Resetting the Laravel Project
To start fresh (e.g., for testing or a new project):
1. **Stop Containers**
   ```bash
   docker compose --project-name laravel_template -f docker-compose.yml down
   ```
2. **Clear the laravel Directory**
   - Remove all contents:
     ```bash
     rm -rf laravel/* laravel/.[!.]* laravel/..?*
     ```
   - This mimics the `setup.sh` cleanup, ensuring a new Laravel project is created.
3. **Rebuild and Run**
   ```bash
   docker compose --project-name laravel_template -f docker-compose.yml up --build
   ```
   - The `setup.sh` script will detect the empty directory and run `composer create-project` to initialize a new Laravel app.

## What’s Kept vs. What’s Not
- **Kept Across Container Restarts/Rebuilds**:
  - **Logs**: Stored in `laravel/storage/logs/`, persisted via the `log-volume` in `docker-compose.yml`. Survives restarts and rebuilds.
  - **Database**: MySQL data is saved in the `db-data` volume.
  - **Redis Data**: Persisted in the `redis-data` volume.
  - **LocalStack Data**: Stored in the `localstack-data` volume for S3 simulation.
  - **Existing Laravel Project**: If `composer.json` and `artisan` exist in `laravel/`, `setup.sh` skips initialization to preserve your work.
- **Not Kept**:
  - Files in `laravel/` are not tracked by Git (per `.gitignore`) and may be lost if you delete the local directory.
  - Temporary setup logs (`/tmp/setup.log`) are cleared on container rebuild.
  - Vendor files (`vendor/`) are ignored by Git and reinstalled by Composer as needed.

## Dev and Prod Consistency
- The same `Dockerfile` is used for both development and production to ensure consistency in PHP version, dependencies, and Apache setup.
- **Splitting for Dev/Prod**: At your discretion, create a separate `Dockerfile.dev` for development (e.g., with extra tools) and place it in `.devcontainer/`. Update `devcontainer.json` to use it:
  ```json
  "build": {
    "context": ".",
    "dockerfile": ".devcontainer/Dockerfile.dev"
  }
  ```
  - Keep the original `Dockerfile` for production builds.

## Stateless Configuration
This template uses stateless configs in `config-stateless/` to decouple settings from the environment. These are copied to `laravel/config/` during setup. Here’s how it works, using logging as an example:

- **Logging Example** (`config/logging.php`):
  ```php
  return [
      'default' => env('LOG_CHANNEL', 'stack'),
      'channels' => [
          'stack' => [
              'driver' => 'stack',
              'channels' => ['daily', 'sentry'],
              'ignore_exceptions' => false,
          ],
          'daily' => [
              'driver' => 'daily',
              'path' => env('LOG_PATH', storage_path('logs/laravel.log')),
              'level' => env('LOG_LEVEL', 'debug'),
              'days' => 14,
          ],
          'sentry' => [
              'driver' => 'sentry',
              'level' => env('LOG_LEVEL', 'error'),
              'dsn' => env('SENTRY_LARAVEL_DSN', null),
          ],
      ],
  ];
  ```
- **How It’s Stateless**:
  - Values like `LOG_CHANNEL`, `LOG_PATH`, and `LOG_LEVEL` are pulled from the `.env` file using the `env()` helper, making the config independent of hardcoded paths or settings.
- **Dev vs. Prod Logging**:
  - **Development**:
    - In `.env`:
      ```env
      LOG_CHANNEL=stack
      LOG_PATH=storage/logs/laravel.log
      LOG_LEVEL=debug
      SENTRY_LARAVEL_DSN=
      ```
    - Logs to `laravel/storage/logs/laravel.log` at `debug` level, no Sentry.
  - **Production**:
    - In `.env`:
      ```env
      LOG_CHANNEL=stack
      LOG_PATH=/var/log/laravel/laravel.log
      LOG_LEVEL=error
      SENTRY_LARAVEL_DSN=https://your-sentry-dsn@sentry.io/12345
      ```
    - Logs errors to a custom path and sends to Sentry for monitoring.
- **Other Stateless Configs**:
  - Similar logic applies to `cache.php`, `database.php`, `filesystems.php`, `queue.php`, `session.php`, etc. Define settings in `.env` (e.g., `CACHE_DRIVER=redis`, `DB_HOST=db`) to control behavior across environments.

## Testing the Project
Once the project is running:
1. **Access the App**
   - Open `http://localhost:8000` to see the Laravel welcome page.
2. **Check Database**
   - Use phpMyAdmin at `http://localhost:8080`:
     - Host: `db`
     - User: `root`
     - Password: `root`
     - Verify the `laravel` database and tables from migrations.
3. **Test Redis**
   - Run in the container:
     ```bash
     docker exec -it laravel_template-app-1 bash
     php artisan cache:put test_key "Hello, Redis!" 3600
     php artisan cache:get test_key
     ```
     - Should output: `Hello, Redis!`
4. **Check Logs**
   - View logs in the container:
     ```bash
     docker exec -it laravel_template-app-1 cat /var/www/laravel/storage/logs/laravel.log
     ```
5. **Test S3 (LocalStack)**
   - Use AWS CLI to test the S3 bucket:
     ```bash
     docker exec -it laravel_template-app-1 bash
     aws --endpoint-url=http://localstack:4566 s3 mb s3://local-bucket
     aws --endpoint-url=http://localstack:4566 s3 ls
     ```

## Using .env for Different Environments
- The `.env` file controls environment-specific settings.
- **Steps**:
  1. Copy `.env.example` to `.env`:
     ```bash
     cp .env.example .env
     ```
  2. Edit `.env` for your environment:
     - **Development**:
       ```env
       APP_ENV=local
       APP_DEBUG=true
       DB_HOST=db
       REDIS_HOST=redis
       AWS_ENDPOINT=http://localstack:4566
       ```
     - **Production**:
       ```env
       APP_ENV=production
       APP_DEBUG=false
       DB_HOST=<your-prod-db-host>
       REDIS_HOST=<your-prod-redis-host>
       AWS_ENDPOINT=https://s3.amazonaws.com
       ```
  3. Restart the container to apply changes:
     ```bash
     docker compose --project-name laravel_template -f docker-compose.yml down
     docker compose --project-name laravel_template -f docker-compose.yml up
     ```
- **Note**: Never commit `.env` to Git (it’s ignored by `.gitignore`). Create separate `.env` files for dev, staging, prod, etc.

## Adding Additional Services to docker-compose.yml
To extend this template for development, add services to `docker-compose.yml`. Example: Adding Playwright for browser testing.

- **Example: Add Playwright**
  - Edit `docker-compose.yml` and add:
    ```yaml
    services:
      playwright:
        image: mcr.microsoft.com/playwright:latest
        environment:
          - NODE_ENV=development
        volumes:
          - ./laravel:/app
        depends_on:
          - app
        command: ["npx", "playwright", "test"]
    ```
  - **Usage**:
    1. Install Playwright in your Laravel project:
       ```bash
       docker exec -it laravel_template-app-1 bash
       cd /var/www/laravel
       composer require --dev phpunit/phpunit
       npm install playwright
       ```
    2. Create tests in `laravel/tests/Browser/`.
    3. Run tests:
       ```bash
       docker compose --project-name laravel_template -f docker-compose.yml up playwright
       ```
  - **Note**: Adjust volumes, ports, or commands based on your needs.

## Included Docker Compose Services
- **php**: The main app service, built from `Dockerfile` using `php:8.3.7-apache`. Runs Laravel at `http://localhost:8000`.
- **mysql**: MySQL 8.0 database, stores data in the `db-data` volume, accessible at port `3306`.
- **phpmyadmin**: A web interface for MySQL management, available at `http://localhost:8080` (user: `root`, password: `root`).
- **localstack**: Simulates AWS services (e.g., S3) for local testing, accessible at `http://localhost:4566`.
- **redis**: Redis 7.0 for caching, sessions, and queues, persisted via the `redis-data` volume, on port `6379`.

## Production Readiness
This template is designed to be production-ready:
- **Non-Root User**: The `Dockerfile` sets permissions for `www-data` (Apache’s user) on `/var/www/laravel`, reducing security risks.
- **Stateless Configs**: Settings in `config-stateless/` use `.env` for flexibility across environments.
- **Persisted Data**: Volumes (`db-data`, `redis-data`, `log-volume`) ensure data survives container restarts.
- **Consistent Build**: The same `Dockerfile` works for dev and prod, ensuring identical PHP and Apache setups.
- **Security**: `mod_rewrite` is enabled, and permissions are set (e.g., `775` for storage) to balance access and safety.
- **Scalability**: Ready for deployment to AWS ECS (see GitHub Pipeline below).

## GitHub Pipeline for Deployment
A GitHub Actions pipeline can build the Docker image and push it to AWS Elastic Container Registry (ECR) for deployment to ECS:
1. **Setup OpenID Connect (OIDC)**:
   - Configure your Git weerHub repo to use OIDC with AWS.
   - In AWS IAM, create a role (e.g., `ecs-deploy-role`) with permissions for ECR (`ecr:PutImage`, `ecr:GetAuthorizationToken`) and ECS.
   - Link the role to GitHub via OIDC (trust relationship for your repo).
2. **Sample Workflow** (`.github/workflows/deploy.yml`):
   ```yaml
   name: Build and Deploy to ECR
   on:
     push:
       branches: [ main ]
   jobs:
     build-and-push:
       runs-on: ubuntu-latest
       permissions:
         id-token: write
         contents: read
       steps:
         - name: Checkout code
           uses: actions/checkout@v4
         - name: Configure AWS credentials
           uses: aws-actions/configure-aws-credentials@v4
           with:
             role-to-assume: arn:aws:iam::<account-id>:role/ecs-deploy-role
             aws-region: us-east-1
         - name: Login to Amazon ECR
           uses: aws-actions/amazon-ecr-login@v2
         - name: Build, tag, and push image to ECR
           env:
             ECR_REGISTRY: <account-id>.dkr.ecr.us-east-1.amazonaws.com
             ECR_REPOSITORY: laravel-app
             IMAGE_TAG: ${{ github.sha }}
           run: |
             docker build -t $ECR_REGISTRY/$ECR_REPOSITORY:$IMAGE_TAG .
             docker push $ECR_REGISTRY/$ECR_REPOSITORY:$IMAGE_TAG
   ```
3. **Deploy to ECS**:
   - Update your ECS task definition to use the pushed image (e.g., `<account-id>.dkr.ecr.us-east-1.amazonaws.com/laravel-app:<sha>`).
   - Deploy via AWS CLI or a separate step in the workflow:
     ```bash
     aws ecs update-service --cluster my-cluster --service my-service --force-new-deployment
     ```
4. **Note**: Replace `<account-id>`, `us-east-1`, and other values with your AWS setup.

## Additional Tips
- **Beginner-Friendly**:
  - All commands are run from the repo root.
  - Use `docker compose logs` to debug issues (e.g., `docker compose --project-name laravel_template logs app`).
  - If setup fails, check `/tmp/setup.log` in the `app` container for clues.
- **Customization**:
  - Add dependencies in the `Dockerfile` (e.g., `RUN apt-get install -y <package>`).
  - Extend `config-stateless/` for custom app logic.
- **Need Help?**:
  - If a step fails, share `/tmp/setup.log` or specific config files (e.g., `config-stateless/logging.php`) with your team or support.

## Questions?
If anything’s unclear or you need the contents of files (e.g., `config-stateless/app.php`, `setup.sh`), feel free to ask! This template is designed to be simple, flexible, and ready for both beginners and pros. Happy coding!