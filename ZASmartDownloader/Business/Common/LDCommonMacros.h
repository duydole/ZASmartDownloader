//
//  LDCommonMacros.h
//  ZASmartDownloader
//
//  Created by Do Le Duy on 10/22/20.
//  Copyright © 2020 vng. All rights reserved.
//

#import <UIKit/UIKit.h>
#ifndef LDCommonMacros_h
#define LDCommonMacros_h

/// Syncthesize singleton for a Class
///
#define SYNTHESIZE_SINGLETON_FOR_CLASS(classname)               \
\
+ (classname *)shared##classname {                              \
        static dispatch_once_t pred;                            \
        static classname * shared##classname = nil;             \
        dispatch_once( &pred, ^{                                \
            shared##classname = [[self alloc] init];            \
        });                                                     \
        return shared##classname;                               \
}

#define ASSERT_USE_NSASSERT 0

#if DEBUG && ASSERT_USE_NSASSERT
#define TB_ASSERT(condition) NSAssert(condition, @"Error")
#define ASSERT_FAILED NSAssert(NO, @"Error");
#else
#define TB_ASSERT(condition)
#define ASSERT_FAILED
#endif

#if defined(__cplusplus)
#define ZA_EXTERN extern "C"
#else
#define ZA_EXTERN extern
#endif

#define TOSTR_(x...) #x    //char*
#define NSStringize(x...) @TOSTR_(x) //NSStr

#define CHECK_CLASS(obj, Type)       ([obj isKindOfClass:[Type class]])
#define CHECK_NULL_CLASS(obj, Type)  (obj && CHECK_CLASS(obj,Type))
#define CHECK_DELEGATE(delegateObj, selectorObj)  (delegateObj && [delegateObj respondsToSelector:selectorObj])
#define CHECK_SELECTOR(Obj, selectorObj) CHECK_DELEGATE(Obj, selectorObj)
#define IS_NONEMPTY_STRING(str)      (str && [str isKindOfClass:[NSString class]] && ((NSString*)str).length>0)
#define IS_NONEMPTY_ARRAY(arr)       (arr && [arr isKindOfClass:[NSArray class]] && ((NSArray*)arr).count>0)
#define IS_EMPTY_ARRAY(arr)       (!IS_NONEMPTY_ARRAY(arr))
#define IS_NONEMPTY_DICTIONARY(dict)       (dict && [dict isKindOfClass:[NSDictionary class]] && ((NSDictionary*)dict).count>0)
#define ITERATE_ARRAY(Type, obj, array)             for(Type* obj in array)
#define ITERATE_ARRAY_TYPESAFE(Type, obj, array)    for(Type* obj in array) if(CHECK_CLASS(obj,Type))
#define LOG_AND_ASSERT_FAILURE(error)        { NSLog(@"Error: %@", error.description); }
#define ELSE_FAILED                  else { ASSERT_FAILED };
#define NOT_IMPLEMENTED_YET          //NSAssert(false,@"Not implemented yet!");
#define MACRO_VALIDATE_IDSTRING_RETURN(userId, returnType)  if(!CHECK_NULL_CLASS(userId, NSString) || userId.length==0) { ASSERT_FAILED; return returnType; }
#define MACRO_VALIDATE_NULL_RETURN(pointer, returnType)  if(pointer==NULL) {ASSERT_FAILED; return returnType; }
#define MACRO_VALIDATE_IDSTRING_NOTRETURN(userId)  if(!CHECK_NULL_CLASS(userId, NSString) || userId.length==0) { ASSERT_FAILED; }
#define NONRETAIN_VALUE(pointer) [NSValue valueWithPointer:pointer]
#define NSArrayObjectMaybeNil(__ARRAY__, __INDEX__) ((__INDEX__ >= [__ARRAY__ count]) ? nil : [__ARRAY__ objectAtIndex:__INDEX__])

#define NOT_IMPLEMENT_YET  UX_CONSOLE_LOGGER(@"ERROR: not implemented: %s!!",__func__);
#define LOG_FUNC       UX_CONSOLE_LOGGER(@"");
#define LOG_FUNC_BEGIN UX_CONSOLE_LOGGER(@"Begin ");
#define LOG_FUNC_END   UX_CONSOLE_LOGGER(@"End ");

#define OBJC_DYNAMIC_CAST(obj, Type) (CHECK_NULL_CLASS(obj, Type)? obj:nil)
#define WEAKSELF __weak typeof(self) weakSelf = self;
#define STRONGSELF __strong typeof(weakSelf) strongSelf = weakSelf; if (strongSelf == nil) return;
#define STRONGSELF_RET_NIL __strong typeof(weakSelf) strongSelf = weakSelf; if (strongSelf == nil) return nil;
#define STRONGSELF_IF_NIL_RETURN_NIL __strong __typeof(weakSelf) strongSelf = weakSelf; if (strongSelf == nil) return nil;
#define STRONGSELF_RETURN(obj) __strong __typeof(weakSelf) strongSelf = weakSelf; if (strongSelf == nil) return obj;
#define MakeWeakSelf() __weak typeof(self) weakSelf = self;
#define MainThreadAssertion()     NSAssert([NSThread isMainThread], @"Must be used on main thread!")

#define DECLARE_SHARED_INSTANCE(classname)                          \
                    static classname* _instance = nil;              \
                    static dispatch_once_t  _onceToken = 0;         \
                    +(instancetype)shared##classname                \
                    {                                               \
                        dispatch_once(&_onceToken, ^{               \
                            _instance = [[classname alloc] init];   \
                        });                                         \
                        return _instance;                           \
                    }                                               \
                    +(void) cleanInstance                           \
                    {                                               \
                        _onceToken = 0;                             \
                        _instance = nil;                            \
                    }

/* Custom Hashing
 * https://www.mikeash.com/pyblog/friday-qa-2010-06-18-implementing-equality-and-hashing.html
 */
#define NSUINT_BIT (CHAR_BIT * sizeof(NSUInteger))
#define NSUINTROTATE(val, howmuch) ((((NSUInteger)val) << howmuch) | (((NSUInteger)val) >> (NSUINT_BIT - howmuch)))
#define NSSTRING_FROM_INTEGER(i) [NSString stringWithFormat:@"%lli", (long long)i]
#define NSSTRING_FROM_FLOAT(f) [NSString stringWithFormat:@"%f", f]
#define REVERSE_ENUMERATE(Type, item, list, processingBlock)                    \
        if (CHECK_NULL_CLASS(list, NSArray)) {                                  \
            for (NSInteger i = (NSInteger)(list.count - 1); i >= 0; --i) {      \
                Type *item = list[i];                                           \
                processingBlock();                                              \
            }                                                                   \
        }
/* By using this macro, item can be safely removed from the list while enumerating */
#define SAFE_REMOVAL_ENUMERATE(Type, item, list, processingBlock) REVERSE_ENUMERATE(Type, item, list, processingBlock)
/* Return YES if both obj and str are NULL or they have a same value */
#define IS_EQUAL_STRING(obj, str)       ((obj == nil && str == nil) || \
                                        (CHECK_NULL_CLASS(obj, NSString) && CHECK_NULL_CLASS(str, NSString) && [obj isEqualToString:str]))

#define SHARED_INSTANCE(shared_instance, class_name) \
        + (class_name *) shared_instance { \
            static class_name *sharedInstance; \
            static dispatch_once_t onceToken; \
            dispatch_once(&onceToken, ^{ \
                sharedInstance = [[class_name alloc] init]; \
            }); \
            return sharedInstance; \
        }

#define SAFE_DISPATCH(block, params, onQueue, dfQueue) \
        if (block) { \
            dispatch_queue_t _safe_queue = onQueue ? onQueue : dfQueue; \
            dispatch_async(_safe_queue ? _safe_queue : dispatch_get_main_queue(), ^{ \
                block params; \
            }); \
        }

#define WEAK_INSTANCE(instance, weak_instance) \
        __weak typeof(instance) weak_instance = instance;

#define STRONG_INSTANCE(instance, strong_instance) \
        __strong typeof(instance) strong_instance = instance;

#define WEAK_SELF \
        WEAK_INSTANCE(self, weakSelf)

#define STRONG_SELF \
        STRONG_INSTANCE(weakSelf, strongSelf)

/*
 Example code:
 
    WEAK_INSTANCE(self, weakSelf)
     dispatch_async(queue, ^{
        IF_STRONG_INSTANCE(weakSelf, strongSelf) {
            [strongSelf foo];
        } else {
            // Following statements will be called if the given instance is already released.
            // Do something...
        }
    });
 */

#define IF_STRONG_INSTANCE(instance, strong_instance) \
        STRONG_INSTANCE(instance, strong_instance) \
        if (strong_instance)

/*
 Example code:
 
    WEAK_SELF
    dispatch_async(queue, ^{
        IF_STRONG_SELF {
            [strongSelf foo];
        } else {
            // Following statements will be called if `self` is already released.
            // Do something...
        }
    });
 */

#define IF_STRONG_SELF \
        IF_STRONG_INSTANCE(weakSelf, strongSelf)


#define IF_NOT_STRONG_SELF \
        STRONG_INSTANCE(weakSelf, strongSelf) \
        if (!strongSelf)

#define IF_NOT_STRONG_SELF_RETURN(_retValue) \
        IF_NOT_STRONG_SELF { \
            return _retValue; \
        }

/*
 A safe way to dispatch sync/async your block without retaining your instances.
 
 Example code:
 
    UNRETAINED_DISPATCH_ASYNC(queue, object) {
        // A strong variable named "strongInstance" which references to your given object will be generated automatically.
        [strongInstance foo];
    } else {
        // Following statements will be called if the given instance is already released.
        // Do something...
    }
    UNRETAINED_DISPATCH_END
 */

#define UNRETAINED_DISPATCH_SYNC(queue, instance) \
        UNRETAINED_DISPATCH_BEGIN(dispatch_sync, queue, instance)

#define UNRETAINED_DISPATCH_ASYNC(queue, instance) \
        UNRETAINED_DISPATCH_BEGIN(dispatch_async, queue, instance)

#define UNRETAINED_DISPATCH_BEGIN(method, queue, instance) \
        { \
            WEAK_INSTANCE(instance, weakInstance) \
            method(queue, ^{ \
                IF_STRONG_INSTANCE(weakInstance, strongInstance)

#define UNRETAINED_DISPATCH_END \
            }); \
        }




/* START OF DEBUG CONSOLE LOGGING MACRO OF TRUNGPNN */
#define DEBUG_TRUNGPNN DEBUG

#if DEBUG_TRUNGPNN
#define TR_CONSOLE_LOGGER(arguments, ...) NSLog(@"[🐙 TrungPNN]> " arguments, ##__VA_ARGS__)
#define TR_CVF_CONSOLE_LOGGER(arguments, ...) TR_CONSOLE_LOGGER(@"[Chat-ViewFull] " arguments, ##__VA_ARGS__)
#else
#define TR_CONSOLE_LOGGER(arguments, ...) {}
#define TR_CVF_CONSOLE_LOGGER(arguments, ...) {}
#endif
/* END OF DEBUG CONSOLE LOGGING MACRO OF TRUNGPNN */

/* START OF SOCIAL UPLOAD QOS LOGGING */
#define ENABLE_LOG_FLOW_POST_FEED   (1 && UX_SOCKET_UNIVERSAL)

#if ENABLE_LOG_FLOW_POST_FEED
#define LOG_SOCIAL_UPLOAD_QOS(arguments, ...)               UX_WRITE_LOG_TO_NATIVE("SOCIAL - " arguments, ##__VA_ARGS__)
#define LOG_SOCIAL_UPLOAD_SUCCESS_QOS(arguments, ...)       LOG_SOCIAL_UPLOAD_QOS("✅ - " arguments, ##__VA_ARGS__)
#define LOG_SOCIAL_UPLOAD_FAIL_QOS(arguments, ...)          LOG_SOCIAL_UPLOAD_QOS("❌ - " arguments, ##__VA_ARGS__)
#else // ENABLE_LOG_FLOW_POST_FEED
#define LOG_SOCIAL_UPLOAD_QOS(arguments, ...)               {}
#define LOG_SOCIAL_UPLOAD_SUCCESS_QOS(arguments, ...)       {}
#define LOG_SOCIAL_UPLOAD_FAIL_QOS(arguments, ...)          {}
#endif // ENABLE_LOG_FLOW_POST_FEED

/* END OF SOCIAL UPLOAD QOS LOGGING */

/* BAONQ3's MACRO */
#define BAONQ3_DEBUG DEBUG

#if BAONQ3_DEBUG
#define BAONQ3_LOG(arguments, ...)  NSLog(@"BaoNQ3> " arguments, ##__VA_ARGS__)
#else
#define BAONQ3_LOG(arguments, ...) {}
#endif
/* END */

/* DAONV - CLEARLOG */
/* Log console without print system datetime & project name => So clearly */
#if DEBUG
void FUNC_CLEAR_LOGv(NSString *format, ...);
#define CLEAR_LOG(arguments, ...) FUNC_CLEAR_LOGv(arguments @"\t|\t%s(Line: %d)", ##__VA_ARGS__, __FUNCTION__, __LINE__)
#else
#define CLEAR_LOG(arguments, ...) {}
#endif
/* END */

/* BENCHMARK */
#if DEBUG
#define DEBUG_LOG_BENCHMARK 1
#else
#define DEBUG_LOG_BENCHMARK 0
#endif

#if DEBUG_LOG_BENCHMARK
#define LOG_BENCHMARK(log, iterations, thresholdTime, block) ({ \
    CFTimeInterval startTime = CACurrentMediaTime(); \
    for (int i=0; i<iterations; i++) { \
        @autoreleasepool { \
            block; \
        } \
    } \
    CFTimeInterval endTime = CACurrentMediaTime(); \
    CFTimeInterval averageTime = (endTime - startTime)/iterations; \
    UX_CONSOLE_LOGGER(@"%@ -> benchmark average time: %g s", log, averageTime); \
    NSAssert(averageTime < thresholdTime, ([NSString stringWithFormat:@"%@ -> averageTime < %g", log, thresholdTime])); \
})
#else
#define LOG_BENCHMARK(log, iterations, thresholdTime, block) block;
#endif
/* END BENCHMARK */

#define UIEdgeInsetsMakeAllEdge(inset) UIEdgeInsetsMake(inset, inset, inset, inset)
#define CGSizeMakeSquare(width) CGSizeMake(width, width)
#define RGB_TO_HEX(r,g,b) [NSString stringWithFormat:@"#%02lX%02lX%02lX",lroundf(r * 255),lroundf(g * 255),lroundf(b * 255)]
#define COLOR_TO_HEX(color) ({ \
    NSString *hex; \
    if(CGColorGetNumberOfComponents(color.CGColor) == 2) \
    { \
        UXDASSERT(NO); \
    } \
    else { \
       const CGFloat *components = CGColorGetComponents(color.CGColor); \
       hex = RGB_TO_HEX(components[0], components[1], components[2]); \
    }\
    hex; \
})

/**
 * Create a new set by mapping `collection` over `work`, ignoring nil.
 */
#define SetByFlatMapping(collection, decl, work) ({ \
    NSMutableSet *s = [NSMutableSet set]; \
    for (decl in collection) {\
        id result = work; \
        if (result != nil) { \
            [s addObject:result]; \
        } \
    } \
    s; \
})

/**
 * Create a new array by mapping `collection` over `work`, ignoring nil.
 */
#define ArrayByFlatMapping(collection, decl, work) ({ \
    NSMutableArray *a = [NSMutableArray array]; \
    for (decl in collection) {\
        id result = work; \
        if (result != nil) { \
            [a addObject:result]; \
        } \
    } \
    a; \
})

#define STRINGIZE(x) #x
#define STRINGIZE2(x) STRINGIZE(x)
#define SHADER_STRING(text) @ STRINGIZE2(text)

#define OptionsHasValue(options, value) (((options) & (value)) == (value))

/** TUCP - Util macros */

#define NOT(cond) (!(cond)) // `not` is existed in C++ macros -> use `NOT` instead of `not`
#define ifnot(condition)        if (!(condition))
#define elseifnot(condition)    else if (!(condition))
#define runAfter(delay, block)  dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delay * NSEC_PER_SEC)), dispatch_get_main_queue(), ^block);
#define safeExec(block, ...)    block ? block(__VA_ARGS__) : nil

#define NETWORK_LOG(nsError)                NSLog(@"[❌ NETWORK]> %@", [nsError description])
#define NETWORK_UNKNOWN(arguments, ...)     NSLog(@"[❌ NETWORK]> " arguments, ##__VA_ARGS__)

#define IS_NONEMPTY_DICT(dict)          (dict && [dict isKindOfClass:[NSDictionary class]] && ((NSDictionary*)dict).count>0)
#define IS_EMPTY_DICT(dict)             !IS_NONEMPTY_DICT(dict)
#define IS_EMPTY_STRING(str)            !IS_NONEMPTY_STRING(str)
#define IS_VALID_CLASS(obj, className)  (obj && [obj isKindOfClass:[className class]])
#define TUCP_LOG(arguments, ...)  NSLog(@"[TUCP] 🔥> " arguments, ##__VA_ARGS__)
#define TUCP_ERR_LOG(arguments, ...)  NSLog(@"[TUCP] ❌> " arguments, ##__VA_ARGS__)

/** END - Util macros */


/****************************** TruongDQ **************************************/

#define AssertNonEmptyString(str) NSAssert(IS_NONEMPTY_STRING(str), @"Argument " @#str " must be non-empty string")
#define AssertNonEmptyArr(str) NSAssert(IS_NONEMPTY_ARRAY(str), @"Argument " @#str " must be non-empty array")

#define AssertNonNull(obj) NSAssert(obj != nil, @"Argument " @#obj " must be non-null")
#define AssertArgumentByClass(obj, class) NSAssert(CHECK_NULL_CLASS(obj, class), @"Argument " @#obj " must be kind of class" @#class "");

#define AssertInconsistency NSAssert(NO, NSInternalInconsistencyException)
#define AssertNotImplemented NSAssert(NO, ([NSString stringWithFormat:@"Method %@ is not implemented", NSStringFromSelector(_cmd)]))
#define AssertNotSupported NSAssert(NO, ([NSString stringWithFormat:@"Method %@ is not supported", NSStringFromSelector(_cmd)]))

#define nonempty // Empty defines

typedef nonempty NSString NonEmptyString;

/***************************** END (TruongDQ) *********************************/


#define STRINGIZE(x) #x
#define STRINGIZE2(x) STRINGIZE(x)
#define SHADER_STRING(text) @ STRINGIZE2(text)

/* HUYNQ10's MACRO */
#define HUYNQ10_DEBUG DEBUG

/* HUYNQ10 DEBUG ONLY */
#if HUYNQ10_DEBUG
#define HNAssert(condition, desc, ...) NSAssert(condition, desc, ##__VA_ARGS__)
#define HNAssertNil(condition, desc, ...) HNAssert((condition) == nil, desc, ##__VA_ARGS__)
#define HNAssertNilConvenience(condition) HNAssert((condition) == nil, @"%s must be nil", #condition)
#define HNAssertNotNil(condition, desc, ...) HNAssert((condition) != nil, desc, ##__VA_ARGS__)
#define HNAssertNotNilConvenience(condition) HNAssert((condition) != nil, @"%s must not be nil", #condition)
#define HNAssertImplementedBySubclass() HNAssert(NO, @"This method must be implemented by subclass %@", [self class]);
#define HNAssertNotInstantiable() HNAssert(NO, nil, @"This class is not instantiable.");
#define HNAssertNotSupported() HNAssert(NO, nil, @"This method is not supported by class %@", [self class]);
#define HNAssertOnQueue(queue, queueName) HNAssert([TSHelper isCurrentQueue:queue withName:queueName], @"%@ must be called on the %s queue.", NSStringFromSelector(_cmd), queueName)
#define HNAssertMainQueue() HNAssert(isMainQueue(), nil, @"%@ must be called on the main queue", NSStringFromSelector(_cmd))
#define HNAssertBackgroundQueue() HNAssert(!isMainQueue(), nil, @"%@ must be called off the main queue", NSStringFromSelector(_cmd))
#else // HUYNQ10_DEBUG
#define HNAssert(condition, desc, ...) {}
#define HNAssertNil(condition, desc, ...) {}
#define HNAssertNilConvenience(condition) {}
#define HNAssertNotNil(condition, desc, ...) {}
#define HNAssertNotNilConvenience(condition) {}
#define HNAssertImplementedBySubclass() {}
#define HNAssertNotInstantiable() {}
#define HNAssertNotSupported() {}
#define HNAssertOnQueue(queue, queueName) {}
#define HNAssertMainQueue() {}
#define HNAssertBackgroundQueue() {}
#endif // HUYNQ10_DEBUG
/* END (HUYNQ10 DEBUG ONLY) */

#define ZADynamicCast(x, c) ({ \
    id __val = x;\
    ((c *) ([__val isKindOfClass:[c class]] ? __val : nil));\
})

#define HN_GUARD(CONDITION) if (CONDITION) {}
#define HN_MIN(A,B)    ({ __typeof__(A) __a = (A); __typeof__(B) __b = (B); __a < __b ? __a : __b; })
#define HN_MAX(A,B)    ({ __typeof__(A) __a = (A); __typeof__(B) __b = (B); __a < __b ? __b : __a; })

#define HN_CLAMP(x, low, high) ({\
__typeof__(x) __x = (x); \
__typeof__(low) __low = (low);\
__typeof__(high) __high = (high);\
__x > __high ? __high : (__x < __low ? __low : __x);\
})

/* END (HUYNQ10's MACRO) */

#define REVERSE_BITS(value) (~value)

// <!—————————————————————————————— [BEG] ASSERTION —————————————————————————————— //

#define ASSERT_MESSAGE(message) [NSString stringWithFormat:@"🌺 %@ — METHOD: %s — LINE: %d", message, __FUNCTION__, __LINE__]

#if DEBUG
    #define ASSERT_WITH_EXEPTION_CASE_MESSAGE NSAssert(NO, ASSERT_MESSAGE(@"Found exception case !!!"));
#else // DEBUG
    #define ASSERT_WITH_EXEPTION_CASE_MESSAGE {}
#endif // DEBUG

#if DEBUG
    #define ASSERT_NON_IMPLEMENTED_METHOD NSAssert(NO, ASSERT_MESSAGE(@"This method should not be called. Plz, implement it!"));
#else // DEBUG
    #define ASSERT_NON_IMPLEMENTED_METHOD {}
#endif // DEBUG

#if DEBUG
    #define ASSERT_NIL_OBJECT(obj) NSAssert(obj, ASSERT_MESSAGE(@"This object is nil which is not allowed in this method !"))
#else // DEBUG
    #define ASSERT_NIL_OBJECT {}
#endif // DEBUG

#if DEBUG
    #define ASSERT_WITH_MESSAGE(message) NSAssert(NO, ASSERT_MESSAGE(message))
#else // DEBUG
    #define ASSERT_WITH_MESSAGE {}
#endif // DEBUG

// ——————————————————————————————— [END] ASSERTION ——————————————————————————————> //

// <!————————————————————————————— [BEG] ANIMATION ——————————————————————————————— //

#define DISABLE_TRANSACTION_ANIMATION_BEGIN [CATransaction begin];\
                                            [CATransaction setDisableActions:YES];

#define DISABLE_TRANSACTION_ANIMATION_END [CATransaction commit];

// ——————————————————————————————— [END] ANIMATION ———————————————————————————————> //

// ——————————————————————————————— [BEG] VuLH Log ———————————————————————————————> //

#if DEBUG
#define VULH_LOG(arguments, ...)  NSLog(@"� VuLH3» " arguments, ##__VA_ARGS__)
#else // DEBUG
#define VULH_LOG(arguments, ...) {}
#endif // DEBUG

// ——————————————————————————————— [END] VuLH Log ———————————————————————————————> //

/* [BEG] HUNGMN's MACRO */

#define FBL_GUARD_ERROR(error)      NSError *guardError = error ?: [NSError errorWithDomain:@"" code:-1 userInfo:nil]; \
                                    reject(guardError);

/* [END] HUNGMN's MACRO */

#if ENABLE_TEXTURE_KIT
#define atomicity atomic
#else
#define atomicity nonatomic
#endif

/**
 Hàm số tính offset tạo hiệu ứng rubberband giống scrollview
 
 f(x, d, c) = (x * d * c) / (d + c * x)
 
 where,
 x – distance from the edge
 c – constant (UIScrollView uses 0.55)
 d – dimension, either width or height
 
 source: http://holko.pl/2014/07/06/inertia-bouncing-rubber-banding-uikit-dynamics/
 */
static inline CGFloat rubberBandDistance(CGFloat offset, CGFloat dimension, CGFloat constant) {
    CGFloat result = (constant * fabs(offset) * dimension) / (dimension + constant * fabs(offset));
    // The algorithm expects a positive offset, so we have to negate the result if the offset was negative.
    return offset < 0.0f ? -result : result;
}

/**
 Distance traveled after decelerating to zero velocity at a constant rate
 */
static inline CGFloat projectDistance(CGFloat inititalVelocity, CGFloat decelerationRate) {
    return (inititalVelocity / 1000) * decelerationRate / (1 - decelerationRate);
}

/**
 @abstract Correctly equates two objects, including cases where both objects are nil. The latter is a case where `isEqual:` fails.
 @param obj The first object in the comparison. Can be nil.
 @param otherObj The second object in the comparison. Can be nil.
 @result YES if the objects are equal, including cases where both object are nil.
 */
static inline BOOL ZAObjectIsEqual(id<NSObject> obj, id<NSObject> otherObj)
{
    return obj == otherObj || [obj isEqual:otherObj];
}

#define ZAValueIsEqual(left, right) ({\
    __typeof__(left) __left = (left); \
    __typeof__(right) __right = (right);\
    __left == __right;\
})

static inline CGFloat ZAInterpolateCGFloat(CGFloat start, CGFloat end, CGFloat progress) {
    return start * (1.0 - progress) + end * progress;
}

static inline CGPoint ZAInterpolateCGPoint(CGPoint start, CGPoint end, CGFloat progress) {
    CGFloat x = ZAInterpolateCGFloat(start.x, end.x, progress);
    CGFloat y = ZAInterpolateCGFloat(start.y, end.y, progress);
    return CGPointMake(x, y);
}

static inline CGSize ZAInterpolateCGSize(CGSize start, CGSize end, CGFloat progress) {
    CGFloat width = ZAInterpolateCGFloat(start.width, end.width, progress);
    CGFloat height = ZAInterpolateCGFloat(start.height, end.height, progress);
    return CGSizeMake(width, height);
}

static inline CGRect ZAInterpolateCGRect(CGRect start, CGRect end, CGFloat progress) {
    CGFloat x = ZAInterpolateCGFloat(start.origin.x, end.origin.x, progress);
    CGFloat y = ZAInterpolateCGFloat(start.origin.y, end.origin.y, progress);
    CGFloat width = ZAInterpolateCGFloat(start.size.width, end.size.width, progress);
    CGFloat height = ZAInterpolateCGFloat(start.size.height, end.size.height, progress);
    return CGRectMake(x, y, width, height);
}

#define ZA_Badge_Number_N 1000000 // Không hiểu sao NSIntegerMax lại làm CFNumber bad access

#define IOS_13_OR_LATER (__IPHONE_13_0 && __IPHONE_OS_VERSION_MAX_ALLOWED >= __IPHONE_13_0)

#define MAKE_SOCIAL_ERROR(errorDomain, errorCode, message)  [NSError errorWithDomain:(errorDomain?: DOMAIN_ZX_SOCIAL) code:errorCode userInfo:@{NSLocalizedDescriptionKey : (message?: @"")}]
#define LimitNumberInRange(number, min, max) number = MIN(max, MAX(min, number))


#endif /* LDCommonMacros_h */
