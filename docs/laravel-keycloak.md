# Laravel con Keycloak (Socialite)

Integracion de una aplicacion Laravel en **http://dev.local** con [socialiteproviders/keycloak](https://socialiteproviders.com/Keycloak).

## Requisitos en este repositorio

1. `docker compose up -d postgresql keycloak`
2. Consola: http://localhost:20001 (`admin` / `admin`)
3. Realm **dev** importado desde `keycloak/realm.json` en el primer arranque.

Si cambias `realm.json` y el realm no se actualiza (solo desarrollo):

```bash
docker compose stop keycloak
docker exec postgresql dropdb -U postgres --force keycloak
docker exec postgresql psql -U postgres -c "CREATE DATABASE keycloak WITH OWNER keycloak ENCODING 'UTF8' LOCALE_PROVIDER icu ICU_LOCALE 'es-CL' TEMPLATE template_full_cl"
docker compose up -d keycloak
```

4. En el host: `127.0.0.1 dev.local` en `/etc/hosts`.

## Cliente Keycloak (realm `dev`)

| Campo | Valor |
|-------|--------|
| Client ID | `laravel-app` |
| Client secret | `my-client-secret` |
| Redirect URI | `http://dev.local/auth/callback/keycloak` |
| Web origin | `http://dev.local` |

Usuario de prueba: `dev-user` / `dev123` (rol `user`).

## Laravel

```bash
composer require laravel/socialite socialiteproviders/keycloak
```

`.env` (Laravel en el host):

```dotenv
APP_URL=http://dev.local
KEYCLOAK_CLIENT_ID=laravel-app
KEYCLOAK_CLIENT_SECRET=my-client-secret
KEYCLOAK_REDIRECT_URI="${APP_URL}/auth/callback/keycloak"
KEYCLOAK_BASE_URL=http://localhost:20001
KEYCLOAK_REALM=dev
```

Si Laravel corre en la red Docker `development`: `KEYCLOAK_BASE_URL=http://keycloak:20001`. El navegador del usuario sigue usando `http://localhost:20001` para OAuth.

`config/services.php`:

```php
'keycloak' => [
    'client_id' => env('KEYCLOAK_CLIENT_ID'),
    'client_secret' => env('KEYCLOAK_CLIENT_SECRET'),
    'redirect' => env('KEYCLOAK_REDIRECT_URI'),
    'base_url' => env('KEYCLOAK_BASE_URL'),
    'realms' => env('KEYCLOAK_REALM'),
],
```

Registrar el proveedor en `AppServiceProvider::boot` (Laravel 11+):

```php
Event::listen(function (\SocialiteProviders\Manager\SocialiteWasCalled $event) {
    $event->extendSocialite('keycloak', \SocialiteProviders\Keycloak\Provider::class);
});
```

Rutas de ejemplo:

```php
Route::get('/auth/redirect/keycloak', [KeycloakController::class, 'redirect']);
Route::get('/auth/callback/keycloak', [KeycloakController::class, 'callback']);
```

## Problemas frecuentes

| Sintoma | Causa habitual |
|---------|----------------|
| `Invalid redirect_uri` | `KEYCLOAK_REDIRECT_URI` no coincide con Keycloak |
| Keycloak no responde | http://localhost:20001/health/ready |
| Realm ausente | Borrar y recrear base `keycloak` (ver arriba) |
| `dev.local` no carga | Falta `/etc/hosts` o `APP_URL` incorrecta |

Documentacion del proveedor: https://socialiteproviders.com/Keycloak
