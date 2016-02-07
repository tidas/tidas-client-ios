//
//  KeyInterface.m
//  tidas_objc_prototype
//
//  Created by Nicholas Esposito on 9/18/15.
//  Copyright © 2015 trailofbits. All rights reserved.
//

#import "KeyInterface.h"

#define newCFDict CFDictionaryCreateMutable(kCFAllocatorDefault, 0, &kCFTypeDictionaryKeyCallBacks, &kCFTypeDictionaryValueCallBacks)

@implementation KeyInterface

static SecKeyRef publicKeyRef;
static SecKeyRef privateKeyRef;
static NSData    *publicKeyBits;

+ (bool)publicKeyExists
{
  CFTypeRef publicKeyResult = nil;
  CFMutableDictionaryRef publicKeyExistsQuery = newCFDict;
  CFDictionarySetValue(publicKeyExistsQuery, kSecClass,               kSecClassKey);
  CFDictionarySetValue(publicKeyExistsQuery, kSecAttrKeyType,         kSecAttrKeyTypeEC);
  CFDictionarySetValue(publicKeyExistsQuery, kSecAttrApplicationTag,  kTidasPublicKeyName);
  CFDictionarySetValue(publicKeyExistsQuery, kSecAttrKeyClass,        kSecAttrKeyClassPublic);
  CFDictionarySetValue(publicKeyExistsQuery, kSecReturnData,          kCFBooleanTrue);

  OSStatus status = SecItemCopyMatching(publicKeyExistsQuery, (CFTypeRef *)&publicKeyResult);

  if (status == errSecItemNotFound) {
    return false;
  }
  else if (status == errSecSuccess) {
    return true;
  }
  else {
    [NSException raise:@"Unexpected OSStatus" format:@"Status: %i", status];
    return nil;
  }
}

+ (SecKeyRef) lookupPublicKeyRef
{
  CFMutableDictionaryRef getPublicKeyQuery = newCFDict;
  CFDictionarySetValue(getPublicKeyQuery, kSecClass,                kSecClassKey);
  CFDictionarySetValue(getPublicKeyQuery, kSecAttrKeyType,          kSecAttrKeyTypeEC);
  CFDictionarySetValue(getPublicKeyQuery, kSecAttrApplicationTag,   kTidasPublicKeyName);
  CFDictionarySetValue(getPublicKeyQuery, kSecAttrKeyClass,         kSecAttrKeyClassPublic);
  CFDictionarySetValue(getPublicKeyQuery, kSecReturnData,           kCFBooleanTrue);
  CFDictionarySetValue(getPublicKeyQuery, kSecReturnPersistentRef,  kCFBooleanTrue);
  
  OSStatus status = SecItemCopyMatching(getPublicKeyQuery, (CFTypeRef *)&publicKeyRef);
  if (status == errSecSuccess)
    return (SecKeyRef)publicKeyRef;
  else if (status == errSecItemNotFound)
    return nil;
  else
    [NSException raise:@"Unexpected OSStatus" format:@"Status: %i", status];
  return false;
}

+ (NSData *) publicKeyBits
{
  if (![self publicKeyExists])
    return nil;
  return (NSData *) CFDictionaryGetValue((CFDictionaryRef)[self lookupPublicKeyRef], kSecValueData);
    
}

+ (SecKeyRef) lookupPrivateKeyRef
{
  CFMutableDictionaryRef getPrivateKeyRef = newCFDict;
  CFDictionarySetValue(getPrivateKeyRef, kSecClass, kSecClassKey);
  CFDictionarySetValue(getPrivateKeyRef, kSecAttrKeyClass, kSecAttrKeyClassPrivate);
  CFDictionarySetValue(getPrivateKeyRef, kSecAttrLabel, kTidasPrivateKeyName);
  CFDictionarySetValue(getPrivateKeyRef, kSecReturnRef, kCFBooleanTrue);
  CFDictionarySetValue(getPrivateKeyRef, kSecUseOperationPrompt, @"Authenticate to sign data");
  
  OSStatus status = SecItemCopyMatching(getPrivateKeyRef, (CFTypeRef *)&privateKeyRef);
  if (status == errSecItemNotFound)
    return nil;
  
  return (SecKeyRef)privateKeyRef;
}

+ (bool)generateTouchIDKeyPair
{
  CFErrorRef error = NULL;
  // Should be the secret invalidated when passcode is removed? If not then use `kSecAttrAccessibleWhenUnlocked`.
  SecAccessControlRef sacObject = SecAccessControlCreateWithFlags(
    kCFAllocatorDefault,
    kSecAttrAccessibleWhenPasscodeSetThisDeviceOnly,
    kSecAccessControlTouchIDAny | kSecAccessControlPrivateKeyUsage,
    &error
  );
  
  if (error != errSecSuccess) {
    NSLog(@"Generate key error: %@\n", error);
  }
  
  return [self generateKeyPairWithAccessControlObject:sacObject];
}

+ (bool) generatePasscodeKeyPair
{
  CFErrorRef error = NULL;
  SecAccessControlRef sacObject = SecAccessControlCreateWithFlags(
    kCFAllocatorDefault,
    kSecAttrAccessibleWhenPasscodeSetThisDeviceOnly,
    kSecAccessControlUserPresence,
    &error
  );
  
  if (error != errSecSuccess) {
    NSLog(@"Generate key error: %@\n", error);
  }
  
  return [self generateKeyPairWithAccessControlObject:sacObject];
}

+ (bool) generateKeyPairWithAccessControlObject:(SecAccessControlRef)accessControlRef
{
  // create dict of private key info
  CFMutableDictionaryRef accessControlDict = newCFDict;;
  CFDictionaryAddValue(accessControlDict, kSecAttrAccessControl, accessControlRef);
  CFDictionaryAddValue(accessControlDict, kSecAttrIsPermanent, kCFBooleanTrue);
  CFDictionaryAddValue(accessControlDict, kSecAttrLabel, kTidasPrivateKeyName);
  
  // create dict which actually saves key into keychain
  CFMutableDictionaryRef generatePairRef = newCFDict;
  CFDictionaryAddValue(generatePairRef, kSecAttrTokenID, kSecAttrTokenIDSecureEnclave);
  CFDictionaryAddValue(generatePairRef, kSecAttrKeyType, kSecAttrKeyTypeEC);
  CFDictionaryAddValue(generatePairRef, kSecAttrKeySizeInBits, (__bridge const void *)([NSNumber numberWithInt:256]));
  CFDictionaryAddValue(generatePairRef, kSecPrivateKeyAttrs, accessControlDict);
  
  OSStatus status = SecKeyGeneratePair(generatePairRef, &publicKeyRef, &privateKeyRef);
  
  if (status != errSecSuccess)
    return NO;
  
  [self savePublicKeyFromRef:publicKeyRef];
  return YES;
}

+ (bool) savePublicKeyFromRef:(SecKeyRef)publicKeyRef
{
  CFTypeRef keyBits;
  CFMutableDictionaryRef savePublicKeyDict = newCFDict;
  CFDictionaryAddValue(savePublicKeyDict, kSecClass,        kSecClassKey);
  CFDictionaryAddValue(savePublicKeyDict, kSecAttrKeyType,  kSecAttrKeyTypeEC);
  CFDictionaryAddValue(savePublicKeyDict, kSecAttrKeyClass, kSecAttrKeyClassPublic);
  CFDictionaryAddValue(savePublicKeyDict, kSecAttrApplicationTag, kTidasPublicKeyName);
  CFDictionaryAddValue(savePublicKeyDict, kSecValueRef, publicKeyRef);
  CFDictionaryAddValue(savePublicKeyDict, kSecAttrIsPermanent, kCFBooleanTrue);
  CFDictionaryAddValue(savePublicKeyDict, kSecReturnData, kCFBooleanTrue);
  
  OSStatus err = SecItemAdd(savePublicKeyDict, &keyBits);
  while (err == errSecDuplicateItem)
  {
    err = SecItemDelete(savePublicKeyDict);
  }
  err = SecItemAdd(savePublicKeyDict, &keyBits);
  
  return YES;
}

+(bool) deletePubKey {
  CFMutableDictionaryRef savePublicKeyDict = newCFDict;
  CFDictionaryAddValue(savePublicKeyDict, kSecClass,        kSecClassKey);
  CFDictionaryAddValue(savePublicKeyDict, kSecAttrKeyType,  kSecAttrKeyTypeEC);
  CFDictionaryAddValue(savePublicKeyDict, kSecAttrKeyClass, kSecAttrKeyClassPublic);
  CFDictionaryAddValue(savePublicKeyDict, kSecAttrApplicationTag, kTidasPublicKeyName);
  
  OSStatus err = SecItemDelete(savePublicKeyDict);
  while (err == errSecDuplicateItem)
  {
    err = SecItemDelete(savePublicKeyDict);
  }
  return true;
}

+(bool) deletePrivateKey {
  CFMutableDictionaryRef getPrivateKeyRef = newCFDict;
  CFDictionarySetValue(getPrivateKeyRef, kSecClass, kSecClassKey);
  CFDictionarySetValue(getPrivateKeyRef, kSecAttrKeyClass, kSecAttrKeyClassPrivate);
  CFDictionarySetValue(getPrivateKeyRef, kSecAttrLabel, kTidasPrivateKeyName);
  CFDictionarySetValue(getPrivateKeyRef, kSecReturnRef, kCFBooleanTrue);
  
  OSStatus err = SecItemDelete(getPrivateKeyRef);
  while (err == errSecDuplicateItem)
  {
    err = SecItemDelete(getPrivateKeyRef);
  }
  return true;
}

+ (void) generateSignatureForData:(NSData *)inputData withCompletion:(void(^)(NSData*, NSError*))completion {
  const uint8_t * const digestData = [inputData bytes];
  size_t digestLength = [inputData length];

  uint8_t signature[256] = { 0 };
  size_t signatureLength = sizeof(signature);

  OSStatus status = SecKeyRawSign([self lookupPrivateKeyRef], kSecPaddingPKCS1, digestData, digestLength, signature, &signatureLength);

  if (status == errSecSuccess) {
    completion([NSData dataWithBytes:signature length:signatureLength], nil);
  }
  else
  {
    NSError *error = [NSError errorWithDomain:@"SecKeyError" code:status userInfo:nil];
    completion(nil, error);
  }
}

+ (CFDictionaryRef) dictionaryWithKeyPairs:(CFArrayRef *)pairs {
  return nil; 
}

@end
