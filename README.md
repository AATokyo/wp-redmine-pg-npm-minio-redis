# Self-Hosted WordPress and Redmine with PostgreSQL, MinIO, Redis, and Nginx Proxy Manager

This stack runs WordPress and Redmine entirely in Docker with self-hosted PostgreSQL, MinIO, Redis, and Nginx Proxy Manager.

## Start

1. Copy `.env.example` to `.env`.
2. For local Compose, create these secret files: `secrets/db_password.txt`, `secrets/admin_password.txt`, `secrets/s3_key.txt`, and `secrets/s3_secret.txt`.
3. Adjust `.env` only if you want different local hostnames, site title, bucket name, or admin values.
4. Run `docker compose up --build`.
5. Open `http://localhost:81`, sign in to Nginx Proxy Manager, and create these proxy hosts:
	- `wp.localtest.me` -> `http://wordpress:80`
	- `redmine.localtest.me` -> `http://redmine:80`
	- `uploads.localtest.me` -> `http://minio:9000`
	- optional: `minio-console.localtest.me` -> `http://minio:9001`

`localtest.me` resolves to `127.0.0.1` automatically, so you do not need to edit your hosts file for local use.

After that, access WordPress through `http://wp.localtest.me` and Redmine through `http://redmine.localtest.me`. If you also proxy MinIO, uploaded media will be served from `http://uploads.localtest.me/<bucket>`.

The first container start runs `wp core install` automatically using the admin credentials from `.env` because `WORDPRESS_AUTO_INSTALL=true` in the local defaults. Nginx Proxy Manager also uses the same PostgreSQL service through its `npm` database. Redmine uses the same PostgreSQL service with its own `redmine` role and `redmine` database, created on startup.

## Notes

PostgreSQL, MinIO, Redis, Redmine, WordPress, and Nginx Proxy Manager are all included in this Compose stack. No external cloud database or object storage service is required.

The WordPress image installs `pdo_pgsql` and wires in a `db.php` drop-in plus the S3 Uploads plugin for MinIO-compatible object storage. The Redmine image is built from `sameersbn/redmine:7.0.0-2` and adds the `redmine_wbs` and `redmine_cloud_attachment_pro` plugins.

If you want WordPress to rewrite uploaded URLs behind the proxy, set `S3_UPLOADS_BUCKET_URL` to the public bucket URL you expose through Nginx Proxy Manager. For this local stack, the default path-style URL is `http://uploads.localtest.me/<bucket>`.

Redmine attachment uploads are configured through `redmine/setup-s3.sh` and default to the same MinIO service through Nginx Proxy Manager-friendly settings.

## Nginx Proxy Manager Host Plan

Use these settings when creating proxy hosts in Nginx Proxy Manager:

1. WordPress site
	- Domain Names: `wp.localtest.me`
	- Scheme: `http`
	- Forward Hostname / IP: `wordpress`
	- Forward Port: `80`
	- Websockets Support: `on`
	- Block Common Exploits: `on`

2. Redmine
	- Domain Names: `redmine.localtest.me`
	- Scheme: `http`
	- Forward Hostname / IP: `redmine`
	- Forward Port: `80`
	- Websockets Support: `on`
	- Block Common Exploits: `on`

3. MinIO uploads
	- Domain Names: `uploads.localtest.me`
	- Scheme: `http`
	- Forward Hostname / IP: `minio`
	- Forward Port: `9000`
	- Websockets Support: `on`

4. MinIO console
	- Domain Names: `minio-console.localtest.me`
	- Scheme: `http`
	- Forward Hostname / IP: `minio`
	- Forward Port: `9001`
	- Websockets Support: `on`

For local-only usage, keep these hosts on plain HTTP. Add certificates only when you control a real DNS name that resolves to this Docker host.

The stack accepts either Compose secrets mounted at `/run/secrets` or plain environment variables for the WordPress admin password, database password, and MinIO credentials.
