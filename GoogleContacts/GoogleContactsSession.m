//
//  GoogleContactsSession.m
//  Created by Devin Ross on 9/15/15.
//
/*
 
 Google Contacts || https://github.com/devinross/googlecontacts
 
 Permission is hereby granted, free of charge, to any person
 obtaining a copy of this software and associated documentation
 files (the "Software"), to deal in the Software without
 restriction, including without limitation the rights to use,
 copy, modify, merge, publish, distribute, sublicense, and/or sell
 copies of the Software, and to permit persons to whom the
 Software is furnished to do so, subject to the following
 conditions:
 
 The above copyright notice and this permission notice shall be
 included in all copies or substantial portions of the Software.
 
 THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
 EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES
 OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
 NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT
 HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY,
 WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
 FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR
 OTHER DEALINGS IN THE SOFTWARE.
 
 */

#import "GoogleContactsSession.h"
#import "GOContact.h"

#import <Google/SignIn.h>
#import <GoogleSignIn/GIDSignIn.h>
#import <GoogleSignIn/GIDGoogleUser.h>
#import <GoogleSignIn/GIDProfileData.h>
#import <GoogleSignIn/GIDAuthentication.h>
#import <RestKit/RestKit.h>
#import <RKXMLReaderSerialization/RKXMLReaderSerialization.h>

static NSString const* ContactsFeedUrl = @"https://www.google.com/m8/feeds/contacts/default/full?max-results=2000";
static NSString const* ContactsScopeUrl = @"https://www.googleapis.com/auth/contacts.readonly";

@interface GoogleContactsSession () <GIDSignInDelegate, GIDSignInUIDelegate>
@end

@implementation GoogleContactsSession

+ (GoogleContactsSession*) sharedSession{
	static GoogleContactsSession *sharedMyManager = nil;
	static dispatch_once_t onceToken;
	dispatch_once(&onceToken, ^{
		sharedMyManager = [[self alloc] init];
	});
	return sharedMyManager;
}
- (id) init{
	if(!(self=[super init])) return nil;
	NSError* error = nil;
	[[GGLContext sharedInstance] configureWithError: &error];
	if (error != nil) {
		NSLog(@"Error configuring the Google context: %@", error);
	}
	
	[GIDSignIn sharedInstance].delegate = self;
	[GIDSignIn sharedInstance].uiDelegate = self;
	[self addContactsScopeToSignIn:[GIDSignIn sharedInstance]];
	[[GIDSignIn sharedInstance] signInSilently];

	return self;
}


- (void) addContactsScopeToSignIn:(GIDSignIn *)signIn {
	
	NSArray *currentScopes = signIn.scopes;
	BOOL scopesUpdated = NO;
	if (![currentScopes containsObject:ContactsScopeUrl]) {
		currentScopes = [currentScopes arrayByAddingObject:ContactsScopeUrl];
		scopesUpdated = YES;
	}
	
	if (scopesUpdated) {
		signIn.scopes = currentScopes;
	}
}

#pragma mark GIDSignInDelegate
- (void) signIn:(GIDSignIn *)signIn didSignInForUser:(GIDGoogleUser *)user withError:(NSError *)error {
	// The sign-in flow has finished and was successful if |error| is |nil|.
	if(user != nil){
		if([self.delegate respondsToSelector:@selector(didSignInWithGoogleContactsSession:)])
			[self.delegate didSignInWithGoogleContactsSession:self];
	}else{
		if([self.delegate respondsToSelector:@selector(googleContactsSession:signInDidFailWithError:)]){
			[self.delegate googleContactsSession:self signInDidFailWithError:error];
		}
	}

}
- (void) signIn:(GIDSignIn *)signIn didDisconnectWithUser:(GIDGoogleUser *)user withError:(NSError *)error {
	// Finished disconnecting |user| from the app successfully if |error| is |nil|.
	NSLog(@"didDisconnectUser. User: %@, error: %@", user.description, error.description);
	if(error == nil){
		if([self.delegate respondsToSelector:@selector(didSignOutOfSession:)])
			[self.delegate didSignOutOfSession:self];
	}
}
- (void) signIn:(GIDSignIn *)signIn presentViewController:(UIViewController *)viewController{
	// If implemented, this method will be invoked when sign in needs to display a view controller.
	// The view controller should be displayed modally (via UIViewController's |presentViewController|
	// method, and not pushed unto a navigation controller's stack.
	[self.delegate presentGoogleContactAuthenticationViewController:viewController];
}
- (void) signIn:(GIDSignIn *)signIn dismissViewController:(UIViewController *)viewController{
	// If implemented, this method will be invoked when sign in needs to dismiss a view controller.
	// Typically, this should be implemented by calling |dismissViewController| on the passed
	// view controller.
	[self.delegate dismissGoogleContactAuthenticationViewController:viewController];
}




#pragma mark - RestKit
- (RKResponseDescriptor *) allContactsResponseDescriptior {
	RKObjectMapping *mapping = [RKObjectMapping mappingForClass:[GOContact class]];
	[mapping addAttributeMappingsFromDictionary:@{
												  
												  @"gd:name.gd:fullName.text"                               : @"fullName",
												  @"gd:name.gd:familyName.text"                             : @"familyName",
												  @"gd:name.gd:givenName.text"                              : @"givenName",

												  @"title.text"                                             : @"title",
												  @"id.text"                                                : @"contactId",
												  @"gd:phoneNumber.uri"                                     : @"phoneNumbers",
												  @"gd:email.address"                                       : @"emails",
												  @"gContact:birthday.when"                                 : @"birthday",
												  @"gd:structuredPostalAddress.gd:formattedAddress.text"    : @"address"
												  }];
	
	RKResponseDescriptor *responseDescriptior = [RKResponseDescriptor responseDescriptorWithMapping:mapping method:RKRequestMethodGET pathPattern:nil keyPath:@"feed.entry" statusCodes:nil];
	return responseDescriptior;
}
- (NSURL *) contactsFeedURL {
	return [NSURL URLWithString:(NSString *)ContactsFeedUrl];
}
- (NSMutableURLRequest *) allContactsRequestWithAccessToken:(NSString *)accessToken {
	
	// we have a likely valid access token
	
	NSMutableURLRequest *request = [[NSMutableURLRequest alloc] initWithURL:[self contactsFeedURL]];
	request.HTTPMethod = @"GET";
	NSString *value = [NSString stringWithFormat:@"%s %@",
					   "Bearer", accessToken];
	[request setValue:value forHTTPHeaderField:@"Authorization"];
	//    GData-Version: 3.0
	[request setValue:@"3.0" forHTTPHeaderField:@"GData-Version"];
	return request;
}
- (void) fetchAllContactsWithCompletionHandler:(void (^)(NSArray *contacts, NSError *error))completionHandler {
	[self fetchAllContactsWithAccessToken:self.accessToken completitionHandler:completionHandler];
}
- (void) fetchAllContactsWithAccessToken:(NSString *)accessToken completitionHandler:(void (^)(NSArray *contacts, NSError *error))completionHandler {
	
	[RKMIMETypeSerialization registerClass:[RKXMLReaderSerialization class] forMIMEType:@"application/atom+xml"];
	
	NSMutableURLRequest *contactsRequest = [self allContactsRequestWithAccessToken:accessToken];
	RKResponseDescriptor *responseDescriptior = [self allContactsResponseDescriptior];
	
	RKObjectRequestOperation *contactsRequestOperation = [[RKObjectRequestOperation alloc] initWithRequest:contactsRequest responseDescriptors:@[responseDescriptior]];
	[contactsRequestOperation setCompletionBlockWithSuccess:^(RKObjectRequestOperation *operation, RKMappingResult *mappingResult) {
		completionHandler(mappingResult.array, nil);
	} failure:^(RKObjectRequestOperation *operation, NSError *error) {
		completionHandler(nil, error);
	}];
	[contactsRequestOperation start];
}


- (NSURL*) imageURLWithDimension:(NSInteger)dimension{
	return [[GIDSignIn sharedInstance].currentUser.profile imageURLWithDimension:dimension];
}
- (void) authenticate {
	[[GIDSignIn sharedInstance] signIn];
}
- (void) logout {
	[[GIDSignIn sharedInstance] signOut];
	[[GIDSignIn sharedInstance] disconnect];
}


#pragma mark Properties
- (NSString*) name{
	return [GIDSignIn sharedInstance].currentUser.profile.name;
}
- (NSString*) email{
	return [GIDSignIn sharedInstance].currentUser.profile.email;
}
- (BOOL) hasImage{
	return [GIDSignIn sharedInstance].currentUser.profile.hasImage;
}
- (BOOL) isLoggedIn{
	return [GIDSignIn sharedInstance].currentUser != nil;
}

- (NSString*) accessToken{
	return [GIDSignIn sharedInstance].currentUser.authentication.accessToken;
}

@end
