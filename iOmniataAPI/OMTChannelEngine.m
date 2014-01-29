#import "OMTChannelEngine.h"
#import "OMTUtils.h"
#import "OMTConfig.h"


@implementation OMTChannelEngine
@synthesize messages, loadingMessages;
- (id)init {
    self = [super init];
    if (self) {
        loadingMessages = NO;
        OMTConfig *config = [OMTConfig instance];
        maxRetries = config.maxRetriesForChannelMessages;
        channelURL = [NSString stringWithFormat:@"%@%@&%@=", [config getURL:SMT_SERVER_CHANNEL],config.userParams,EVENT_POST_KEY_CHANNEL_ID];

    }
    return self;
}

- (void)loadMessagesForChannel:(NSUInteger)channelID completionHandler:(void (^)(OMT_CHANNEL_STATUS))completionBlock {
    if (self.loadingMessages) {
        LOG(SMT_LOG_INFO, @"CHANNEL API: load call skipped as one call is under process");
    }
    else {
        LOG(SMT_LOG_VERBOSE, @"CHANNEL API: Initiating loadMessagesForChannel");
        [self loadMessages:channelID completionHandler:completionBlock];
    }
}

  //jijo :  THis method needs refactoring.....
- (void)loadMessages:(int)channelID completionHandler:(void (^)(OMT_CHANNEL_STATUS))completionBlock {
      loadingMessages = YES;
      __block __weak OMTChannelEngine* weakSelf = self;
    __block NSUInteger retryCount = 0;
    if ([OMTUtils connectedToNetwork]) {
        NSString *urlStr = [NSString stringWithFormat:@"%@%d",channelURL,channelID];
        NSURL *url = [NSURL URLWithString:urlStr];
        NSMutableURLRequest *urlRequest = [[NSMutableURLRequest alloc] initWithURL:url cachePolicy:NSURLCacheStorageNotAllowed timeoutInterval:10];
        NSOperationQueue *operationQueue = [[NSOperationQueue alloc] init];
        [urlRequest setValue:@"application/x-www-form-urlencoded" forHTTPHeaderField:@"Content-type"];
        [NSURLConnection sendAsynchronousRequest:urlRequest queue:operationQueue
                               completionHandler:^(NSURLResponse *response, NSData *data, NSError *error) {
                                   BOOL isSuccess = NO;
                                   NSArray *_msgs = nil;
                                   if (error) {
                                       LOG(SMT_LOG_ERROR, @"CHANNEL API: Error getting Channel Messages: %@", [error description]);
                                   }
                                   else {
                                       NSInteger responseCode = [(NSHTTPURLResponse *) response statusCode];
                                       LOG(SMT_LOG_INFO, @"CHANNEL API: HTTP_RESPONSE: %d", responseCode);
                                       if (data != nil && [data length] > 0) {
                                           LOG(SMT_LOG_VERBOSE, @"CHANNEL API: Processing response");
                                           NSError *jsonError;
                                           NSDictionary *responseDict = [NSJSONSerialization JSONObjectWithData:data options:0 error:&jsonError];
                                           if (jsonError) {
                                               LOG(SMT_LOG_VERBOSE, @"CHANNEL API: Error parsing json data %@", [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding]);
                                           }
                                           else {
                                               _msgs = [responseDict objectForKey:CHANNEL_DATA_JSON_CONTENT];
                                               isSuccess = YES;
                                           }
                                       }
                                       else {
                                           LOG(SMT_LOG_WARN, @"CHANNEL API: Empty response from server");
                                       }
                                   }
                                   if (!isSuccess)
                                   {
                                       LOG(SMT_LOG_INFO, @"CHANNEL API:****RETRY INITIATED****");
                                       while(retryCount < maxRetries)
                                       {
                                           retryCount++;
                                           LOG(SMT_LOG_INFO, @"CHANNEL API: Retry Attempt %d",retryCount);
                                           @try {

                                               NSURLResponse *response1;
                                               NSError *error1;
                                               NSData *conData;


                                               conData = [NSURLConnection sendSynchronousRequest:urlRequest returningResponse:&response1 error:&error1];
                                               if (conData == nil) {
                                                   LOG(SMT_LOG_ERROR, @"CHANNEL API: Connection failed");
                                               }
                                               else {
                                                   if (response1 != nil) {
                                                       NSInteger responseCode = [(NSHTTPURLResponse *) response1 statusCode];
                                                       LOG(SMT_LOG_INFO, @"Response Code %d", responseCode);
                                                       if (responseCode == HTTP_OK) {
                                                           NSString *responseStr = [[NSString alloc] initWithData:conData encoding:NSUTF8StringEncoding];
                                                           if (responseStr != nil && [responseStr length] > 0) {
                                                               LOG(SMT_LOG_VERBOSE, @"CHANNEL API: Processing response");
                                                               NSError *jsonError;
                                                               NSData *data1 = [responseStr dataUsingEncoding:NSUTF8StringEncoding];
                                                               NSDictionary *responseDict = [NSJSONSerialization JSONObjectWithData:data1 options:0 error:&jsonError];
                                                               if (jsonError) {
                                                                   LOG(SMT_LOG_ERROR, @"CHANNEL API: Error parsing json data %@", responseStr);
                                                               }
                                                               else {
                                                                   _msgs = [responseDict objectForKey:CHANNEL_DATA_JSON_CONTENT];
                                                                   isSuccess = YES;
                                                                   LOG(SMT_LOG_INFO, @"CHANNEL API: Sucessfully loaded channel data");
                                                               }
                                                           }
                                                           else {
                                                               LOG(SMT_LOG_ERROR, @"CHANNEL API: Empty response from server");
                                                           }
                                                       }
                                                       else {
                                                           LOG(SMT_LOG_ERROR, @"CHANNEL API: URL Returned Error");
                                                       }
                                                   }
                                                   else {
                                                       LOG(SMT_LOG_ERROR, @"CHANNEL API: Empty response from server");
                                                   }
                                               }
                                           }
                                           @catch (NSException *exception1) {
                                               LOG(SMT_LOG_ERROR, @"CHANNEL API : Exception occurred while connecting : %@", [exception1 userInfo]);
                                           }
                                           if (isSuccess)break;
                                       }
                                   }
                                   if (isSuccess)
                                   {
                                       [weakSelf setMessages:_msgs];
                                   }
                                   loadingMessages = NO;
                                   OMT_CHANNEL_STATUS status = isSuccess ? CHANNEL_MESSAGE_LOAD_SUCCESS : CHANNEL_MESSAGE_LOAD_FAILED;
                                   dispatch_sync(dispatch_get_main_queue(), ^(void) {
                                       completionBlock(status);
                                   });
                               }];
    }
    else {
        LOG(SMT_LOG_WARN, @"CHANNEL API: No Connectivity");
        dispatch_async(dispatch_get_main_queue(), ^(void) {
            completionBlock(CHANNEL_MESSAGE_LOAD_FAILED);
        });
    }
}

-(void) setMessages:(NSArray *)array
{
   messages = array;
}

- (void)dealloc {
    messages = nil;
}

@end