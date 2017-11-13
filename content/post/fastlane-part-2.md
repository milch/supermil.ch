---
title: "Working With fastlane Part 2: Integrating fastlane"
author: "Manu Wallner"
tags: ["fastlane", "CI/CD"]
date: 2017-11-13T14:42:06+01:00
---

In this post, we will take a look at how to integrate fastlane into your iOS app. This guide is for iOS, but the process should be similar on Android as well.

<!--more-->

We will go through the complete setup, and I will give you insights into the best practices with fastlane. This is the second post in the series, so if you are not sure yet whether fastlane is for you, check out the [first post]({{< relref "fastlane-part-1.md" >}}). So start your terminals and get ready!

## Installation

To get started with fastlane, you need to install it first. There are multiple ways to do this, which you can find in the [documentation here](https://docs.fastlane.tools/getting-started/ios/setup/#choose-your-installation-method). To start things off, you need to have Xcode installed, which is easy enough from the terminal:

```bash
xcode-select --install
```

Next, install fastlane using [homebrew](https://brew.sh):

```bash
brew cask install fastlane
```

This is my preferred installation method. It has the advantage of coming with a complete, self-contained ruby installation and all required dependencies baked in. This way is the most likely to work for your setup, but there are some cases where other installation methods might be a better option. You can check out the docs link above if homebrew doesn't work for you. After this, you are ready to start using fastlane.

## Getting Started

As we saw in my last post, fastlane is mostly controlled through a configuration file - the `Fastfile` - in a `fastlane/` subfolder in your project directory. You can create this folder and the `Fastfile` manually if you want, but for the purpose of this guide we will let fastlane do the work for us. In your project directory, run:

```bash
fastlane init
```

fastlane will proceed to ask you a bunch of questions about your project, as well as your Apple ID and password. As soon as you confirm your app's bundle ID, a couple things will happen: 

1. If your app doesn't exist on the Apple Developer portal or on iTunes Connect, `produce` will create it
2. Any existing metadata from iTunes Connect will be downloaded by `deliver` 
3. Your project settings will be detected by `fastlane`, or you will be asked to enter them manually if this is not possible, and a `Fastfile` will be created for you

Note that fastlane will always save your credentials in your system's keychain after you've entered them for the first time. If you do not want that, you can also set your username and password by setting the `FASTLANE_USER` and `FASTLANE_PASSWORD` environment variables. 

Let's take a look at everything that fastlane has created for us:

<img src="/images/fastlane-part-2/fastlane-dir.png" alt="fastlane directory, with Appfile, Deliverfile, Fastfile and metadata and screenshots folders">

We can see that there is the `Fastfile` that we've talked about, but also an `Appfile` and `Deliverfile`. The [Appfile](https://docs.fastlane.tools/advanced/#appfile) is a special kind of configuration file that is used by all the tools included in fastlane. It contains general project information like the Apple ID you entered for this project, the bundle ID and your team's ID. You can ignore the `Deliverfile` since you are using fastlane. 

The `metadata` and `screenshots` folders contain everything that `deliver` managed to download from iTunes Connect. All the files in the `metadata` folder are simple text files. This allows you to check in all your metadata into your SCM and treat it just like source code. How neat is that? 

Before we go on, it's helpful to add the following lines to your `.gitignore` file in your project directory. fastlane creates some temporary files which you probably don't want to go into your repository:

```sh
# fastlane specific
fastlane/report.xml

# deliver temporary files
fastlane/Preview.html

# snapshot generated screenshots
fastlane/screenshots

# scan temporary files
fastlane/test_output
```

## Configuring fastlane

If we take a look at the generated `Fastfile` we can see that it already includes some lanes and some other configuration. Something that we haven't discussed yet in my last post when I was talking about the DSL is the platform block, but it's really simple - it just scopes all the lanes in it to a single platform. For a multi-language project or a monorepo, this allows you to have a single `Fastfile` to support all the platforms your project supports. Consequently, you would call those lanes from your command line with `fastlane <platform> <lane>`. 

Right off the bat, I would suggest you uncomment the line `update_fastlane` at the beginning. This will ensure that your fastlane is always up to date every time you run it, which is important because fastlane depends on Apple's webservers - which tend to have breaking API changes frequently and unexpectedly. 

### Setting up the Xcode project for fastlane

To actually compile your project, fastlane will need access to your project's schemes. Check that you are sharing your schemes by opening Xcode, and clicking on `Product > Scheme > Manage Schemes...` in your menu bar. Make sure all the boxes are ticked:

<img src="/images/fastlane-part-2/schemes.png" alt="Xcode Scheme Editor, with 'Autocreate Schemes' and 'Shared' enabled for the project">

Next, we want to setup fastlane to be able to manipulate version information. We can get the information how to do this [directly from Apple](https://developer.apple.com/library/content/qa/qa1827/_index.html), but it is a straightforward process:

- In Xcode, click on your project file to open the project's settings
- Under `Targets` click on your app, then go to the `Build Settings` tab
- Make sure "All" is selected so you see all options
- Type "Versioning" into the search bar
- Set `Current Project Version` to 1 (or any number that you want to start with) and `Versioning System` to "Apple Generic"
- Go to the `Info` tab and make sure that `Bundle versions string, short` and `Bundle version` are both set

### Making it useful

Now we can explore the pre-existing lanes. If you run `fastlane lanes` you will get a list of all of them. The `beta` and `release` lanes will most likely not work right away, but you can try running the `test` lane. As a reward, you will get some nice output hopefully showing you that all your tests passed. This will give you a feel of how fastlane works and how it looks like. 

#### Screenshots

To get automatic screenshot creation, you need to use Xcode UI tests. If you aren't using them already, you can simply add them by clicking on your project file in Xcode and clicking on `Editor > New Target...` in the menu bar. Scroll down until you find `iOS UI Testing Bundle` and add it to your project. Now, we can let fastlane set everything up for us: 

```bash
fastlane snapshot init
```

This will create two new files in your fastlane directory - the `Snapfile` and `SnapshotHelper.swift`. Everything you need to know about the `Snapfile` is explained inside, so take a look at it. You should set all the languages that you want screenshots for as well as the list of devices by uncommenting the respective lines. Now go back to Xcode and add the `SnapshotHelper` to your UI test target:

- Click on your project file to bring up the project settings
- Under `Targets`, select your UI test target
- Go to the `Build Phases` tab
- Expand `Compile Sources` and click the + icon 
- Click `Add Other...` in the bottom left
- Navigate to the fastlane folder in your project directory and add `SnapshotHelper`. Make sure that `Copy Items If Needed` is not checked

<video autoplay loop muted>
<source type="video/mp4" src="/images/fastlane-part-2/snapshot-xcode.mp4">
</video>

#### Code Signing

Let's address the elephant in the room: code signing. In the last post I promised a simple to command that takes care of everything. 

### Completing the configuration

After you're done with the previous steps, make sure to commit your changes to your SCM. At this point you can also add a `before_all` block at the start of your `Fastfile` to make sure no one deploys a new version with uncommitted changes:

```ruby
before_all do
  ensure_git_status_clean
end
```
