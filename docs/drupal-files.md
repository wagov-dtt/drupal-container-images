# Drupal Files

## Info

[Drupal](https://drupal.org/) has following **file types** separated based on their storage and creation process (what purpose they have):

- **Public**
- **Private**
- **Generated**

## Purpose

The section below explains the meaning of **file types** and how to configure their storage path.

## File types and their storage settings

### Public

**Path**: `sites/default/files` (`web/sites/default/files`)

[Drupal](https://drupal.org/) uses the `public://` stream wrapper ([PublicStream](https://api.drupal.org/api/drupal/core%21lib%21Drupal%21Core%21StreamWrapper%21PublicStream.php/class/PublicStream/11.x)) to store and serve openly accessible files through the [Drupal File API](https://www.drupal.org/docs/7/api/file-api/file-api-overview).

By **default**, files mapped to `public://` point to `sites/default/files` within [Drupal](https://drupal.org/) web root.

[Drupal](https://drupal.org/) **container image** building process requires the **default** path to **public** files, which should be defined in `sites/default/settings.php` file like this:

```php
$settings['file_public_path'] = 'sites/default/files';
```

### Private

**Path**: `sites/default/private` (`web/sites/default/private`)

[Drupal](https://drupal.org/) uses the `private://` stream wrapper ([PrivateStream](https://api.drupal.org/api/drupal/core%21lib%21Drupal%21Core%21StreamWrapper%21PrivateStream.php/class/PrivateStream/11.x)) to route files through [Drupal](https://drupal.org/)  **access checks** rather than exposing them directly via the web server, ensuring anonymous or unauthorized users can not download them via direct links.

By **default**, files mapped to `private://` point to `sites/default/files/private` within [Drupal](https://drupal.org/) web root.

- When you specify the private directory in `admin/config/media/file-system` it automatically creates the sub-directory & create a simple `.htaccess` file with `Deny from all`.
- Whenever possible it's **recommended** that you choose a directory **located outside** of your [Drupal](https://drupal.org/) root folder (or actually outside your web root), which may be tricky if you are on a shared host.

[Drupal](https://drupal.org/) **container image** building process requires the following path to **private** files, which should be defined in `sites/default/settings.php` file like this:

```php
$settings['file_private_path'] = 'sites/default/private';
```

We might want to improve the settings in a future and potentially **create the private directory outside web root**, which is ideal for security.

- In relation to [Drupal](https://drupal.org/) web root the improved location could be `../private`.

### Generated

**Paths**:

- `sites/default/generated/assets` (`web/sites/default/generated/assets`)
- `sites/default/generated/php` (`web/sites/default/generated/php`)

[Drupal](https://drupal.org/) **container image** building process requires the paths for **generated** files to be separated from **public** and **private** files location to be **excluded from backups**. The following paths defined in `sites/default/settings.php` file are required:

```php
// Optimized assets path.
$settings['file_assets_path'] = 'sites/default/generated/assets';
// Twig cache storage directory.
$settings['php_storage']['twig']['directory'] = 'sites/default/generated/php';
```

**Optimized Assets** settings (`$settings['file_assets_path']`) changes where [Drupal](https://drupal.org/) saves **aggregated**, **minified**, and **optimized CSS** and **JavaScript** files.

**Twig Cache** settings (`$settings['php_storage']`) alters the location where Drupal saves **compiled Twig template PHP** files.