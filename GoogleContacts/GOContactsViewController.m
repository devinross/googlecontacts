//
//  GOContactsViewController.m
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

#import "GOContactsViewController.h"
#import "GOContactViewController.h"
#import "GOContact.h"
#import "GOContact+Additional.h"
#import "GoogleContactsSession.h"

@interface GOContactsViewController () <UISearchBarDelegate,UISearchResultsUpdating>

@property (nonatomic,strong) UILocalizedIndexedCollation *collation;
@property (nonatomic,strong) UILocalizedIndexedCollation *filteredCollation;
@property (nonatomic,strong) NSArray *filteredData;
@property (nonatomic,strong) NSArray *data;

@end

@implementation GOContactsViewController

- (id) init{
	if(!(self=[super init])) return nil;
	self.title = NSLocalizedString(@"Contacts", @"");
	return self;
}

#pragma mark View Lifecycle
- (void) loadView{
	[super loadView];
	self.searchController = [[UISearchController alloc] initWithSearchResultsController:nil];
	self.searchController.searchResultsUpdater = self;
	self.searchController.dimsBackgroundDuringPresentation = NO;
	self.searchController.searchBar.delegate = self;
	self.tableView.tableHeaderView = self.searchController.searchBar;
}
- (void) viewDidLoad {
    [super viewDidLoad];

	UIView *header = [[UIView alloc] initWithFrame:CGRectMake(0, 0, CGRectGetWidth(self.view.frame), 88)];
	header.backgroundColor = [UIColor whiteColor];
	
	self.sortSwitch = [[UISwitch alloc] initWithFrame:CGRectMake(CGRectGetWidth(self.view.frame)-80, 8, 60, 34)];
	self.sortSwitch.on = [[NSUserDefaults standardUserDefaults] boolForKey:@"ContactsNameSort"];
	[self.sortSwitch addTarget:self action:@selector(changeSort:) forControlEvents:UIControlEventValueChanged];
	[header addSubview:self.sortSwitch];
	
	UILabel *sortByName = [[UILabel alloc] initWithFrame:CGRectMake(14, 0, CGRectGetMinX(self.sortSwitch.frame)-12, 44)];
	sortByName.text = NSLocalizedString(@"Sort by first name", @"");
	sortByName.font = [UIFont boldSystemFontOfSize:14];
	[header addSubview:sortByName];
	
	
	self.sortCell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:nil];
	[self.sortCell.contentView addSubview:header];
	
	[self.tableView registerClass:[UITableViewCell class] forCellReuseIdentifier:@"Cell"];
	[self fetchContacts];
	
	self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel target:self action:@selector(dismiss:)];

}


#pragma mark Data
- (void) fetchContacts{
	
	self.tableView.tableFooterView = self.loadingIndicatorView;
	[[GoogleContactsSession sharedSession] fetchAllContactsWithCompletionHandler:^(NSArray *contacts, NSError *error) {
		if (error != nil) {
			NSLog(@"error: %@", error);
		}
		self.tableView.tableFooterView = nil;
		self.contacts = contacts;
		[self.tableView reloadData];
	}];
	
}
- (void) setupSortData{
	
	
	UILocalizedIndexedCollation *collation = [UILocalizedIndexedCollation currentCollation];
	NSInteger sectionCount = [[collation sectionTitles] count]; //section count is take from sectionTitles and not sectionIndexTitles
	NSMutableArray *sections = [NSMutableArray arrayWithCapacity:sectionCount];
	
	for(NSInteger i = 0; i < sectionCount; i++){
		[sections addObject:@{@"objects":[NSMutableArray array],@"indexTitle":collation.sectionIndexTitles[i],@"titles":collation.sectionTitles[i]}];
	}
	
	for(NSInteger i=0; i<_contacts.count; i++){
		GOContact *contact = _contacts[i];
		NSString *name = self.sortSwitch.isOn ? contact.firstNameSortString : contact.sortString;
		NSInteger section = [collation sectionForObject:name collationStringSelector:@selector(self)];
		[sections[section][@"objects"] addObject:contact];
	}
	
	for(NSInteger i=0;i<sections.count;i++){
		if([sections[i][@"objects"] count] > 0){
			
			[sections[i][@"objects"] sortUsingComparator:^(GOContact *one, GOContact *two){
				return [one.sortString compare:two.sortString];
			}];
			
			continue;
		}
		[sections removeObjectAtIndex:i];
		i--;
	}
	
	self.collation = collation;
	self.data = sections;
	
	[self updateSearchWithString:self.searchController.searchBar.text];
	
}
- (void) updateSearchWithString:(NSString*)string{
	
	
	if(string.length < 1){
		self.filteredCollation = self.collation;
		self.filteredData = self.filteredData;
		return;
	}
	
	
	string = string.lowercaseString;
	
	UILocalizedIndexedCollation *collation = [UILocalizedIndexedCollation currentCollation];
	NSInteger sectionCount = [[collation sectionTitles] count]; //section count is take from sectionTitles and not sectionIndexTitles
	NSMutableArray *sections = [NSMutableArray arrayWithCapacity:sectionCount];
	
	for(NSInteger i = 0; i < sectionCount; i++){
		[sections addObject:@{@"objects":[NSMutableArray array],@"indexTitle":collation.sectionIndexTitles[i],@"titles":collation.sectionTitles[i]}];
	}
	
	
	for(NSInteger i=0; i<_contacts.count; i++){
		GOContact *contact = _contacts[i];
		BOOL found = NO;
		for(NSString *term in contact.searchableTerms){
			if(!([term.lowercaseString rangeOfString:string].location == NSNotFound)){
				found = YES;
				break;
			}
		}
		
		if(!found) continue;
		NSString *name = self.sortSwitch.isOn ? contact.firstNameSortString : contact.sortString;
		NSInteger section = [collation sectionForObject:name collationStringSelector:@selector(self)];
		[sections[section][@"objects"] addObject:contact];
	}
	
	
	
	for(NSInteger i=0;i<sections.count;i++){
		if([sections[i][@"objects"] count] > 0){
			[sections[i][@"objects"] sortUsingComparator:^(GOContact *one, GOContact *two){
				return [one.sortString compare:two.sortString];
			}];
			continue;
		}
		[sections removeObjectAtIndex:i];
		i--;
	}
	
	
	self.filteredCollation = collation;
	self.filteredData = sections;
	
	
}


#pragma mark UISearchViewControlllerDelegate
- (void) updateSearchResultsForSearchController:(UISearchController *)searchController{
	[self updateSearchWithString:searchController.searchBar.text];
	[self.tableView reloadData];
}

#pragma mark Button Actions
- (void) changeSort:(UISwitch*)sender{
	[self setupSortData];

	[self.tableView reloadData];
	[[NSUserDefaults standardUserDefaults] setBool:self.sortSwitch.isOn forKey:@"ContactsNameSort"];
	[[NSUserDefaults standardUserDefaults] synchronize];
	
}
- (void) dismiss:(id)sender{
	[self dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark - Table View
#pragma mark - Table view data source
- (NSInteger) numberOfSectionsInTableView:(UITableView *)tableView{
	if(self.searchController.active)
		return self.filteredData.count;
	return self.data.count + (self.showSortCell ? 1 : 0);
}
- (NSInteger) tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section{
	if(self.searchController.active)
		return [self.filteredData[section][@"objects"] count];
	
	if(section == 0 && self.showSortCell)
		return 1;
	
	NSInteger sect = section - (self.showSortCell ? 1 : 0);
	return [self.data[sect][@"objects"] count];
}
- (UITableViewCell *) tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath{
	
	if(self.showSortCell && indexPath.section == 0 && !self.searchController.isActive)
		return self.sortCell;
	
	static NSString *CellIdentifier = @"Cell";
	
	UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
	if (cell == nil) {
		cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:CellIdentifier];
	}
	
	GOContact *contact = [self contactAtIndexPath:indexPath];
	cell.textLabel.attributedText = contact.attributedCompositeString;
	
	return cell;
}
- (void) tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath{
	GOContact *contact = [self contactAtIndexPath:indexPath];

	GOContactViewController *vc = [[GOContactViewController alloc] initWithContact:contact];
	[self.navigationController pushViewController:vc animated:YES];
}
- (NSArray *) sectionIndexTitlesForTableView:(UITableView *)tableView {
	if(self.searchController.isActive)
		return [self.filteredData valueForKey:@"titles"];
	
	return [self.data valueForKey:@"titles"];
}
- (NSString *) tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
	if(self.searchController.isActive)
		return self.filteredData[section][@"indexTitle"];
	if(section == 0 && self.showSortCell) return nil;
	return self.data[section-(self.showSortCell ? 1 :0)][@"indexTitle"];
}
- (GOContact*) contactAtIndexPath:(NSIndexPath*)indexPath{
	
	if(self.searchController.active)
		return self.filteredData[indexPath.section][@"objects"][indexPath.row];
	
	if(indexPath.section == 0 && self.showSortCell)
		return nil;
	
	NSInteger section = indexPath.section - (self.showSortCell ? 1 : 0);
	
	return self.data[section][@"objects"][indexPath.row];
}


#pragma mark Properties
- (void) setContacts:(NSArray *)contacts{
	if (_contacts == contacts) return;
	_contacts = contacts;
	[self setupSortData];
}
- (UIView*) loadingIndicatorView{
	if(_loadingIndicatorView) return _loadingIndicatorView;
	_loadingIndicatorView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, CGRectGetWidth(self.tableView.frame), 60)];
	UIActivityIndicatorView *ind = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
	ind.center = CGPointMake(_loadingIndicatorView.frame.size.width/2, _loadingIndicatorView.frame.size.height/2);
	[ind startAnimating];
	[_loadingIndicatorView addSubview:ind];
	return _loadingIndicatorView;
}

@end