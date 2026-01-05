# Review

## Info

The following points have to be **reviewed before** making this project **PROD ready**.

## To be reviewed

### PHP 8.3 vs. 8.4

The [Drupal CMS with FrankenPHP](https://github.com/wagov-dtt/tutorials-and-workshops/tree/main/drupal#drupal-cms-with-frankenphp)](https://github.com/wagov-dtt/tutorials-and-workshops/tree/main/s3-pod-identity) example from **Adon** is using **PHP 8.4** as it comes with **improved** [PHP Just-In-Time (JIT) Compilation](https://medium.com/@rezahajrahimi/just-in-time-jit-compilation-in-php-8-4-2beab4d1212c).

The **Jobs WA** project is still using **PHP 8.3** and it would have to be **upgraded** in order for us to proceed with **PHP 8.4** when **re-platforming Jobs WA**.

**Adon:** - lets use 8.4 if we can, Drupal 10.4+ seems to support it (so would uplift jobsWA if no major issues spotted), this will allow us to have less testing/more consistency with future wa.gov.au builds.

### Caddyfile `@protectedFilesRegexp`

The [Caddyfile](../Caddyfile) has a directive `@protectedFilesRegexp` in the `{$SERVER_NAME:localhost}` section. The directive has parameter `path_regexp` with a **regular expression value**.

This **regular expression value** seems to be **NOT valid**.

The **Drupal core** issue: [Add Caddyfile configuration](https://www.drupal.org/project/drupal/issues/3437187) with the **commit**: [add Caddyfile](https://git.drupalcode.org/project/drupal/-/commit/f1d611661998cad5eea3652ac09277433ec08800) contains the **value** as:

```regex
\.(engine|inc|install|make|module|profile|po|sh|.*sql|theme|twig|tpl(\.php)?|xtmpl|yml)(~|\.sw[op]|\.bak|\.orig|\.save)?$|^/(\..*|Entries.*|Repository|Root|Tag|Template|composer\.(json|lock)|web\.config|yarn\.lock|package\.json)$|^\/#.*#$|\.php(~|\.sw[op]|\.bak|\.orig|\.save)$
```

The **regualr expression** above contains one **unescaped forward slash** `/` and one **escaped forward slash** `\/`.

- The online **Regular Expressions Tool** [https://regexr.com/](https://regexr.com/) **warns** about the **unescaped** forward slash.
- **Caddyfile** prepared by **Adon** in: [https://github.com/wagov-dtt/tutorials-and-workshops/blob/main/drupal/Caddyfile](https://github.com/wagov-dtt/tutorials-and-workshops/blob/main/drupal/Caddyfile) have both **forward slashes** `/` **unescaped**.

What should be the **correct forward slash escaping** in this case **?**

**Adon:** - switch to all escaped fwd slashes, I copypasted the caddyfile basically as is from drupal core but believe they made an error, we should fix.

### Caddyfile `file_server`

Compared to [Drupal CMS with FrankenPHP](https://github.com/wagov-dtt/tutorials-and-workshops/tree/main/drupal#drupal-cms-with-frankenphp)](https://github.com/wagov-dtt/tutorials-and-workshops/tree/main/s3-pod-identity) example from **Adon**, the project contains also the following `file_server` configuration in its [Caddyfile](../Caddyfile):

```
# Security: List of files or folders to hide; if requested, the file server will pretend they do not exist.  
file_server {  
    hide .git  
    hide .env*  
}
```

Read more about it in **Caddy** documentation: [file_server](https://caddyserver.com/docs/caddyfile/directives/file_server).

**Adon:** - This is just good defaults to avoid unexpected build gotchas (even from modules etc), would keep in.

### Caddyfile in `.htaccess`

The `Caddyfile` is **protected** from prying eyes in the `.htaccess` modified under **Drupal core** issue: [Add Caddyfile configuration](https://www.drupal.org/project/drupal/issues/3437187) in the **commit**: [add Caddyfile](https://git.drupalcode.org/project/drupal/-/commit/f1d611661998cad5eea3652ac09277433ec08800).

We probably want to **include this change** either:

1. As `.htaccess` modification.
2. Or making the modification part of the **Container Image** building process (amending the `.htaccess` or using other directives).
3. Or adding it into the [Caddyfile](../Caddyfile)  directive `@protectedFilesRegexp` (not sure if it will work).

**Adon:** - Would include in the 'hide' directives for the file_server above, .htaccess ignored by caddy so wouldn't be worth dropping in there.




