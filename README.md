# CakePHP Docker Setup for AWS ECS Fargate

This repository provides a complete example of running a CakePHP PHP application using Docker and DevContainers, with a focus on building **stateless applications** ready for deployment on **AWS ECS Fargate**.

It includes:

* Local development with Docker Compose
* Integration with LocalStack for AWS services
* DevContainer support for VS Code
* Guidance on how to make your app Fargate-friendly (stateless and scalable)

---

## Getting Started

### 1. Install Docker

First, you need to install Docker on your local machine.

* **Mac:** [Docker Desktop for Mac](https://www.docker.com/products/docker-desktop/)
* **Windows:** [Docker Desktop for Windows](https://www.docker.com/products/docker-desktop/)
* **Linux:** Use your package manager (for example, on Ubuntu: `sudo apt install docker.io docker-compose`)

---

### 2. Change Hosts File

To make development easier, we'll use a friendly hostname instead of `localhost`.

#### Mac

```bash
sudo vim /private/etc/hosts
```

#### Windows

Edit: `C:\Windows\System32\drivers\etc\hosts` as Administrator.

#### Add the following line:

```plaintext
127.0.0.1 cakephp.test
```

**Why?**
Using `localhost` can cause strange behavior in Dockerized environments (network issues, caching problems). Using `cakephp.test` avoids these problems and works better with browsers.

---

### 3. Setup CakePHP Environment

Configure the CakePHP application.

---

### 4. Start the Application

Start your full development stack using Docker Compose:

```bash
docker compose up -d
```

This will start:

* CakePHP app container
* MySQL database
* phpMyAdmin
* LocalStack (mock AWS services)

---

### 5. Install Composer Dependencies

Enter the CakePHP app container:

```bash
docker compose exec -it app bash
```

Then install the dependencies:

```bash
composer install
```

---

### 6. Setup LocalStack S3

Inside the app container, run:

```bash
awslocal s3api create-bucket --bucket localbucket --region us-east-1
```

This will create a **mock S3 bucket** (`localbucket`) inside LocalStack for local testing.

---

### 7. Access the Application

* CakePHP app: [http://cakephp.test/](http://cakephp.test/)
* phpMyAdmin: [http://localhost:8080/](http://localhost:8080/)

---

### 8. DevContainers (Optional)

If you are using **Visual Studio Code**, you can use the built-in DevContainer for a seamless development experience:

* Open the project in VS Code.
* When prompted, reopen the project in the DevContainer.

Benefits:

* No need to manually run `docker compose exec ...` to enter the container.
* Pre-configured PHP, Composer, and AWS CLI environment.

---

## Statelessness (Why It Matters for ECS Fargate)

**ECS Fargate** runs your containers on a fully managed serverless platform. Containers can be stopped and restarted anytime, or scaled across multiple instances.
This requires your app to be **stateless**:

### Guidelines:

1. **Logging:**
   → Stream logs to **stdout** (Docker logs) or an external service (e.g. Sentry).
   → Do not write log files inside the container.

2. **File Storage:**
   → Never store files on the container filesystem. They will be lost when a container restarts.
   → Use **S3** or similar object storage.

3. **Sessions:**
   → Store user sessions in a shared, persistent system like **database** or **Redis**.
   → If sessions are file-based, users will get logged out when load-balanced to another container.

   **Example:** When using a load balancer (ALB/NLB), traffic will round-robin between containers. If session state isn't shared, users will appear logged out or lose state.

---

## Configuration

All configuration must be done using **environment variables**.

* Local development → `.env` file is fine.
* Staging/Production → must use real environment variables (do not bake configs into the image).

Why?
→ ECS Fargate uses different environments for staging/production and you must be able to deploy the same container image everywhere with different configs.

Example env variable: `APP_URL`, `DB_CONNECTION`, `AWS_REGION`, etc.

---

## Health Check

Your application should expose a simple health check endpoint:

```plaintext
/healthcheck
```

Guidelines:

* Should not perform heavy operations.
* Should not connect to the database — if the database is down, ECS would otherwise kill all your containers!
* Simple response: `200 OK`, no dependencies.

---

## AWS LocalStack

For local AWS service testing, this project uses **LocalStack**.

Inside the container you can use:

```bash
awslocal s3api ...
```

In production on ECS Fargate:

* Do not use **AWS access keys/secrets** inside your app container.
* Instead, use an **ECS Task Role**, which is automatically injected into your container.

Example (Production):

```php
$s3Client = new S3Client([
    'version' => 'latest',
    'region'  => getenv('AWS_REGION'),
    // No credentials provided — uses ECS Task Role
]);
```

Example (Local Development):

```php
$s3Client = new S3Client([
    'version'                 => 'latest',
    'region'                  => 'eu-west-1',
    'endpoint'                => 'http://localstack:4566',
    'use_path_style_endpoint' => true,
    'credentials'             => [
        'key'    => 'test',
        'secret' => 'test',
    ],
]);
```

Tip:
Wrap this logic in a factory or service class so your app can seamlessly switch between local and production.

---

## Summary

This project helps you:

✅ Run CakePHP in Docker

✅ Test with LocalStack

✅ Build apps ready for ECS Fargate

✅ Enforce **stateless design principles**

---

## Notes for ECS Deployment

When deploying to AWS ECS Fargate:

* Use multi-stage Docker builds to keep images small.
* Mount config through environment variables.
* Ensure all state (files, sessions, logs) is externalized.
* Provide a working `/healthcheck`.

## When to use nginx

This container uses Apache as it's easier to configure. When your application is under significant load it is better to use nginx as it is friendlier on the resources and scales better. 