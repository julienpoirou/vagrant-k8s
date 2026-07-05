# Development

## Layout

- `lib/`: plugin implementation
- `spec/`: RSpec unit tests
- `docs/`: project documentation

## Checks

```sh
bundle exec rake
bundle exec rubocop
gem build vagrant-k8s.gemspec
```

## Local trial

```sh
vagrant plugin install .
vagrant up
```
