---
title: "Working With fastlane Part 1: Introduction"
author: "Manu Wallner"
tags: ["fastlane", "CI/CD"]
date: 2017-11-11T12:57:08+01:00
---

Welcome to the first part of my series of posts on fastlane. I know there are already a number of such articles out there, but I would still like to give my take on this.
Note that this post is targeted at beginners: the goal is to give an overview of what fastlane is, what problems it tries to solve and how it works.
I will start with the problem that fastlane is trying to solve first.
If you are already familiar with the purpose of fastlane, you can skip the next section [by following this link](#enter-magic).

<!-- more -->

## Getting your app into the store without fastlane

Unless you are an app developer with at least one app on the store, your idea of the app development process probably looks a little something like this: 

1. Have an awesome idea
2. Write some code 
3. Upload your app to the App Store or to Google Play

Unfortunately, that is not the case. At least on Apple's platforms the process looks a little bit more like this:

1. Have an awesome idea
2. Write some code
3. To test your code on your device you need to go to the Apple Developer portal, click a bunch of buttons until you have a certificate, private key, app ID, provisioning profile and your device registered with Apple
4. Distribute the certificate and the private key to your teammates, because the number of certificates you can have is limited
5. Register every other device you intend to use in your team on Apple's website
6. Add your testers to Apple's TestFlight, and redo everything you've done above (certificates, private keys and provisioning profiles) because that was only valid for the development environment
7. Distribute these things to your coworkers as well, because you don't want to be the only one who is able to issue a build to the testers
8. Create the app on iTunes Connect so that you can finally upload the archive you created in Xcode
9. Submit it for review after you and the testers are happy with the build 
    * iTunes Connect is asking for screenshots at this point, which you need to take for every combination of device size and language possible. Currently, you need 5 screenshots per device and there are 7 device form factors, so this number can get very large depending on how many languages you support
10. Fill out the rest of your app's metadata
    * There are a lot of metadata fields that you need to fill out like the description, tags, title, etc. Let's just say that iTunes Connect's interface, while reasonably pretty, is not the most efficient so this will take you a while
11. Finally, submit your app for review and hopefully have it be accepted 

To be fair, Apple is constantly improving this process. It is actually not as arduous as I'm making it sound anymore, because Xcode now also has automatic code signing.  Xcode does its best to figure everything out for you, but like everything Apple creates it is not very configurable and therefore not available or possible for every use case.

Since iOS 10, it has also been possible to reuse screenshots by taking them on only one device, and having them scaled to fit everything else automatically. This is fine for some teams, but teams who want a competitive edge will want to show the user a preview of what their app will actually look like on their device. This is especially important for the iPad and the new iPhone X - no one wants to buy an app only to find out later that it is unoptimized for the screen.

In any case, you can see that it is a lot of work. I know teams that used to have a single person dedicated to retaking screenshots for updates in all the languages they supported - a couple hundred screenshots in that case. I will now show you how we can solve this using fastlane.

## Enter: Magic 🎩

fastlane uses a configuration system with a custom DSL that looks similar to other ruby-based build systems like `rake`. The file that is used to set everything up is called `Fastfile`. Here is a simplified example that does everything that I've described above and more:

```ruby
lane :deploy_appstore do
  match      # Takes care of syncing the developer profile 
  scan       # Runs unit tests 
  snapshot   # Takes screenshots for every (language, device) pair 
  frameit    # Puts the correct device frame around each screenshot 
  gym        # Builds your app for the App Store or TestFlight 
  deliver    # Uploads screenshots, metadata and your built app to the App Store or TestFlight. 
             # deliver also automatically checks if your app might be rejected by Apple
             # e.g. for mentioning a non-Apple platform
end
```

You would run this by simply typing `fastlane deploy_appstore` in your terminal. Everyone on your team can do it, and you can basically do this as often as you want - review times permitting. 

If you are also using fastlane to deploy your apps to *testers* (internal or external) you can even deploy multiple times a day, easily and without a lot of extra work. 
This allows your team to have a fast turnaround time and to get features and bugfixes out to customers very quickly. 

Overall, everyone benefits: customers are happy because they get a frequently updated, well tested app, and you are happy because you don't have to click through a web app and the simulator for half a day every time you want to submit an update to your app. 

### Breaking it down 

Now, let's take a deeper look at the DSL I showed you in the code snippet above. 

At this point you're probably asking yourself "match? scan? gym? What do all these mean?". You see, fastlane is actually not just a simple build tool for mobile applications, it is also a complete set of tools, batteries included! It wasn't always that way, almost all of these tools used to be standalone at some point. Some, like deliver, even predate fastlane entirely. Eventually fastlane was created to bundle them together and to allow the user to easily orchestrate the entire build process using an easy to understand DSL.

We call those commands within the `lane` "Actions" in the fastlane jargon and you can find a list of all supported actions [here](https://docs.fastlane.tools/actions/). Actions are the backbone of fastlane, and they allow you to do almost everything you need for your project:

* Working with git and GitHub
* Running tests and generating test reports
* Integrating with dependency managers like CocoaPods or Carthage
* Updating your project's version and build numbers
* Integrating with 3rd party services like Crashlytics, 
* Sending you notifications to update you on the build status
* And a lot more!

If you are concerned that the things you are using might not be supported by fastlane because they are not in the list of supported actions, you can also take a look at [fastlane plugins](https://docs.fastlane.tools/plugins/available-plugins/). These are 3rd party bundles of actions that are created by the fastlane community. Plugins can be added via your terminal in your project's directory simply by running `fastlane add_plugin <plugin name>` - afterwards all the actions that it includes are available for you in your `Fastfile`.

The next concept we need to talk about are the lanes. A `lane` is basically just like a function in other programming languages, but it is exported and is allowed to be called from the terminal. Just like with functions you can pass parameters, call them from other lanes and return values. This allows you to efficiently split your `Fastfile` into reusable components like this: 

```ruby
lane :sync_codesigning do |opts|
  app_id_suffix = ""

  # If it is an adhoc build, make sure all test devices are registered and add .test to the ID
  if !opts[:appstore]
    register_devices(devices_file: "./test_devices.txt")
    app_id_suffix = ".test"
  end

  # Actually sync the developer profile here
  match(app_identifier: "org.example.app" + app_id_suffix,
                  type: opts[:appstore] ? "appstore" : "adhoc")
end

lane :deploy_testing do
  sync_codesigning(appstore: false)
  # ... 
end

lane :deploy_appstore do
  sync_codesigning(appstore: true)
  # ...
end
```

Like you might've guessed from the snippet above, behind the scenes a `Fastfile` is just ruby code. That means in addition to everything that fastlane provides you also get all the power of ruby. Everything that you can do in ruby you can also do in your `Fastfile`, which gives you lots of control and customization options. Take a look (this is actually [part of the code](https://github.com/milch/supermil.ch/blob/master/fastlane/Fastfile#L6) used to deploy this website):

```ruby
desc "Rebuild the static HTML"
lane :build do
  require 'digest'                                                      

  # 1.
  before = Dir["../public/**/*"].map do |f|
      [f, File.file?(f) ? Digest::SHA2.hexdigest(File.read(f)) : nil]
  end.to_h

  # 2.
  sh "cd .. && hugo"

  # 3.
  Dir["../public/**/*"].select do |f| 
      File.file?(f) && Digest::SHA2.hexdigest(File.read(f)) != before[f]
  end
end
```

This simply uses a ruby gem to calculate the hashes for all the files in the `public/` directory (1), then rebuilds the website using hugo (2) and returns all files which changed during the rebuild (3). The support for regular ruby code is one of the most powerful features of fastlane and also the reason why fastlane does not need to be limited to only mobile projects. With some custom actions it is an excellent tool for deploying simple server projects or websites like this one. 

## Wrapping up

This concludes my first post in this series. I hope I've managed to convince you that fastlane is the way to go when it comes to deploying your app. In the [next post]({{< relref "fastlane-part-2.md" >}}) in this series, we will be getting our hands dirty by actually setting up fastlane and integrating it into an existing app. 

As homework, I'm asking you to take a look at the [fastlane docs](https://docs.fastlane.tools). I know that most people will be thinking that docs are usually boring and hard to understand, which is why you are reading a blog post in the first place. Give me a chance to explain.
 
A lot of care went into creating the fastlane docs. There is a guide for basically every tool and use-case, a detailed explanation of all the parameters you might wanna use with sample code, best practices and everything. 
Hands down, they are some of the best and most comprehensive docs I have ever used. If something can be done with fastlane, it is very likely somewhere on that site and can be found using the search function. 
If it is not, chances are somebody else has already asked: 
The [fastlane GitHub community](https://github.com/fastlane/fastlane/issues) is very active and includes a lot of people asking, answering and otherwise helping with questions.

