## Releases

To install betas run `gem install git-multirepo --pre`

## 1.0.0.beta72

- **Bug Fix:** Revert changes from beta 71
- **Enhancement:** Add a `--here` flag to the `clone` command to skip creating an intermediate directory to clone into

## 1.0.0.beta71

- **Enhancement:** The `clone` command now clones all repos in the current directory instead of creating an intermediate directory (more flexible)

## 1.0.0.beta70

- **Enhancement:** Repo clones initialize and clone submodules (shallow in CI scenarios).
- **Enhancement:** The `merge` command always updates main repo tracking files (makes no sense not to do it, important for CI).

## 1.0.0.beta69

- **Bug Fix:** The `add` command ensures that added repos' paths have a trailing slash (avoids some nasty issues)

## 1.0.0.beta68

- **Bug Fix:** Fix a regression that prevented many commands from running

## 1.0.0.beta67

- **Bug Fix:** Fix a crash related to the presence of trailing slashes in dependency paths

## 1.0.0.beta66

- **Enhancement:** Add a `--no-ff` option to `multi merge` to optionally avoid fast-forwarding

## 1.0.0.beta65

- **Removal:** The `graph` command was removed. It was unused and added an unnecessary dependency.

## 1.0.0.beta64

- **Enhancement:** The branch command does not push by default anymore (helps avoid creating branches in wrong origins when setting up new projects)

## 1.0.0.beta63

- **Bug Fix:** Remove some unnecessary debug console output

## 1.0.0.beta62

- **Bug Fix:** Fix post-first-init commit

## 1.0.0.beta61

- **Bug Fix:** Fix crasher in file permissions checking code

## 1.0.0.beta60

- **Enhancement:** Implemented the `--force` option in `multi branch`
- **Enhancement:** Prevent updating tracking files with an outdated version of the tool
- **Bug Fix:** Fail gracefully in case of limited tracking file permissions

## 1.0.0.beta59

- **Bug Fix:** Fix clone and install error when on-disk dependency directory case does not match

## 1.0.0.beta57

- **Bug Fix:** Fixed error in multi install clone error message building

## 1.0.0.beta56

- **Enhancement:** Using the `--extra-output` flag will output more CI server-specific info (checkout info, errors, etc.)
- **Bug Fix:** Some config flags (such as `--verbose`) were reset when calling other commands internally

## 1.0.0.beta53

- **Enhancement:** Added a `--extra-output` flag to output additional CI server-specific messages (such as TeamCity service messages)

## 1.0.0.beta52

- **Enhancement:** InspectCommand now takes the name of a stat as input instead of flags and provides helpful output if the provided stat name is invalid
- **Enhancement:** Added a `--force` flag to `multi checkout`, which ignores uncommitted changes

## 1.0.0.beta51

- **Enhancement:** `multi merge` now shows a lock file diff if the user chooses to perform an update after the merge operation
- **Enhancement:** `multi merge` now uses the same update logic as `multi update` for more robustness and uniformity
- **Enhancement:** `multi update` has a new `--no-diff` option to skip lock file diffing and shows diff by default
- **Bug Fix:** `multi update` did not show the lock file diff when the `--commit` flag was specified
- **Internals:** `multi update`, `multi do` and `multi open` now use common repo-selection logic (`--deps`, `--main`, etc.)

## 1.0.0.beta50

- **Enhancement:** `multi merge` now asks to update the main repo lock file after a merge (useful for CI scenarios)
- **Enhancement:** `multi update` now asks to show a lock file diff if the main repo's lock file was modified
- **Enhancement:** Checking out the main repo in floating HEAD to prevent unnecessary local branch creation in `multi merge`

## 1.0.0.beta49

- **Enhancement:** Added `--deps`, `--main` and `--all` flags to `multi update` and update all by default
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

## 1.0.0.beta45 and earlier

Refer to the commit history for details on earlier versions of git-multirepo.
