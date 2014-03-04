#import "OMTConstants.h"

//GENERAL
NSString *const SDK_VERSION = @"ios-1.0.1";
NSString *const iOMNIATA = @"iOmniataAPI";

NSString *const EVENT_POST_KEY_TYPE = @"type";
NSString *const EVENT_POST_KEY_TOTAL = @"total";
NSString *const EVENT_POST_VAL_TYPE_LOAD = @"load";
NSString *const EVENT_POST_VAL_TYPE_REVENUE = @"revenue";
NSString *const EVENT_POST_VAL_DEFAULT_CURRENCY = @"USD";
NSString *const EVENT_POST_KEY_REF_CODE = @"ref_code";
NSString *const EVENT_POST_KEY_REF_UID = @"ref_uid";
NSString *const EVENT_POST_KEY_REF_APP_KEY = @"ref_app_key";
NSString *const EVENT_POST_KEY_TIME = @"time";
NSString *const EVENT_LOG_FILE_NAME = @"smt.events.log";
NSString *const EVENT_LOG_FILE_DIR =  @"tmp";
NSUInteger const EVENT_PROCESSOR_THREAD_DELAY = 1;
NSUInteger const EVENT_PROCESSOR_RETRY_CONNECTIVITY_DELAY = 16;
NSUInteger const EVENT_PERSIST_THREAD_DELAY = 1;
NSString* const EVENT_POST_KEY_EVENT = @"events";
NSString* const EVENT_POST_KEY_USER_PARAMS = @"usr_params";
NSString* const EVENT_POST_KEY_API_KEY = @"api_key";
NSString* const EVENT_POST_KEY_USER_ID = @"uid";
NSString* const EVENT_POST_KEY_CHANNEL_ID = @"channel_id";
NSString* const EVENT_POST_KEY_USER_AGENT_MODEL = @"useragent_model";
NSString* const EVENT_POST_KEY_USER_AGENT_OS = @"useragent_os";
NSString* const EVENT_POST_KEY_CLIENT_VERSION  = @"olib_client_ver";
NSUInteger const INTERNAL_SERVER_ERROR = 500;
NSUInteger const HTTP_OK = 200;
NSUInteger const HTTP_BAD_REQUEST = 400;
NSUInteger const SLEEP_TIME = 1;
NSUInteger const MAX_SLEEP = 64;
NSString *const ERROR = @"ERROR";
NSString *const OM_DISCARDED = @"om_discarded";


//SERVER
NSString *const ROOT_URL = @"https://api.omniata.com/";
#ifdef DEVELOPMENT
NSString *const TEST_URL = @"http://localhost:8000/";
#else
NSString *const TEST_URL = @"http://api-test.omniata.com/";
#endif
NSString *const EVENTS_TRACK_SUB_URL = @"event";
NSString *const CONFIG_SUB_URL = @"get_conf?";
NSString *const CHANNEL_MSGS_SUB_URL = @"channel?";

//CONFIG
NSString *const CONFIG_JSON_MAX_TRACK_RETRIES = @"max_track_retries";
NSString *const CONFIG_JSON_MAX_CHANNEL_RETRIES = @"max_channel_retries";
NSString *const CONFIG_JSON_MAX_BATCH_SIZE = @"max_batch_size";
NSString *const CONFIG_JSON_BATCH_DELAY = @"max_batch_delay";
NSString *const CHANNEL_DATA_JSON_CONTENT = @"content";

//DEBUG
//set this to true if you need to load the config from a json file. This is just for testing and should be disabled while releasing.
BOOL const LOAD_CONFIG_INTERNAL = NO;