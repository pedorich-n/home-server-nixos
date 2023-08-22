# Development environment

Inspired by https://github.com/nix-community/ethereum.nix/issues/258 & https://github.com/srid/haskell-flake/pull/179

## Note about pre-commit-hook

Because `pre-commit-hook` is installed from subdirectory, the `core.hooksPath` setting in `.git/config` is not correct.

Instead of `../.git/hooks` it should be `.git/hooks`
