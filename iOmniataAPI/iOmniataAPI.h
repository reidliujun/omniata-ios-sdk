#import <Foundation/Foundation.h>

//#define DEVELOPMENT

typedef enum {
    SMT_LOG_NONE = 1,
    SMT_LOG_ERROR,
    SMT_LOG_WARN,
    SMT_LOG_INFO,
    SMT_LOG_VERBOSE
} SMT_LOG;

typedef enum {
    CHANNEL_MESSAGE_LOAD_SUCCESS,
    CHANNEL_MESSAGE_LOAD_FAILED
} OMT_CHANNEL_STATUS;

/**
 * The different end results of an event sending.
 */
typedef enum {
    EVENT_SUCCESS,
    EVENT_FAILED,
    EVENT_DISCARDED
} OMT_EVENT_STATUS;


typedef void (^EventCallbackBlock)(NSDictionary* event, OMT_EVENT_STATUS status, NSUInteger retry);

/** This class contains the set of static methods that you can use for event tracking.
 
 This library uses an event processor thread and event uploader thread. The former will iterate through the queue of events added and
 move them to a persistent queue (one that is archived to a file). The latter retrieves the persistent queue and upload them to the server as a batch of events.
 The minimum duration to upload the batch and maximum batch size will be retrieved from the server as a configuration.
 
 3rd party licenses:
 
 SBJson
 
 Copyright (C) 2009-2011 Stig Brautaset. All rights reserved.
 
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

@interface iOmniataAPI : NSObject
/**---------------------------------------------------------------------------------------
 * @name Initialisation
 *  ---------------------------------------------------------------------------------------
 */
/** Initialize the library to enable event tracking.
 
 This method should be first invoked before using the library for any tracking etc. All the thread creation and loading of the
 persisted but not uploaded events are done in this method. Any calls to the other methods of this library will throw Exception.
 Throws NSException if user_id or api_key value is either nil or empty string.
 
 The eventCallbackBlock-block is called after an event has been succesfully sent (EVENT_SUCCESS),
 after an event sending failed (EVENT_FAILED) and after an event has been discarded after too many retries (EVENT_DISCARDED).
 The set callback doesn't survive app restart, i.e. after app restart no callback is set (if not explicitely set).
 Because of that the application code cannot assume that the callback is called for events that are tracked after setEventCallback is called -
 it is possible that after calling setEventCallback, events are tracked, and the app is stopped and restarted and the events are sent w/o callback.
 
 @param user_id The user_id given by the application. This cannot be nil or empty.
 @param api_key The key identifier for the application. This cannot be nil or empty.
 @param eventCallbackBlock The EventCallbackBlock to receive information of event sending success and failures. Can be nil.
 */
+ (void)initializeWithApiKey:(NSString *)api_key UserId:(NSString *)user_id AndDebug:(BOOL)debug EventCallbackBlock:(EventCallbackBlock) eventCallbackBlock;

/**
 Calls initializeWithApiKey with EventCallbackBlock nil.
 */
+ (void)initializeWithApiKey:(NSString *)api_key UserId:(NSString *)user_id AndDebug:(BOOL)debug;


/**---------------------------------------------------------------------------------------
 * @name Debugging
 *  ---------------------------------------------------------------------------------------
 */
/** Set the logging level
 
 This method sets the Logging Level for the trace messages. The default value is set to SMT_LOG_NONE. This method can be called pre-initialize as well.
 
 @param logLevel The verbosity and severity level of the traces.
 The possible values are
 SMT_LOG_NONE
 SMT_LOG_ERROR
 SMT_LOG_WARN
 SMT_LOG_INFO
 SMT_LOG_VERBOSE
 */
+ (void)setLogLevel:(SMT_LOG)logLevel;

/** Sets the current Api Key
 
 After setting this all events moving forward will utilize this api key.
 */
+ (void)setApiKey:(NSString*)api_key;

/** Set the current user id
 
 After setting this all events moving forward will utilize this user id.
 */
+ (void)setUserId:(NSString*)user_id;

/** Sets a callback for event sending.
 */
+ (void)setEventCallback:(EventCallbackBlock) eventCallback;

/**---------------------------------------------------------------------------------------
 * @name Tracking
 *  ---------------------------------------------------------------------------------------
 */
/** Append the event for tracking.
 
 Use this method to track an application specific events. This method will add the event to the internal event queue and later uploaded to the server when certain batch management criteria are met.
 Throws NSException if called before intialization call or eventParams is nil.
 @param type The type of event being tracked.
 @param eventParams The non-nil event parameters as a NSDictionary.
 @return BOOL YES for successful event addition for tracking and NO for failure.
 */
+ (BOOL) trackEvent:(NSString*)type :(NSDictionary *) eventParams;

/** Append the purchase event for tracking.
 
 Use this method to track any purchase events. This method will add the event to the internal event queue and later uploaded to the server when certain batch management criteria are met.
 Throws NSException if called before intialization call, amount <= 0 and currency_code not among the ISO Currency Code.
 
 @param amount The amount in double that you need to track. Must be greater than 0.
 @param currency_code Optional NSString for the iso defined 3 alphabet currency_code. If nil is passed then it defaults to "USD"
 @return BOOL YES for successful event addition for tracking and NO for failure.
 */
+ (BOOL)trackPurchaseEvent:(double)amount currency_code:(NSString *)currency_code;

/** Append the purchase event for tracking.
 
 Use this method to track any purchase events. This method will add the event to the internal event queue and later uploaded to the server when certain batch management criteria are met.
 Throws NSException if called before intialization call, amount <= 0 and currency_code not among the ISO Currency Code.
 
 @param amount The amount in double that you need to track. Must be greater than 0.
 @param currency_code Optional NSString for the iso defined 3 alphabet currency_code. If nil is passed then it defaults to "USD"
 @param additional_params Optional NSDictionary containing additional parameters for tracking
 @return BOOL YES for successful event addition for tracking and NO for failure.
 */
+ (BOOL)trackPurchaseEvent:(double)amount currency_code:(NSString *)currency_code additional_params:(NSDictionary*)additional_params;

/** Append the load event for tracking.
 
 Use this method to track the load event. Use this to track the first time loading of the application. This method will add the event to the internal event queue and later uploaded to the server when certain batch management criteria are met.
 Throws NSException if called before initialisation call.
 @return BOOL YES for successful event addition for tracking and NO for failure.
 */
+ (BOOL)trackLoadEvent;

/** Append the load event with parameters for tracking.
 
 Use this method to track the load event. Use this to track the first time loading of the application. This method will add the event to the internal event queue and later uploaded to the server when certain batch management criteria are met.
 Throws NSException if called before initialisation call.
 @param parameters NSDictionary containing additional parameters that will be tracked with load event.
 @return BOOL YES for successful event addition for tracking and NO for failure.
 */
+ (BOOL)trackLoadEventWithParameters:(NSDictionary*)parameters;

+ (void)loadMessagesForChannel:(NSUInteger)channelID completionHandler:(void(^)(OMT_CHANNEL_STATUS))completionBlock;

+ (NSArray *)getChannelMessages;

/** Set a custom network reachability check. By default the code from Reachability sample application from Apple (v 3.5) is used for the check.
 * If your application e.g. has a always connected socket, you're application knows better than Reachability whether the network is available.
 * The block needs to be non-blocking, because it's call within the Channel API a call and should not block that. It also needs to be thread-safe.
 */
+ (void)setReachability:(BOOL(^)(void))reachability;

@end
