# Développement

## Structure

- `lib/` : implémentation du plugin
- `spec/` : tests unitaires RSpec
- `docs/` : documentation du projet

## Vérifications

```sh
bundle exec rake
bundle exec rubocop
gem build vagrant-k8s.gemspec
```

## Essai local

```sh
vagrant plugin install .
vagrant up
```
