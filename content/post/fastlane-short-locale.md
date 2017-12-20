---
title: "fastlane Short: UTF-8 Locale Settings"
author: "Manu Wallner"
tags: ["fastlane", "CI/CD", "shell"]
date: 2017-12-08T17:51:16+01:00
---

fastlane needs an environment that is configured to use UTF-8 in your terminal. This article explains the configuration. 

<!--more-->

If you've updated fastlane recently and hadn't set up your environment, or if you've just installed fastlane, you'll probably be familiar with this new warning: 

> WARNING: fastlane requires your locale to be set to UTF-8. To learn more go to https://docs.fastlane.tools/getting-started/ios/setup/#set-up-environment-variables


## How to fix it 

Fixing this issue is simple. There are two environment variables that you need to set before running fastlane:

```bash
export LC_ALL=en_US.UTF-8
export LANG=en_US.UTF-8
```

You can run both of these commands in your terminal before you run fastlane to configure your environment correctly and the warning will be gone. Unfortunately, this only fixes the issue temporarily: if you close the terminal window where you ran those commands, the settings will be gone.


### The quick and easy way

If you trust my shell-scripting abilities and don't have an issue with copying random scripts from people's websites and running them in your terminal, you can run this script: 

```bash
bash -c 'echo -e ".bashrc\n.bash_profile\n.zshrc\n.config/fish/config.fish" | while read f; do if [ -f $HOME/$f ]; then echo -e "export LC_ALL=en_US.UTF-8\nexport LANG=en_US.UTF-8" >> $HOME/$f; fi; done'
```

After you've restarted your terminal you are done with the configuration. You can still read the ['why'](#why-it-is-necessary) if you are curious.

### Manual setup

To set your environment to use UTF-8 permanently yourself instead, you need to edit your shell configuration file. Find out what your shell is by printing the `$SHELL` environment variable, then expand the appropriate section for your shell:

```bash
echo $SHELL
```

<details>
<summary>**bash** (`/bin/bash` or `/usr/local/bin/bash`)</summary>

`bash` has two different files that are commonly in use. On most macOS systems, the file that your bash will be using is `~/.bashrc`. On Linux systems like Ubuntu the file is usually `~/.bash_profile`. You can find out which of the files exists on your system by running: 

```bash
ls ~/.bashrc ~/.bash_profile
```

One of them will give an error message, and you'll know that the other one is the correct file. On my system, the output is: 

```bash
ls: /Users/manu/.bash_profile: No such file or directory
/Users/manu/.bashrc
```

So now I know that `~/.bashrc` is the file I need to edit. This is a hidden file, so you won't be able to get to it with your regular editor. The easiest way is to use the terminal editor `nano`: 

```bash
nano ~/.bashrc
```

Use your arrow keys to navigate to the end of the file (if it isn't empty) and add the two lines from before to it: 

```bash
export LC_ALL=en_US.UTF-8
export LANG=en_US.UTF-8
```

Then press `Ctrl+O` to save and `Ctrl+X` to exit out of `nano`. Restart your terminal and you are done. 

</details>
<details>
<summary>**zsh** (`/usr/local/bin/zsh`)</summary>

The `zsh` configuration file is located at `~/.zshrc`. This is a hidden file, so you won't be able to get to it with your regular editor. The easiest way is to use the terminal editor `nano`: 

```bash
nano ~/.zshrc
```

Use your arrow keys to navigate to the end of the file (if it isn't empty) and add the two lines from before to it: 

```bash
export LC_ALL=en_US.UTF-8
export LANG=en_US.UTF-8
```

Then press `Ctrl+O` to save and `Ctrl+X` to exit out of `nano`. Restart your terminal and you are done. 

</details>
<details>
<summary>**fish** (`/usr/local/bin/fish`)</summary>

With `fish` you don't actually need to edit any configuration files. It is enough to simply run the following command, which will automatically preserve the settings across restarts: 

```bash
set -Ux LC_ALL en_US.UTF-8
set -Ux LANG en_US.UTF-8
```
</details>

## Why it is necessary

The change was introduced by me in this [Pull Request](https://github.com/fastlane/fastlane/pull/10996). Many of the fastlane tools have always required this, but it was never explicitly stated anywhere except in the documentation. 

When looking through the issues we received on GitHub I noticed that a lot of incoming issues were caused at least in part by users not having their environment configured correctly. I made fastlane output a warning so that people could fix these issues without hours of troubleshooting: fastlane is about *saving* time after all. 

The reason for this requirement is that many parts of fastlane interact with web APIs that use UTF-8 or they build on top of other tools that expect content to be encoded in UTF-8, or that send content to fastlane that is encoded in UTF-8. 

When fastlane is interacting with those applications or APIs and the environment is not configured correctly, bad things can happen: things can crash or hang indefinitely, without having any way to show a warning. In the worst case, uploaded data will be wrong. 

