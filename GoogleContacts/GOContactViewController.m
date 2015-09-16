//
//  GOContactViewController.m
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

#import "GOContactViewController.h"
#import "GOContact.h"
#import "GOContact+Additional.h"

@interface GOContactViewController ()

@property (nonatomic,strong) NSArray *data;

@end

@implementation GOContactViewController

- (instancetype) initWithContact:(GOContact*)contact{
	if(!(self=[super initWithStyle:UITableViewStyleGrouped])) return nil;
	self.contact = contact;
	self.title = self.contact.fullName;
	return self;
}

#pragma mark View Lifecycle
- (void) viewDidLoad {
    [super viewDidLoad];
	
	self.tableView.allowsSelection = NO;
	NSMutableArray *array = [NSMutableArray array];
	
	if(self.contact.fullName)
		[array addObject:@{@"text":self.contact.fullName,@"label":NSLocalizedString(@"Name", @"")}];
	
	if(self.contact.title)
		[array addObject:@{@"text":self.contact.title,@"label":NSLocalizedString(@"Title", @"")}];
	
	for(NSString *email in self.contact.emails)
		[array addObject:@{@"text":email,@"label":NSLocalizedString(@"Email", @"")}];
	
	for(NSString *phone in self.contact.phoneNumbers)
		[array addObject:@{@"text":phone,@"label":NSLocalizedString(@"Phone", @"")}];
	
	if(self.contact.address)
		[array addObject:@{@"text":self.contact.title,@"label":NSLocalizedString(@"Address", @"")}];
	
	if(self.contact.birthday)
		[array addObject:@{@"text":self.contact.birthday,@"label":NSLocalizedString(@"Birthday", @"")}];
	
	self.data = array.copy;
	
}

#pragma mark - Table view data source
- (NSInteger) numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}
- (NSInteger) tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.data.count;
}
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
	UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"Cell"];
	
	if(!cell){
		cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:@"Cell"];
	}
	
	NSDictionary *dict = self.data[indexPath.row];
	cell.textLabel.text = dict[@"text"];
	cell.detailTextLabel.text = dict[@"label"];

    return cell;
}

@end
