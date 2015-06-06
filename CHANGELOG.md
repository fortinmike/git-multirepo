## Releases

To install betas run `[sudo] gem install git-multirepo --pre`

## 1.0.0.beta49

- **Enhancement:** Added --deps, --main and --all flags to `multi update` and update all by default
- **Enhancement:** Log a warning on multi install --ci if the main repo HEAD is a merge commit, for CI servers to pick up and optionally force fail with
- **Bug Fix:** "HEAD" was stored in the lock file instead of `nil` when in floating HEAD, which caused some operations to have unexpected results
- **Bug Fix:** Incorrect default behavior for `multi open` (now defaults to "all")

## 1.0.0.beta48

- **New:** `multi update` now updates tracking files in subdependencies
- **Enhancement:** Manual and automated code refactorings using RuboCop

## 1.0.0.beta47

- **Enhancement:** Running commands using system() when we don't need to grab output (enables interactive commands in `multi do` and fixes clone/fetch progress output)

## 1.0.0.beta46

- **Enhancement:** Better `multi install --ci` output
- **Enhancement:** Not requiring a multirepo-enabled repo in InspectCommand, else it's not very useful to inspect random repos
- **Bug Fix:** Fixed exception in `multi do` when providing only the `--help` flag