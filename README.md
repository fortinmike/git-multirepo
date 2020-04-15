# git-multirepo

[![Gem Version](https://badge.fury.io/rb/git-multirepo.svg)](http://badge.fury.io/rb/git-multirepo)
[![Code Climate](https://codeclimate.com/github/fortinmike/git-multirepo/badges/gpa.svg)](https://codeclimate.com/github/fortinmike/git-multirepo)
[![License](http://img.shields.io/:license-mit-blue.svg)](https://github.com/fortinmike/git-multirepo/blob/master/LICENSE)

Track multiple Git repositories side-by-side.

An alternative approach to manage constantly evolving dependencies.

Check out [the project's to-do list](https://www.pivotaltracker.com/n/projects/1256156) to get an idea of upcoming enhancements and read the [change log](https://github.com/fortinmike/git-multirepo/blob/master/CHANGELOG.md) for detailed information on releases.

You can download a handy cheat sheet [here](https://github.com/fortinmike/git-multirepo/raw/master/docs/git-multirepo-cheatsheet.docx).

## Installation

git-multirepo is distributed as a Ruby Gem.

    $ gem install git-multirepo

The `--pre` flag is necessary to install beta releases.

## Development

1. Install dependencies with `bundle install` (install the `bundler` gem beforehand if necessary)
2. Run `rake install` to build and install the tool locally (`sudo` might be required based on how your Ruby was installed)
3. Run it using the command `multi`

## Motivation

The
[pitfalls](http://somethingsinistral.net/blog/git-submodules-are-probably-not-the-answer/)
of git submodules are
[pretty](https://codingkilledthecat.wordpress.com/2012/04/28/why-your-company-shouldnt-use-git-submodules/)
[well](http://slopjong.de/2013/06/04/git-why-submodules-are-evil/)
[known](http://stackoverflow.com/questions/12075809/git-submodules-workflow-issues).
They work when your dependencies are linearly-evolving third-party libraries that you seldom update but they fall apart when it comes to managing your own, constantly evolving dependencies. To solve this, many tools have been created. Among the most popular is [Lerna](https://lerna.js.org) but that only works for JavaScript projets and requires projects to migrate to a monorepo. `git-multirepo` works with separate repos and is language-agnostic.

Git subtrees are a recommended approach, but they have pitfalls of their own:

- They require verbose and error-prone command-line operations. This can become quite tedious when managing more than one or two dependencies.
- They change the rules of the game when it comes to merges.
- Each developer has to configure the appropriate remotes and subtrees on his machine if he or she wants to contribute back.
- Developers must not forget to push changes to dependencies back to the appropriate remotes.
- Few git GUIs have any kind of subtree integration, so you're stuck with the command-line.

Etc.

## Overview

Using git-multirepo, you can manage your main project and its dependencies as completely independent repositories while still maintaining the ability to checkout a previous revision (or another branch) in a single step and have the project build properly.

A git-multirepo setup looks like this:

```
MyAwesomeProject
  |-- AwesomeApp
  |-- Dependency1
  |-- Dependency2
```

In essence:

1. You tell git-multirepo what your dependencies are.
2. Each time you commit the main repo, git-multirepo tracks what revision of each dependency is required by the project (and it ensures that you don't forget to commit changes to dependencies beforehand; more on that later).
3. If you ever want to go back to a previous version of your project, git-multirepo handles checking out the main repo and appropriate revisions of all of its dependencies in a single, seamless operation.
4. Setting up the project on a new machine is only a single `multi clone` away. Checking out source for continuous integration is similarly easy.

## Example

Say you want to track an existing project with git-multirepo:

1. Organize repos on disk in the following manner:

   ```
   MyAwesomeProject
     |-- AwesomeApp
     |-- Dependency1
     |-- Dependency2
   ```

2. `cd` into the _AwesomeApp_ directory (aka the "main repo").
3. Run `multi init`.
4. You will get prompted to add _Dependency1_ and _Dependency2_ to multirepo; do so.
5. git-multirepo reads all required information from dependency repos and initializes itself, storing its metadata in the main repo, under version control.

From now on, each time you commit the main repo git-multirepo tracks &mdash; using local git hooks &mdash; which revision of each dependency is required for that main repo revision, and where to get them. The hooks also ensure that you won't commit the main repo before its dependencies so that you always get a valid state stored under version control.

If you want to add another dependency later on, you can run `multi add ../NewDependency` and you can do the opposite with `multi remove ../SomeOtherDependency`.

If you want to checkout a previous revision (say `e690d`), you use the checkout command: `multi checkout e690d`. This will checkout the main repo's `e690d` revision and all of its dependencies with the proper revisions in detached HEAD state.

If you want to setup your project on another machine, simply run `multi clone` with the appropriate parameters. This will clone the project and each of its dependencies, then checkout the appropriate work branches.

If you want to stop using git-multirepo, run `multi uninit`. This will remove all traces of git-multirepo from your repository and working copy, including local git hooks.

## Advantages

- Makes setting up a project on a new machine a breeze.
- Really effective when working on multiple projects that share a common set of constantly evolving dependencies.
- Each dependency's repository is totally independent from the main repository, which simplifies a lot of things (merges, contributing upstream, etc.) and works well with git GUIs.
- While the repositories are independent, git-multirepo makes sure to track everything that's required to bring back a previous version of your project in a valid state.
- It supports sub-dependencies (e.g. dependencies that have dependencies of their own) so that you can bring back any subset of your project in a valid state at will.
- Much more approachable to novice developers than submodules or subtrees.
- Once setup, there is little need for git-multirepo commands (although some of them are great timesavers), so you are free to use whatever tools you like to work with your git repos.
- Low possibility of human error (such as forgetting to contribute changes to dependencies back to the appropriate remotes, forgetting to commit dependencies in the proper order, etc.)
- You're not stuck with git-multirepo. It stores its metadata as [YAML](http://www.yaml.org) in the main repo. You can clone and checkout appropriate revisions of your dependencies by hand without git-multirepo if you need to. The information is there, in human-readable form.

| How It Handles...                |   git-multirepo    | git submodules | git subtrees |
| -------------------------------- | :----------------: | :------------: | :----------: |
| Working Copy                     |  beside main repo  |  in main repo  | in main repo |
| Constantly Evolving Dependencies |        easy        |      hard      |   passable   |
| Merging Changes to Dependencies  |        easy        |      hard      |   passable   |
| Contributing Upstream            |        easy        |      easy      |   passable   |
| Continuous Integration           | medium<sup>1</sup> |     medium     |     easy     |
| Branch-Based Workflows           |  easy<sup>2</sup>  |      hard      |     easy     |

(1) For simplified checkouts, you must install and use `git-multirepo` in your CI pipeline, otherwise you forgo the benefits it provides for CI. See [Continuous Integration](#continuous-integration) for details.

(2) The `multi branch` and `multi merge` commands faciliate branching and merging the main repo and its dependencies as a whole.

## Limitations

- This tool should be considered beta at the moment (but it's getting pretty stable).
- The tracked project and its dependencies must live beside each other on disk.
- You must install the tool on your CI server (`gem install git-multirepo`) and perform a `multi install --ci` to checkout dependencies prior to building.

## Subdependencies

Dependencies can be initialized and have their own dependencies. However, git-multirepo currently supports only _direct_ dependencies (which is a minor inconvenience in practice). This means that every git-multirepo-enabled repository must have its direct and indirect dependencies listed in its `.multirepo file`. Take for example the following directory listing.

```
MyAwesomeProject
  |-- AwesomeApp
  |-- AppDependency1
  |-- AppDependency1-Dependency
  |-- AppDependency2
```

To properly track those repositories with git-multirepo, `AppDependency1` would be initialized with `AppDependency1-Dependency` as a dependency. Then, `AwesomeApp` would be initialized with `AppDependency1`, `AppDependency1-Dependency` and `AppDependency2` as dependencies, even though `MyAwesomeApp` does not directly depend on `AppDependency1-Dependency`. `AppDependency1-Dependency` and `AppDependency2` do not need to be initialized because they have no dependencies of their own.

After repositories are initialized this way, git-multirepo handles the rest and enforces dependency tree-based commit order, merges and more. From then, it is also possible to perform a `multi checkout` not only in the `AwesomeApp` directory but also in the `AppDependency1` directory. This means you can easily get a subset of your dependencies into the state they were in at some point in the past.

## Continuous Integration

<a href="#continuous-integration"></a>

git-multirepo supports continuous integration in a couple of ways:

- The `install` command has a special `--ci` flag, which:
  - Installs exact revisions of dependencies in-place (as read from the lock file)
  - Skips local hooks installation
  - Logs additional information that's useful in a CI context
- The `inspect` command offers plumbing-style output that can be used to inspect repositories to conditionally perform multirepo operations on them afterwards.
- A special `--extra-output` option causes git-multirepo to output specially-formatted progress and error messages for CI purposes, such as TeamCity service messages (when using `--extra-output=teamcity`).

## Summary of Commands

Here is a quick rundown of commands available to you in git-multirepo:

| Command  | Description                                                                                                                                                                               |
| -------- | ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| init     | Initialize the current repository as a multirepo project.                                                                                                                                 |
| add      | Track an additional dependency with multirepo.                                                                                                                                            |
| branch   | Create and/or checkout a new branch for all repos.                                                                                                                                        |
| checkout | Checks out the specified commit or branch of the main repo and checks out matching versions of all dependencies.                                                                          |
| clone    | Clones the specified repository in a subfolder, then installs it.                                                                                                                         |
| do       | Perform an arbitrary Git operation in the main repository, dependency repositories or all repositories.                                                                                   |
| inspect  | Outputs various information about multirepo-enabled repos. For use in scripting and CI scenarios.                                                                                         |
| install  | Clones and checks out dependencies as defined in the version-controlled multirepo metadata files and installs git-multirepo's local git hooks. Idempotent for a given main repo checkout. |
| merge    | Performs a git merge on all dependencies and the main repo, in the proper order.                                                                                                          |
| open     | Opens repositories in the OS's file explorer.                                                                                                                                             |
| remove   | Removes the specified dependency from multirepo.                                                                                                                                          |
| update   | Force-updates the multirepo tracking files.                                                                                                                                               |
| uninit   | Removes all traces of multirepo in the current multirepo repository.                                                                                                                      |

To read more about each command, use the `--help` flag (e.g. `$ multi clone --help`).

## Metadata

git-multirepo stores all of its metadata in three files:

| File            | Format | Updated                                   | Contents                                                                                                                                                                                                                                      |
| --------------- | ------ | ----------------------------------------- | --------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| .multirepo      | YAML   | at _initialization_, on _add_ on _remove_ | A collection of your project's dependencies. For each dependency, stores its **local path** relative to the main repo and the **remote URL** your project depends upon.                                                                       |
| .multirepo.lock | YAML   | before each commit                        | For each dependency, stores the **commit id** and **branch** on which the dependency was when the main repo was committed. The dependency's **name** is also included but only serves as a reference to make inspecting the lock file easier. |
| .multirepo.meta | YAML   | before each commit                        | Various git-multirepo metadata, such as the **git-multirepo version** that the last commit was performed with.                                                                                                                                |

The information contained in .multirepo and .multirepo.lock allow one-step cloning of a project and all its dependencies, and checking out any prior revision of the main project with appropriate revisions of all of its dependencies, respectively.
