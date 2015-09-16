//
//  GOContact+Additional.m
//  Created by Devin Ross on 9/16/15.
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

#import "GOContact+Additional.h"

@implementation GOContact (Additional)


- (NSAttributedString*) attributedCompositeString{
	
	NSString *first = self.firstName;
	NSString *composite = self.fullName;
	NSString *email = self.firstEmail;
	
	
	if(composite.length < 1 && email.length > 0){
		NSMutableAttributedString *str = [[NSMutableAttributedString alloc] initWithString:email];
		[str setAttributes:@{ NSFontAttributeName : [UIFont boldSystemFontOfSize:18]} range:NSMakeRange(0, str.length)];
		return str;
	}
	
	if(!composite)
		composite = @"";
	
	
	NSMutableAttributedString *str = [[NSMutableAttributedString alloc] initWithString:composite];
	NSRange range = NSMakeRange(first.length, str.length - first.length);
	[str setAttributes:@{ NSFontAttributeName : [UIFont boldSystemFontOfSize:18]} range:range];
	
	return str;
}
- (NSString*) sortString{
	
	NSString *first = self.firstName;
	NSString *last = self.lastName;
	NSString *email = self.firstEmail;
	
	
	if(last && first)
		return [NSString stringWithFormat:@"%@ %@",last,first];
	
	if(last)
		return last;
	
	if(first)
		return first;
	
	if(email)
		return email;
	
	return @"";
	
	
}
- (NSString*) firstEmail{
	if(self.emails.count < 1) return nil;
	return self.emails[0];
}
- (NSString*) firstNameSortString{
	NSString *first = self.firstName;
	NSString *last = self.lastName;
	NSString *email = self.firstEmail;
	
	
	if(last && first)
		return [NSString stringWithFormat:@"%@ %@",first,last];
	
	if(first)
		return first;
	
	if(last)
		return last;
	
	if(email)
		return email;
	
	return @"";
	
	
}
- (NSString*) firstName{
	return self.givenName;
}
- (NSString*) lastName{
	return self.familyName;
}
- (void) _addString:(NSString*)string toArray:(NSMutableArray*)array{
	if(string && [string isKindOfClass:[NSString class]] && string.length > 0)
		[array addObject:string];
}
- (NSArray*) searchableTerms{
	
	NSMutableArray *ret = [NSMutableArray array];
	
	[self _addString:self.familyName toArray:ret];
	[self _addString:self.givenName toArray:ret];
	[self _addString:self.fullName toArray:ret];
	[self _addString:self.title toArray:ret];
	
	for(NSString *str in self.emails){
		[self _addString:str toArray:ret];
	}
	[self _addString:self.address toArray:ret];
	
	
	return ret.copy;
}

@end
