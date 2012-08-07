//
//  GAKeychain.m
//  GAKeychain
//
//  Created by Guilherme Andrade on 8/6/12.
//  Copyright (c) 2012 Guilherme Andrade. All rights reserved.
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the  Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is furnished
//  to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in
//  all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED,
//  INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A
//  PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT
//  HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION
//  OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE
//  SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
//

#import "GAKeychain.h"

NSString *const kGAKeychainDefaultAccount   =   @"GAKeychainDefaultAccount";

NSString *const kGAKeychainErrorDomain      =   @"com.2thinkers.gakeychain";

NSString *const kGAKeychainAccountKey       =   @"acct";
NSString *const kGAKeychainCreatedAtKey     =   @"cdat";
NSString *const kGAKeychainClassKey         =   @"labl";
NSString *const kGAKeychainDescriptionKey   =   @"desc";
NSString *const kGAKeychainLabelKey         =   @"labl";
NSString *const kGAKeychainLastModifiedKey  =   @"mdat";
NSString *const kGAKeychainWhereKey         =   @"svce";

#if __IPHONE_4_0 && TARGET_OS_IPHONE  
CFTypeRef GAKeychainAccessibilityType = NULL;
#endif

@interface GAKeychain ()

+ (NSMutableDictionary *)_queryForService:(NSString *)service account:(NSString *)account;

@end


@implementation GAKeychain

#pragma mark - Getting Accounts

+ (NSArray *)allAccounts {
    
    return [self accountsForService:nil error:nil];
}

+ (NSArray *)allAccounts:(NSError **)error {
    
    return [self accountsForService:nil error:error];
}

+ (NSArray *)accountsForService:(NSString *)service {
    
    return [self accountsForService:service error:nil];
}

+ (NSArray *)accountsForService:(NSString *)service error:(NSError **)error {
    
    OSStatus status = GAKeychainErrorBadArguments;
    
    NSMutableDictionary *query = [self _queryForService:service account:nil];
#if __has_feature(objc_arc)
	[query setObject:(__bridge id)kCFBooleanTrue forKey:(__bridge id)kSecReturnAttributes];
    [query setObject:(__bridge id)kSecMatchLimitAll forKey:(__bridge id)kSecMatchLimit];
#else
    [query setObject:(id)kCFBooleanTrue forKey:(id)kSecReturnAttributes];
    [query setObject:(id)kSecMatchLimitAll forKey:(id)kSecMatchLimit];
#endif
	
	CFTypeRef result = NULL;
#if __has_feature(objc_arc)
    status = SecItemCopyMatching((__bridge CFDictionaryRef)query, &result);
#else
	status = SecItemCopyMatching((CFDictionaryRef)query, &result);
#endif
    
    if (status != noErr && error != NULL) {
        
		*error = [NSError errorWithDomain:kGAKeychainErrorDomain code:status userInfo:nil];
		return nil;
	}
	
#if __has_feature(objc_arc)
	return (__bridge_transfer NSArray *)result;
#else
    return [(NSArray *)result autorelease];
#endif
}


#pragma mark - Getting Passwords

+ (NSString *)passwordForService:(NSString *)serviceName {
    
    return [self passwordForService:serviceName account:kGAKeychainDefaultAccount];
}

+ (NSString *)passwordForService:(NSString *)service account:(NSString *)account {
    
	return [self passwordForService:service account:account error:nil];
}

+ (NSString *)passwordForService:(NSString *)service account:(NSString *)account error:(NSError **)error {
    
    NSData *data = [self passwordDataForService:service account:account error:error];
    
	if (data.length > 0) {
        
		NSString *string = [[NSString alloc] initWithData:(NSData *)data encoding:NSUTF8StringEncoding];
#if !__has_feature(objc_arc)
		[string autorelease];
#endif
		return string;
	}
	
	return nil;
}

+ (NSData *)passwordDataForService:(NSString *)service account:(NSString *)account {
    
    return [self passwordDataForService:service account:account error:nil];
}

+ (NSData *)passwordDataForService:(NSString *)service account:(NSString *)account error:(NSError **)error {
    
    OSStatus status = GAKeychainErrorBadArguments;
	if (!service || !account) {
        
		if (error) {
            
			*error = [NSError errorWithDomain:kGAKeychainErrorDomain code:status userInfo:nil];
		}
		return nil;
	}
	
	CFTypeRef result = NULL;	
	NSMutableDictionary *query = [self _queryForService:service account:account];
#if __has_feature(objc_arc)
	[query setObject:(__bridge id)kCFBooleanTrue forKey:(__bridge id)kSecReturnData];
	[query setObject:(__bridge id)kSecMatchLimitOne forKey:(__bridge id)kSecMatchLimit];
	status = SecItemCopyMatching((__bridge CFDictionaryRef)query, &result);
#else
	[query setObject:(id)kCFBooleanTrue forKey:(id)kSecReturnData];
	[query setObject:(id)kSecMatchLimitOne forKey:(id)kSecMatchLimit];
	status = SecItemCopyMatching((CFDictionaryRef)query, &result);
#endif
	
	if (status != noErr && error != NULL) {
		*error = [NSError errorWithDomain:kGAKeychainErrorDomain code:status userInfo:nil];
		return nil;
	}
	
#if __has_feature(objc_arc)
	return (__bridge_transfer NSData *)result;
#else
    return [(NSData *)result autorelease];
#endif
}


#pragma mark - Deleting Passwords

+ (BOOL)deletePasswordForService:(NSString *)serviceName {
    
    return [self deletePasswordForService:serviceName account:kGAKeychainDefaultAccount];
}

+ (BOOL)deletePasswordForService:(NSString *)service account:(NSString *)account {
    
	return [self deletePasswordForService:service account:account error:nil];
}

+ (BOOL)deletePasswordForService:(NSString *)service account:(NSString *)account error:(NSError **)error {
    
	OSStatus status = GAKeychainErrorBadArguments;
	if (service && account) {
		NSMutableDictionary *query = [self _queryForService:service account:account];
#if __has_feature(objc_arc)
		status = SecItemDelete((__bridge CFDictionaryRef)query);
#else
		status = SecItemDelete((CFDictionaryRef)query);
#endif
	}
	if (status != noErr && error != NULL) {
		*error = [NSError errorWithDomain:kGAKeychainErrorDomain code:status userInfo:nil];
	}
	return (status == noErr);
}


#pragma mark - Setting Passwords

+ (BOOL)setPassword:(NSString *)password forService:(NSString *)serviceName {
    
    return [self setPassword:password forService:serviceName account:kGAKeychainDefaultAccount];
}

+ (BOOL)setPassword:(NSString *)password forService:(NSString *)service account:(NSString *)account {
    
	return [self setPassword:password forService:service account:account error:nil];
}

+ (BOOL)setPassword:(NSString *)password forService:(NSString *)service account:(NSString *)account error:(NSError **)error {
    
    NSData *data = [password dataUsingEncoding:NSUTF8StringEncoding];
    return [self setPasswordData:data forService:service account:account error:error];
}

+ (BOOL)setPasswordData:(NSData *)password forService:(NSString *)service account:(NSString *)account {
    
    return [self setPasswordData:password forService:service account:account error:nil];
}

+ (BOOL)setPasswordData:(NSData *)password forService:(NSString *)service account:(NSString *)account error:(NSError **)error {
    OSStatus status = GAKeychainErrorBadArguments;
	if (password && service && account) {
        [self deletePasswordForService:service account:account];
        NSMutableDictionary *query = [self _queryForService:service account:account];
#if __has_feature(objc_arc)
		[query setObject:password forKey:(__bridge id)kSecValueData];
#else
		[query setObject:password forKey:(id)kSecValueData];
#endif
		
#if __IPHONE_4_0 && TARGET_OS_IPHONE
		if (GAKeychainAccessibilityType) {
#if __has_feature(objc_arc)
			[query setObject:(id)[self accessibilityType] forKey:(__bridge id)kSecAttrAccessible];
#else
			[query setObject:(id)[self accessibilityType] forKey:(id)kSecAttrAccessible];
#endif
		}
#endif
		
#if __has_feature(objc_arc)
        status = SecItemAdd((__bridge CFDictionaryRef)query, NULL);
#else
		status = SecItemAdd((CFDictionaryRef)query, NULL);
#endif
	}
	if (status != noErr && error != NULL) {
		*error = [NSError errorWithDomain:kGAKeychainErrorDomain code:status userInfo:nil];
	}
	return (status == noErr);
}


#pragma mark - Configuration

#if __IPHONE_4_0 && TARGET_OS_IPHONE 
+ (CFTypeRef)accessibilityType {
	return GAKeychainAccessibilityType;
}

+ (void)setAccessibilityType:(CFTypeRef)accessibilityType {
    
	CFRetain(accessibilityType);
	if (GAKeychainAccessibilityType) {
		CFRelease(GAKeychainAccessibilityType);
	}
	GAKeychainAccessibilityType = accessibilityType;
}
#endif


#pragma mark - Private

+ (NSMutableDictionary *)_queryForService:(NSString *)service account:(NSString *)account {
    NSMutableDictionary *dictionary = [NSMutableDictionary dictionaryWithCapacity:3];
#if __has_feature(objc_arc)
    [dictionary setObject:(__bridge id)kSecClassGenericPassword forKey:(__bridge id)kSecClass];
#else
	[dictionary setObject:(id)kSecClassGenericPassword forKey:(id)kSecClass];
#endif
	
    if (service) {
#if __has_feature(objc_arc)
		[dictionary setObject:service forKey:(__bridge id)kSecAttrService];
#else
		[dictionary setObject:service forKey:(id)kSecAttrService];
#endif
	}
	
    if (account) {
#if __has_feature(objc_arc)
		[dictionary setObject:account forKey:(__bridge id)kSecAttrAccount];
#else
		[dictionary setObject:account forKey:(id)kSecAttrAccount];
#endif
	}
	
    return dictionary;
}

@end
