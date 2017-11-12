---
title: "Introduction to fastlane, part 1"
author: "Manu Wallner"
tags: ["fastlane", "CI/CD"]
date: 2017-11-11T12:57:08+01:00
---

Welcome to the first part of my "Introduction to fastlane" post series. I know there are already a number of such articles out there, but I would still like to give my take on this.  
Note that this series is targeted at beginners: the goal is to give an overview of what fastlane is, what problems it tries to solve and how it works.  
I will start with the problem that fastlane is trying to solve first.  
If you are already familiar with the purpose of fastlane, you can skip ahead [with this link](#enter-magic).

<!-- more -->

<!-- I'd change it to something like "The state of getting your app into the store before fastlane" -->
## The current state of getting your app into the store

Unless you are an app developer with at least one app on the store, your idea of the app development process probably looks a little something like this: 

1. Have an awesome idea
2. Write some code 
3. Upload your app to the App Store or to Google Play

Unfortunately, that is not the case. At least on Apple's platforms the process looks a little bit more like this:
<!-- changed the language of all items to be commanding -->
1. Have an awesome idea
2. Write some code
3. To test your code on your device you need to go to the Apple Developer portal, click a bunch of buttons until you have a certificate, private key, app ID, provisioning profile and your device registered with Apple
4. Distribute the certificate and the private key to your teammates, because the number of certificates you can have is limited
5. Register every device you intend to use in your team on Apple's website
6. Add your testers to Apple's TestFlight, and redo everything you've done above (certificates, private keys and provisioning profiles) because that was only valid for the development environment. 
7. Distribute these things to your coworkers as well, because you don't want to be the only one who is able to issue a build to the testers
8. Create the app on iTunes Connect so that you can finally upload the archive you created in Xcode
9. Submit it for review, after you and the testers are happy with the build 
    * iTunes Connect is asking for screenshots at this point, which you need to take for every combination of device size and language possible. Currently, you need 5 screenshots per device and there are 7 devices, so this number can get very large depending on how many languages you support
10. Fill out the apps metadata
    * There's a lot of metadata fields in there that you need to fill out, like the description, tags, title, etc. Let's just say that iTunes Connect's interface, while reasonably pretty, is not the most efficient
11. Finally, submit your app for review and hopefully have it be accepted 

To be fair, Apple is constantly improving this process. It is actually not as arduous as I'm making it sound anymore, because Xcode now also has automatic code signing.  
Xcode does its best to figure everything out for you, but like everything Apple creates it is not very configurable and therefore not available or possible for every use case.  

Since iOS 10, it has also been possible to reuse screenshots by taking them on one device, and having them scaled automatically. This is fine for small teams, but larger teams will want to gain a competitive edge by offering the user a preview of what the app will look like on their device. 
<!-- I'd change team size to high profile app, a team of 2 can also create great apps (e.g. Tweetbot) -->

In any case, you can see that it is a lot of work.  
I know teams that used to have a single person dedicated to retaking screenshots for updates in all the languages they support. I will now show you how we can solve this using fastlane.

## Enter: Magic

fastlane uses a configuration system with a custom DSL. It looks similar to other ruby-based build systems like `rake`. The file that is used to set everything up is called `Fastfile`. Here is a simplified example that does everything that I've described above and more:

```ruby
lane :deploy_appstore do
  match      # Takes care of syncing the developer profile 
  scan       # Runs unit tests 
  snapshot   # Takes screenshots for every (language, device) pair 
  frameit    # Puts the correct device frame around each screenshot 
  gym        # Builds your app for the App Store or TestFlight 
  deliver    # Uploads screenshots, metadata and your built app to the App Store or TestFlight. 
  # deliver also automatically checks if your app might be rejected by Apple, e.g. for mentioning a non-Apple platform
end
```

You would run this by simply typing `fastlane deploy_appstore` in your terminal.  
Everyone on your team can do it, and you can basically do this as often as you want - review times permitting. 

<!-- I highlighted testers because I overlooked it at first, which caused me to question how that would work when the app is submitted to the app store multiple times per day -->
If you are also using fastlane to deploy your apps to **testers** (internal or external) you can even deploy multiple times a day, easily and without a lot of extra work.  
This allows your team to have a fast turnaround time and to get features and bugfixes out to customers very quickly. 

Overall, everyone benefits: customers are happy because they get a frequently updated, well tested app, and you are happy because you don't have to click through a web app for half a day every time you want to submit an update to your app. 

## Breaking it down 

Now, let's take a deeper look at the DSL I showed you in the code snippet above. 

At this point you're probably asking yourself "match? scan? gym? What do all these commands mean?".  
You see, fastlane is actually not just a simple build tool for mobile applications, it is also a complete set of tools, batteries included! 

All these words - called "Actions" in the fastlane-lingo - are separate tools that come bundled as part of fastlane.  
You can find a list of all supported actions [here](https://docs.fastlane.tools/). 

The next concept we need to talk about are `lane`s. A `lane` is basically just a function in your Fastfile, except that you can call **What??**

Behind the scenes, a `Fastfile` is just ruby code. That means in addition to everything that fastlane provides you also get all the power of ruby. You can do everything that you would be able to do in ruby. Take a look (this is actually part of the code used to deploy this website):

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

This simply uses a ruby gem to calculate the hashes for all the files in the `public/` directory (1), then rebuilds the website (2) and returns all files which changed during the rebuild (3).

## Wrapping it up

This concludes my first post in this series. 

<!-- the "No, wait!" is a bit confusing: I believe you meant "wait before you leave and call me a lunatic for making you read the docs" -->
As homework, I'm asking you to take a look at the [fastlane docs](https://docs.fastlane.tools).   
I know that most people will be thinking that docs are boring and hard to understand, which is why you are reading a blog post in the first place. But this is not the case for the fastlane docs!
 
A lot of care went into creating the fastlane docs. There is a guide for basically every tool and use-case, a detailed explanation of all the parameters you might wanna use with sample code, best practices and everything.  
<!-- if something can be done with fastlane -->
Hands down, they are some of the best and most comprehensive docs I have ever used. If something can be done with fastlane, it is very likely somewhere on that site and can be found using the search function.  
If it is not, chances are somebody else has already asked:  
The [fastlane GitHub community](https://github.com/fastlane/fastlane/issues) is very active and includes a lot of people asking, answering and otherwise helping with questions.

In the next post in this series, we will be getting our hands dirty by actually setting up fastlane and integrating it into an existing app. 
