#  Saftellite 

A satellite messenger for iOS 

<img src="./AppIcon.png" height=200px>

## What can it do? 

With *Saftellite* you can send SMS-like messages using the satellite connectivity of your iPhone 14 or newer on iOS 16. It works in all countries that support satellite connectivity and Find My locatio sharing over satellite. No iMessage over satellite or iOS 18 is required. 

## What do I need for it? 

You need an iPhone 14 (or newer) with a jailbreak on it. At the time of release, you can jailbreak up to iOS 16.6.1 with [Dopamine](https://github.com/opa334/Dopamine). At best, the recipient also uses a jailbroken iPhone with the Saftelite app installed. The recipient does not need to have an iPhone with satellite connectivity as messages can only be received over the internet.

## Who can receive my message? 

All friends with whom you share your location over Find My can receive messages. We use Find My location updates over satellite to send your message instead of a location. 

## How do I install the app?

We don't offer a Cydia/Zebra/Sileo package at the moment. The easiest way is to build the app using Xcode, then resign the binary with the necessary entitlements: Run the `$ create_ipa.sh` script. 
Then share the `.tipa` or `.ipa` to your jailbroken and install it on your jailbroken iPhone using [TrollStore](https://github.com/opa334/TrollStore).

## How do I install the tweak? 

To send satellite messages, you will need a tweak that hooks into the satellite connectivity system. 

Get the tweak binary which is the `.deb` file in `SendStewieMessageTweak/packages`. Then install it by opening it on your iPhone with Sileo or using `dpkg`.   

You can also build the tweak with [theos](https://github.com/theos/theos) by running the make file in the `SendStewieMessageTweak` folder. 

## How long can a message be? 

Apple has limited the length to 82 bytes, aka 82 characters (in ASCII). 

## Can I send Emojis? 

Yes but they need more bytes 

## Why *Saftellite* 
We could not come up with a better name and we got tired... But also Apple uses `SFT` as a short term for satellite related messages and we found it funny. 

## Authors 

Jiska Classen, Research Group Leader @ HPI Potsdam 
Alexander Heinrich, Security Researcher @ SEEMOO, TU Darmstadt
