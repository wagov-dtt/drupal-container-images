# Caddyfile

## Info

- `Caddyfile` is  [Caddy](https://caddyserver.com/) **configuration format** used by [Caddy](https://caddyserver.com/) **web server**.
- The configuration defined in `Caddyfile` is used by [FrankenPHP](https://frankenphp.dev/) app server running on [Caddy](https://caddyserver.com/) **web server**.
- The `Caddyfile` in use is based on the [Drupal on FrankenPHP](https://github.com/dunglas/frankenphp-drupal) example (link to the file: [Port the Apache config to Caddyfile](https://github.com/dunglas/frankenphp-drupal/blob/main/Caddyfile)).
- Read more about: [Caddy](https://wagov-dtt.github.io/dalibor-matura/docs/server/Caddy/]), [Caddyfile](https://wagov-dtt.github.io/dalibor-matura/docs/server/Caddyfile/]) or [FrankenPHP](https://wagov-dtt.github.io/dalibor-matura/docs/language/php/FrankenPHP/).

## Resources

The `Caddyfile` use in this project is inspired by following resources:

- **Drupal core** issue: [Add Caddyfile configuration](https://www.drupal.org/project/drupal/issues/3437187) aiming to introduce a `Caddyfile` configuration to enable Drupal to be served by [Caddy](https://caddyserver.com/) and to make it possible to use [FrankenPHP](https://frankenphp.dev/) easily.
	- The **commit**: [add Caddyfile](https://git.drupalcode.org/project/drupal/-/commit/f1d611661998cad5eea3652ac09277433ec08800) is used in a few **MRs**: [Resolve #3437187 "Add caddyfile configuration"](https://git.drupalcode.org/project/drupal/-/merge_requests/7256)  and [Draft: Resolve #3437187 "Frankenphp features"](https://git.drupalcode.org/project/drupal/-/merge_requests/7276).
	- Forked repository: [drupal-3437187](https://git.drupalcode.org/issue/drupal-3437187/-/tree/3437187-add-caddyfile-configuration).