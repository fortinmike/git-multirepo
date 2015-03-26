![git-multirepo](images/logo.png)

# git-multirepo

[![Gem Version](https://badge.fury.io/rb/git-multirepo.svg)](http://badge.fury.io/rb/git-multirepo)

Track multiple Git repositories side-by-side.

An alternative approach to manage constantly evolving dependencies.

Check out [the project's to-do list](https://www.pivotaltracker.com/n/projects/1256156) to get an idea of upcoming enhancements.

## Motivation

By now the
[pitfalls](http://somethingsinistral.net/blog/git-submodules-are-probably-not-the-answer/)
of git submodules are
[pretty](https://codingkilledthecat.wordpress.com/2012/04/28/why-your-company-shouldnt-use-git-submodules/)
[well](http://slopjong.de/2013/06/04/git-why-submodules-are-evil/)
[known](http://stackoverflow.com/questions/12075809/git-submodules-workflow-issues).
They work when your dependencies are linearly-evolving third-party libraries that you seldom update but they fall apart when it comes to managing your own, constantly evolving dependencies.

Git subtrees are the recommended alternative but have pitfalls of their own:

- They require verbose and error-prone command-line operations. This can become quite tedious when managing more than one or two dependencies.
- They change the rules of the game when it comes to merges.
- Each developer has to configure the appropriate remotes and subtrees on his machine if he or she wants to contribute back.
- Developers must not forget to push changes to dependencies back to the appropriate remotes.
- Few git GUIs have any kind of subtree integration, so you're stuck with the command-line.

Etc.

## Overview

Using git-multirepo, you can manage your main project and its dependencies as completely independent repositories while still maintaining the ability to checkout a previous revision in a single step and have the project build properly.

A git-multirepo setup looks like this:

```
MyAwesomeProject
  |-- AwesomeApp
  |-- Dependency1
  |-- Dependency2
```

In essence:

1. You tell git-multirepo what your dependencies are.
2. Each time you commit the main repo, git-multirepo tracks what revision of each dependency is required by the project (don't worry, it ensures that you don't forget to commit changes to dependencies beforehand; more on that later).
3. If you ever want to go back to a previous version of your project, git-multirepo handles checking out the main repo and appropriate revisions of all of its dependencies in a single, seamless operation.
4. Setting up the project on a new machine is only a single `git clone` and `multi install` away.

## Example

Say you want to track an existing project with git-multirepo:

1. Organize repos on disk in the following manner:

	```
	MyAwesomeProject
	  |-- AwesomeApp
	  |-- Dependency1
	  |-- Dependency2
	```

2. `cd` into the *AwesomeApp* directory (aka the "main repo").
3. Run `multi init`.
4. You will get prompted to add *Dependency1* and *Dependency2* to multirepo; do so.
5. git-multirepo reads all required information from dependency repos and initializes itself, storing its metadata files in the main repo, under version control.

From now on, each time you commit the main repo git-multirepo tracks &mdash; using a pre-commit hook &mdash; which revision of each dependency is required for that main repo revision, and where to get them. The pre-commit hook also ensures that you won't commit the main repo before its dependencies so that you always get a valid state stored under version control.

If you want to add another dependency later on, you can run `multi add ../NewDependency` and you can do the opposite with `multi remove ../SomeOtherDependency`.

If you want to checkout a previous revision (say `e690d`), you use the checkout command: `multi checkout e690d`. This will checkout the main repo's `e690d` revision and all of its dependencies with the proper revisions in detached HEAD state.

If you want to setup your project on another machine, simply clone the main repo in a container directory (see above) and run `multi install`. This will clone each dependency and checkout the appropriate branches.

If you want to stop using git-multirepo, run `multi uninit`. This will remove all traces of git-multirepo from your repository and working copy.

## Advantages

- Makes setting up the project on a new machine a breeze.
- Works really well for multiple projects that share a common set of constantly evolving dependencies.
- Each dependency's repository is totally independent from the main repository, which simplifies a lot of things (merges, contributing upstream, etc.) and works well with git GUIs.
- While the repositories are independent, git-multirepo makes sure to track everything that's required to bring back a previous version of your project in a valid state.
- Much more approachable to novice developers than submodules or subtrees.
- Once setup, there is little need for git-multirepo commands, so you are free to use whatever tools you like to work with your git repos.
- Low possibility of human error (such as forgetting to contribute dependency changes back to the appropriate remotes, forgetting to commit dependencies before committing the main project, etc.)
- You're not stuck with git-multirepo. It stores its metadata as [YAML](http://www.yaml.org) in the main repo. You can clone and checkout appropriate revisions of your dependencies by hand without git-multirepo if you need to. The information is there, in human-readable form.

| How It Handles... | git-multirepo | git submodules | git subtrees |
|----------------------------------|:----------------:|:--------------:|:------------:|
| Working Copy | beside main repo | in main repo | in main repo |
| Constantly Evolving Dependencies | easy | hard | passable |
| Merging Changes to Dependencies | easy | hard | passable |
| Contributing Upstream | easy | easy | passable |
| Continuous Integration | medium | medium | easy |
| Complex Branch-Based Workflows | hard* | hard | easy |

(*) This should get better in future versions of git-multirepo.

## Limitations

- git-multirepo should be considered beta at the moment. All of the core features work as described, though. Suggestions and contributions are welcome.
- The project and its dependencies must live beside each other on disk (for now).
- There are currently no features to facilitate branch-heavy workflows.
- You must (ideally) install the tool on your CI server: `gem install git-multirepo`

## Summary of Commands

Here is a quick rundown of commands available to you in git-multirepo:

| Command | Description |
|---------|-------------|
| init | Initialize the current repository as a multirepo project. |
| add | Track an additional dependency with multirepo. |
| branch | Create and/or checkout a new branch for all repos. |
| checkout | Checks out the specified commit or branch of the main repo and checks out matching versions of all dependencies. |
| clone | Clones the specified repository in a subfolder, then install it. |
| edit | Opens the .multirepo file in the default text editor. |
| fetch | Performs a git fetch on all dependencies. |
| install | Clones and checks out dependencies as defined in the .multirepo file, and installs git-multirepo's local pre-commit hook. |
| open | Opens all dependencies in the current OS's file explorer. |
| remove | Removes the specified dependency from multirepo. |
| update | Force-updates the multirepo lock file. |
| uninit | Removes all traces of multirepo in the current multirepo repository. |

To read more about each command, use the --help flag (e.g. `$ multi clone --help`).

## Metadata

git-multirepo stores all of its metadata in two files:

| File | Format | Contents |
|------|--------|----------|
| .multirepo | YAML | A collection of your project's dependencies. For each dependency, stores its **local path** relative to the main repo, the **remote URL** and the **branch** your project depends upon.
| .multirepo.lock | YAML | For each dependency, stores the **commit hash** and **branch** on which the dependency was when the main repo was committed. The dependency's **name** is also included but only serves as a reference to make inspecting the lock file easier. |

The information contained in .multirepo and .multirepo.lock allow one-step cloning of a project and all its dependencies, and checking out any prior revision of the main project with appropriate revisions of all of its dependencies, respectively.