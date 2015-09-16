//
//  GOContact.m
//  Created by Devin Ross on 04/09/15.
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

#import "GOContact.h"

@implementation GOContact


- (NSString*) description{
	
	
	NSMutableString *str = [[NSMutableString alloc] initWithString:@""];
	
	if(self.fullName)
		[str appendFormat:@" name: %@",self.fullName];
	if(self.title)
		[str appendFormat:@" title: %@",self.title];
	if(self.phoneNumbers.count > 0)
		[str appendFormat:@" phones: %@",[self.phoneNumbers componentsJoinedByString:@", "]];
	
	if(self.emails.count > 0)
		[str appendFormat:@" emails: %@",[self.emails componentsJoinedByString:@", "]];
	
	if(self.birthday)
		[str appendFormat:@" birthday: %@",self.birthday];
	
	if(self.address)
		[str appendFormat:@" address: %@",self.address];
	
	return [NSString stringWithFormat:@"<GOContact%@>",str];
}

@end
