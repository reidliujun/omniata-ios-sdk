# omniata-ios-sdk

##Features and technical description
Omniata iOS SDK is implemented using Objective-C.

By default SDK does not log anything, i.e. uses SMT_LOG_NONE log level. The method setLogLevel of iOmniataAPI can be used to adjust the log level. When developing and testing a more verbose log level might be useful.
Note the SDK uses NSMutableURLRequest class for the Channel API & Event API communication. The class is rather limited, it doesn't allow setting connection timeout or request timeout.

##Event API 

The iOS SDK automatic adds Event Parameters in om_load events: 
om_device: the device model, obtained by code block:
  size_t size;
    sysctlbyname("hw.machine", NULL, &size, NULL, 0);
    char *machine = malloc(size);
    sysctlbyname("hw.machine", machine, &size, NULL, 0);
    NSString *platform = [NSString stringWithUTF8String:machine];
    free(machine);
    return platform;
om_platform: the platform: ios
om_os_version: the version of the operating system, [[UIDevice currentDevice] systemVersion]
om_sdk_version: the version of the SDK
om_discarded: the cumulative count of events the SDK has discarded, because the delivery has failed.

Additionally information of the application itself is added, check [here](https://developer.apple.com/library/mac/documentation/General/Reference/InfoPlistKeyReference/Articles/CoreFoundationKeys.html#//apple_ref/doc/uid/TP40009249-102364-TPXREF106)   
om_ios_bundle_short_version_string: CFBundleShortVersionString, in XCode " Bundle versions string, short"
om_ios_bundle_version : CFBundleVersion, in XCode "Bundle version"
om_ios_bundle_identifier: CFBundleIdentifier, in XCode "Bundle identifier"

  The SDK automatically adds Event Parameters in all events:
om_delta: the time difference (seconds) between when the event was created and when it was was sent
When the application code asks the SDK to send an event, the event is not immediately sent, instead the event is added to a in-memory queue. A lock is obtained for a very short time while adding.
The persistent storage is located in file tmp/smt.events.log in NSHomeDirectory(). That directory is persisted even if the application is updated.
There is a background thread that periodically (every few seconds) polls the persistent storage for events. If there is an event, and network is reachable, the event is sent.
By default the SDK uses the Reachability library from Apple to determine the network reachability. It's possible to plug-in a custom reachability check, consult the API docs for details.
There's a retry mechanism in the event sending. In the case of event sending fails, the sending system sleeps a certain time and retries. In retried events there is an Event Parameter om_retry having the value of the how many retries have been made so far. If the event sending is retried multiple time, the sleep time between retries is doubled for each retry. When an event is successfully send, the sleep time is reset. The minimum sleep time is one second, i.e. max one event per second is sent. The max sleep is around one minute. 
 The traffic of an event goes to: 
 https://<ORG_NAME>.analyzer.omniata.com/events?api_key=<API_KEY>&uid=<USER_ID>&<PARAMETERS>

##Channel API: 
A Channel API request is made by calling loadMessagesForChannel-method. After it finished, it will save the message in channelEngine.messages, which can be get by using getChannelMessages-method.
 Traffic of a Channel API calling goes to:
 https://<ORG_NAME>.engager.omniata.com/channel?api_key=<API_KEY>&uid=<USER_ID>&channel_id=<CHANNEL_ID>
Installation and upgrade
Add the following frameworks to your project by clicking on your Target, choosing the “Build Phases” tab and using the + button at the bottom of the “Linked Libraries” section.
Foundation
UIKit
SystemConfiguration
AdSupport
Copy the iOmniataAPI.framework to any directory in your app folder.
Drag it to your Xcode project.

##Licenses
3rd party software licenses.
SBJson is used for JSON processing:
/*
 Copyright (C) 2009 Stig Brautaset. All rights reserved.
 
 Redistribution and use in source and binary forms, with or without
 modification, are permitted provided that the following conditions are met:
 
 * Redistributions of source code must retain the above copyright notice, this
   list of conditions and the following disclaimer.
 
 * Redistributions in binary form must reproduce the above copyright notice,
   this list of conditions and the following disclaimer in the documentation
   and/or other materials provided with the distribution.
 
 * Neither the name of the author nor the names of its contributors may be used
   to endorse or promote products derived from this software without specific
   prior written permission.
 
 THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
 AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
 IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
 DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE
 FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
 DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
 SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER
 CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY,
 OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
 OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */
