# git-multirepo

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

If you want to checkout a previous revision (say tag "1.2"), you use the checkout command: `multi checkout 1.2`. This will checkout the main repo and all of its dependencies with the proper revisions in detached HEAD state.

If you want to setup your project on another machine, simply clone the main repo in a container directory (see above) and run `multi install`. This will clone each dependency and checkout the appropriate branches.

If you want to stop using git-multirepo, run `multi uninit`. This will remove all traces of git-multirepo from your repository and working copy.

## Advantages

- Works really well with multiple projects that share a common set of constantly evolving dependencies.
- Each dependency's repository is totally independent from the main repository, which simplifies a lot of things (merges, contributing upstream, etc.) and works well with git GUIs.
- While the repositories are independent, git-multirepo makes sure to track everything that's required to bring back a previous version of your project in a valid state.
- Much more approachable to novice developers than submodules or subtrees.
- Once setup, there is little need for git-multirepo commands, so you are free to use whatever tools you like to work with your git repos.
- Low possibility of human error (such as forgetting to contribute dependency changes back to the appropriate remotes, forgetting to commit dependencies before committing the main project, etc.)
- Works well with CI servers.
- You're not stuck with git-multirepo. It stores its metadata as CSV and YAML in the main repo. You can clone and checkout appropriate revisions of your dependencies by hand without git-multirepo if you need to. The information is there, in human-readable form.

| How It Handles...                |   git-multirepo  | git submodules | git subtrees |
|----------------------------------|:----------------:|:--------------:|:------------:|
| Working Copy                     | beside main repo |  in main repo  | in main repo |
| Constantly Evolving Dependencies |       easy       |      hard      |   passable   |
| Merging Changes to Dependencies  |       easy       |      hard      |   passable   |
| Contributing Upstream            |       easy       |      easy      |   passable   |
| Continuous Integration           |      medium      |     medium     |     easy     |
| Complex Branch-Based Workflows   |      hard*       |      hard      |     easy     |

(*) This should get better in future versions of git-multirepo.

## Limitations

- git-multirepo should be considered alpha at the moment. All of the core features work as described, though. Suggestions and contributions are welcome.
- The project and its dependencies are beside each other on disk (for now).
- There are currently no features to facilitate main-repo + dependencies branching workflows.
- You must install the tool (`gem install git-multirepo`) on the CI server to perform continuous integration.

## Summary of Commands

## How It Works, In Detail