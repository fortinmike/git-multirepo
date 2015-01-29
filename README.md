# git-multirepo

Track multiple Git repositories side-by-side. An alternative approach to manage constantly evolving dependencies.

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
2. Each time you commit the main repo, git-multirepo tracks what revision of each dependency is required by the project (don't worry, it ensures that you don't forget to commit dependencies beforehand; more on that later).
3. If you ever want to go back to a previous version of your project, git-multirepo handles checking out the main repo and appropriate revisions of all of its dependencies in a single, seamless operation.
4. Setting up the project on another machine is only a single `git clone` and `multi install` away.

## Advantages

- Works really well to develop multiple projects that share a common set of constantly evolving dependencies.
- Managing dependencies as totally independent repositories simplifies a lot of things (merges, contributing upstream, etc.) and works well with git GUIs.
- While the repositories are independent, git-multirepo makes sure to track everything that's required to bring back a previous version of your project in a valid state.
- Much more approachable to novice developers than submodules or subtrees.
- Low possibility of human error (such as forgetting to contribute changes back to dependency remotes).
- Works well with CI servers.
- You're not stuck with git-multirepo. It stores its metadata as CSV and YAML in the main repo. You can clone and checkout appropriate revisions of your dependencies by hand without git-multirepo if you need to. The information is there, in human-readable form.

| How It Handles...                |   git-multirepo  | git submodules | git subtrees |
|----------------------------------|:----------------:|:--------------:|:------------:|
| Working Copy                     | beside main repo |  in main repo  | in main repo |
| Constantly Evolving Dependencies |       easy       |      hard      |   passable   |
| Merging Changes to Dependencies  |       easy       |      hard      |   passable   |
| Contributing Upstream            |       easy       |      easy      |   passable   |
| Continuous Integration           |      medium      |     medium     |     easy     |

## Limitations

- git-multirepo is currently a work-in-progress. All of the core features work as described, though.

## Example

## Summary of Commands

## How It Works, In Detail

Check out [the project's to-do list](https://www.pivotaltracker.com/n/projects/1256156).