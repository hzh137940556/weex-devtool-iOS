//
//  WXRenderTracingViewController.m
//  TBWXDevTool
//
//  Created by 齐山 on 2017/7/4.
//  Copyright © 2017年 Taobao. All rights reserved.
//

#import "WXRenderTracingViewController.h"
#import <UIKit/UIKit.h>
#import "WXDebugger.h"
#import "WXRenderTracingTableViewCell.h"
#import "WXTracingViewControllerManager.h"
#import "WXSubRenderTracingTableViewCell.h"

@implementation WXShowTracing
@end

@implementation WXShowTracingTask
@end

@interface WXRenderTracingViewController ()<UITableViewDelegate,UITableViewDataSource>

@property (strong,nonatomic) UITableView *table;
@property (strong,nonatomic) NSArray     *content;
@property (strong,nonatomic) NSMutableArray *tasks;
@property (nonatomic) NSTimeInterval begin;
@property (nonatomic) NSTimeInterval end;
@property (nonatomic,copy) NSString *sectionTitle;
@property (assign, nonatomic) BOOL isExpand; //是否展开
@property (strong, nonatomic) NSIndexPath *selectedIndexPath;//展开的cell的下标

@end

@implementation WXRenderTracingViewController

- (instancetype)initWithFrame:(CGRect )frame
{
    if ((self = [super init])) {
        self.view.frame = frame;
    }
    return self;
}
    
   
- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor whiteColor];
    CGRect rect = [UIScreen mainScreen].bounds;
    self.view.frame =  CGRectMake(0, 0, rect.size.width, rect.size.height);
    [self cofigureTableview];
    
}

-(void)refreshNewData
{
    self.tasks = [NSMutableArray new];
    NSMutableDictionary *taskData = [[WXTracingManager getTracingData] mutableCopy];
    NSArray *instanceIds = [[WXSDKManager bridgeMgr] getInstanceIdStack];
    if(instanceIds && [instanceIds count] >0){
        for (NSInteger i = 0; i< [instanceIds count]; i++) {
            NSString *instanceId =instanceIds[i];
            WXTracingTask *task = [taskData objectForKey:instanceId];
            //            NSString *str = [WXUtility JSONString:[self formatTask:task]];
            WXShowTracingTask *showTask = [WXShowTracingTask new];
            showTask.counter = task.counter;
            showTask.iid = task.iid;
            showTask.tag = task.tag;
            showTask.bundleUrl = task.bundleUrl;
            showTask.bundleJSType = task.bundleJSType;
            NSMutableArray *tracings = [NSMutableArray new];
            for (WXTracing *tracing in task.tracings) {
                if(![WXTracingEnd isEqualToString:tracing.ph]){
                    [tracings addObject:tracing];
                    if(showTask.begin <0.0001){
                        showTask.begin = tracing.ts;
                    }
                    
                    if(tracing.ts < showTask.begin){
                        showTask.begin = tracing.ts;
                    }
                    if((tracing.ts +tracing.duration) > showTask.end){
                        showTask.end = tracing.ts +tracing.duration ;
                    }
                }
            }
            showTask.tracings = [NSMutableArray new];
            showTask.tracings = tracings;
            [self.tasks addObject:showTask];
        }
    }
    if(!self.tasks || [self.tasks count] == 0)
    {
        WXShowTracingTask *showTask = [WXShowTracingTask new];
        showTask.tracings = [NSMutableArray new];
        self.tasks = [NSMutableArray new];
        [self.tasks addObject:showTask];
    }
    [self.table reloadData];
}

-(WXShowTracing *)getShowTracing:(WXTracing *)tracing tracings:(NSMutableArray *)tracings
{
    for (WXShowTracing *t in tracings) {
        if(t.traceId ==  tracing.parentId){
            return t;
        }
    }
    return nil;
}

- (WXShowTracing *)copyTracing:(WXTracing *)tracing
{
    WXShowTracing *newTracing = [WXShowTracing new];
    if(tracing.ref.length>0){
        newTracing.ref = tracing.ref;
    }
    if(tracing.parentRef.length>0){
        newTracing.parentRef = tracing.parentRef;
    }
    if(tracing.className.length>0){
        newTracing.className = tracing.className;
    }
    if(tracing.name.length>0){
        newTracing.name = tracing.name;
    }
    if(tracing.fName.length>0){
        newTracing.fName = tracing.fName;
    }
    if(tracing.ph.length>0){
        newTracing.ph = tracing.ph;
    }
    if(tracing.iid.length>0){
        newTracing.iid = tracing.iid;
    }
    newTracing.parentId = tracing.parentId;
    if(tracing.traceId>0){
        newTracing.traceId = tracing.traceId;
    }
    if(tracing.ts>0){
        newTracing.ts = tracing.ts;
    }
    if(tracing.threadName.length>0){
        newTracing.threadName = tracing.threadName;
    }
    return newTracing;
}

-(void)refreshData
{
    self.tasks = [NSMutableArray new];
    NSMutableDictionary *taskData = [[WXTracingManager getTracingData] mutableCopy];
    NSArray *instanceIds = [[WXSDKManager bridgeMgr] getInstanceIdStack];
    if(instanceIds && [instanceIds count] >0){
        for (NSInteger i = 0; i< [instanceIds count]; i++) {
            NSString *instanceId =instanceIds[i];
            WXTracingTask *task = [taskData objectForKey:instanceId];
            //            NSString *str = [WXUtility JSONString:[self formatTask:task]];
            WXShowTracingTask *showTask = [WXShowTracingTask new];
            showTask.counter = task.counter;
            showTask.iid = task.iid;
            showTask.tag = task.tag;
            showTask.bundleUrl = task.bundleUrl;
            showTask.bundleJSType = task.bundleJSType;
            NSMutableArray *tracings = [NSMutableArray new];
            for (WXTracing *tracing in task.tracings) {
                if(![WXTracingEnd isEqualToString:tracing.ph]){
                    WXShowTracing *showTracing = [self getShowTracing:tracing tracings:tracings];
                    if(showTask.begin <0.0001){
                        showTask.begin = tracing.ts;
                    }
                    
                    if(tracing.ts < showTask.begin){
                        showTask.begin = tracing.ts;
                    }
                    if((tracing.ts +tracing.duration) > showTask.end){
                        showTask.end = tracing.ts +tracing.duration ;
                    }
                    
                    if(!showTracing){
                        showTracing = [self copyTracing:tracing];
                        showTracing.subTracings = [NSMutableArray new];
                        [tracings addObject:showTracing];
                        if((tracing.ts +tracing.duration) > showTracing.ts+showTracing.duration){
                            showTracing.duration =  tracing.ts +tracing.duration - showTracing.ts;
                        }
                        [showTracing.subTracings addObject:tracing];
                    }else{
                        if((tracing.ts +tracing.duration) > showTracing.ts+showTracing.duration){
                            showTracing.duration =  tracing.ts +tracing.duration - showTracing.ts;
                        }
                        [showTracing.subTracings addObject:tracing];
                    }
                }
                if([@"renderFinish" isEqualToString:tracing.fName] && [WXTracingInstant isEqualToString:tracing.ph] && [WXTUIThread isEqualToString:tracing.threadName])
                {
                    break;
                }
            }
            for(WXShowTracing *tracing in tracings){
                if([tracing.subTracings count] == 1){
                    tracing.subTracings = [NSMutableArray new];
                }
            }
            showTask.tracings = [NSMutableArray new];
            showTask.tracings = tracings;
            [self.tasks addObject:showTask];
        }
    }
    if(!self.tasks || [self.tasks count] == 0)
    {
        WXShowTracingTask *showTask = [WXShowTracingTask new];
        showTask.tracings = [NSMutableArray new];
        self.tasks = [NSMutableArray new];
        [self.tasks addObject:showTask];
    }
    [self.table reloadData];
}

-(void)cofigureTableview
{
    self.table = [[UITableView alloc] initWithFrame:CGRectMake(self.view.bounds.origin.x, 0, self.view.bounds.size.width, self.view.bounds.size.height-64) style:UITableViewStylePlain];
    self.table.delegate = self;
    self.table.dataSource = self;
    [self.table registerClass:[WXRenderTracingTableViewCell class] forCellReuseIdentifier:@"cellIdentifier"];
    [self.table registerClass:[WXSubRenderTracingTableViewCell class] forCellReuseIdentifier:@"subcellIdentifier"];
    [self.view addSubview:self.table];
    
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    
    return [self.tasks count];
}
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    WXShowTracingTask *task = self.tasks[section];
    NSInteger count = [task.tracings count];
    if(self.selectedIndexPath && self.selectedIndexPath.section == section){
        if (self.isExpand) {
            count = count + [self getSubTracingCount:self.selectedIndexPath];
        }
    }
    return count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell;
    
    WXShowTracingTask *task = self.tasks[indexPath.section];
//    [cell config:[task.tracings objectAtIndex:indexPath.row] begin:task.begin end:task.end];
    
    if(self.isExpand) {
        if(indexPath.section == self.selectedIndexPath.section){
            if(self.selectedIndexPath.row < indexPath.row && indexPath.row <= self.selectedIndexPath.row + [self getSubTracingCount:self.selectedIndexPath]){
                WXShowTracing *showTracing = [task.tracings objectAtIndex:self.selectedIndexPath.row];
                WXTracing *tracing = [showTracing.subTracings objectAtIndex:(indexPath.row - self.selectedIndexPath.row-1)];
                WXSubRenderTracingTableViewCell *subCell = [tableView dequeueReusableCellWithIdentifier:@"subcellIdentifier" forIndexPath:indexPath];
                [subCell config:tracing begin:task.begin end:task.end];
                cell = subCell;
            }else if(indexPath.row > self.selectedIndexPath.row + [self getSubTracingCount:self.selectedIndexPath]){
                WXRenderTracingTableViewCell *showCell = [tableView dequeueReusableCellWithIdentifier:@"cellIdentifier" forIndexPath:indexPath];
                [showCell config:[task.tracings objectAtIndex:indexPath.row - [self getSubTracingCount:self.selectedIndexPath]] begin:task.begin end:task.end];
                cell = showCell;
            }else{
                WXRenderTracingTableViewCell *showCell = [tableView dequeueReusableCellWithIdentifier:@"cellIdentifier" forIndexPath:indexPath];
                [showCell config:[task.tracings objectAtIndex:indexPath.row] begin:task.begin end:task.end];
                cell = showCell;

            }
            
            
        }else{
            WXRenderTracingTableViewCell *showCell = [tableView dequeueReusableCellWithIdentifier:@"cellIdentifier" forIndexPath:indexPath];
            [showCell config:[task.tracings objectAtIndex:indexPath.row] begin:task.begin end:task.end];
            cell = showCell;
        }
        
    }else {
        WXRenderTracingTableViewCell *showCell = [tableView dequeueReusableCellWithIdentifier:@"cellIdentifier" forIndexPath:indexPath];
        [showCell config:[task.tracings objectAtIndex:indexPath.row] begin:task.begin end:task.end];
        cell = showCell;
    }
    cell.selectionStyle = UITableViewCellSelectionStyleNone;
    return cell;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return 80;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath;
{
//    NSLog(@"title of cell %@", [_content objectAtIndex:indexPath.row]);
    NSInteger count = [self getSubTracingCount:self.selectedIndexPath];
    if(count == 0){
        self.selectedIndexPath = nil;
    }
    
    if (!self.selectedIndexPath) {
        self.isExpand = YES;
        self.selectedIndexPath = indexPath;
        [self.table beginUpdates];
        [self.table insertRowsAtIndexPaths:[self indexPathsForExpand:indexPath] withRowAnimation:UITableViewRowAnimationTop];

        [self.table endUpdates];
    } else {
        if (self.isExpand) {
            NSArray *tracings = [self  indexPathsForExpand:indexPath];
            if (self.selectedIndexPath == indexPath) {
                self.isExpand = NO;
                [self.table beginUpdates];
                [self.table deleteRowsAtIndexPaths:tracings withRowAnimation:UITableViewRowAnimationTop];
                [self.table endUpdates];
                self.selectedIndexPath = nil;
            } else if (self.selectedIndexPath.row < indexPath.row && indexPath.row <= self.selectedIndexPath.row + [tracings count]) {
                
            } else {
                self.isExpand = NO;
                [self.table beginUpdates];
                [self.table deleteRowsAtIndexPaths:[self indexPathsForExpand:self.selectedIndexPath] withRowAnimation:UITableViewRowAnimationTop];
                [self.table endUpdates];
                self.selectedIndexPath = nil;
            }
        }
    }
}

-(NSInteger)getSubTracingCount:(NSIndexPath *)selectedIndexPath
{
    WXShowTracingTask *task = [self.tasks objectAtIndex:selectedIndexPath.section];
    WXShowTracing *tracing = [task.tracings objectAtIndex:selectedIndexPath.row];
    return [tracing.subTracings count];
}

- (NSArray *)indexPathsForExpand:(NSIndexPath *)selectedIndexPath {
    WXShowTracingTask *task = [self.tasks objectAtIndex:selectedIndexPath.section];
    WXShowTracing *tracing = [task.tracings objectAtIndex:selectedIndexPath.row];
//    return @[tracing];
    
    NSMutableArray *indexPaths = [NSMutableArray array];
    for (int i = 1; i <= [tracing.subTracings count]; i++) {
        NSIndexPath *idxPth = [NSIndexPath indexPathForRow:selectedIndexPath.row + i inSection:selectedIndexPath.section];
        [indexPaths addObject:idxPth];
    }
    return [indexPaths copy];
}

#pragma mark -
#pragma section
- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
    return 58;
}
-(UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section
{
    WXTracingTask *task = [self.tasks objectAtIndex:section];
    UIView *view = [[UIView alloc] initWithFrame:CGRectMake(0, 0, tableView.frame.size.width, 18)];
    /* Create custom view to display section header... */
    UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(10, 5, tableView.frame.size.width, 18)];
    [label setFont:[UIFont boldSystemFontOfSize:14]];
    NSString *string = [NSString stringWithFormat:@"instanceId:%@",task.iid];
    if(!task.iid){
        string = @"暂时没有weex页面渲染";
    }
    /* Section header is in 0th index... */
    [label setText:string];
    [view addSubview:label];
    if(!task.iid){
        return view;
    }
    
    UILabel *subLabel = [[UILabel alloc] initWithFrame:CGRectMake(10, 22, tableView.frame.size.width, 30)];
    [subLabel setFont:[UIFont systemFontOfSize:12]];
    subLabel.lineBreakMode = NSLineBreakByWordWrapping;
    subLabel.numberOfLines = 0;
    NSString *subString = [NSString stringWithFormat:@"bundleUrl:%@",task.bundleUrl];
    /* Section header is in 0th index... */
    [subLabel setText:subString];
    [view addSubview:subLabel];
    
    [view setBackgroundColor:[UIColor colorWithRed:235/255.0 green:235/255.0 blue:235/255.0 alpha:1.0]];
    return view;
}

@end
