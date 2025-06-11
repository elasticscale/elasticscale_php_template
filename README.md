# GETTING STARTED

Outline for the readme:



## 1. Install Docker

How to install docker

## 2. Change hosts file

Change hostfile, on Mac + add windows instructions:

```
sudo vim /private/etc/hosts
```

Add an entry like this that ends at .test:

```
127.0.0.1 laravel.test
```

And why we need to do that because localhost sucks and can have weird behaviour at times.

## 3. Setup laravel env

Copy `laravel/.env.example` to `laravel/.env`

## 4. Start app

Run `docker compose up -d`

## 5. Install composer dependencies

Run `docker compose exec -it app bash` to get into the laravel container then run `composer install`

## 6. Access application

Go to http://laravel.test/ to see the application, changes will be volume mounted so you can see them directly. 

phpmyadmin is available on http://localhost:8080/

# Statelesness





