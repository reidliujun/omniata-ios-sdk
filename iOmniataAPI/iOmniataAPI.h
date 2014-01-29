#import <Foundation/Foundation.h>

typedef enum {
    SMT_LOG_NONE = 1,
    SMT_LOG_ERROR,
    SMT_LOG_WARN,
    SMT_LOG_INFO,
    SMT_LOG_VERBOSE
} SMT_LOG;

typedef enum{
    CHANNEL_MESSAGE_LOAD_SUCCESS,
    CHANNEL_MESSAGE_LOAD_FAILED
} OMT_CHANNEL_STATUS;

/** This class contains the set of static methods that you can use for event tracking.
 
 This library uses an event processor thread and event uploader thread. The former will iterate through the queue of events added and
 move them to a persistent queue (one that is archived to a file). The latter retrieves the persistent queue and upload them to the server as a batch of events.
 The minimum duration to upload the batch and maximum batch size will be retrieved from the server as a configuration.
 
 */

@interface iOmniataAPI : NSObject
/**---------------------------------------------------------------------------------------
 * @name Initialisation
 *  ---------------------------------------------------------------------------------------
 */
/** Initialize the library to enable event tracking.
 
 This method should be first invoked before using the library for any tracking/ flushing etc. All the thread creation and loading of the
 persisted but not uploaded events are done in this method. Any calls to the other methods of this library will throw Exception.
 Throws NSException if user_id or api_key value is either nil or empty string.
 
 @param user_id The user_id given by the application. This cannot be nil or empty.
 @param api_key The key identifier for the application. This cannot be nil or empty.
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
 
 Use this method to track the load event.Use this to track the first time loading of the application. This method will add the event to the internal event queue and later uploaded to the server when certain batch management criteria are met.
 Throws NSException if called before initialisation call.
 @return BOOL YES for successful event addition for tracking and NO for failure.
 */
+ (BOOL)trackLoadEvent;

/** Append the load event with parameters for tracking.
 
 Use this method to track the load event.Use this to track the first time loading of the application. This method will add the event to the internal event queue and later uploaded to the server when certain batch management criteria are met.
 Throws NSException if called before initialisation call.
 @param parameters NSDictionary containing additional parameters that will be tracked with load event.
 @return BOOL YES for successful event addition for tracking and NO for failure.
 */
+ (BOOL)trackLoadEventWithParameters:(NSDictionary*)parameters;

/** Flush the events.
 
 This is an overriding call to flush all the existing or waiting events queue to the dispatched to the server. When this call is made, all the  batch management criteria
 like upload interval, batch size limit etc are ignored and the internally queued up events will be dispatched immediately.
 */
+ (void)flushEvents;

+ (void)loadMessagesForChannel:(NSUInteger)channelID completionHandler:(void(^)(OMT_CHANNEL_STATUS))completionBlock;

+ (NSArray *)getChannelMessages;
@end