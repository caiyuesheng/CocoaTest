//
//  ViewController.m
//  CocoaTest
//
//  Created by yuesheng on 16/3/22.
//  Copyright © 2016年 yuesheng. All rights reserved.
//

#import "ViewController.h"
#import "VideoViewController.h"
#import <SDWebImage/UIImageView+WebCache.h>

@interface ViewController ()<UIScrollViewDelegate, UITableViewDelegate, UITableViewDataSource>
@property (nonatomic, weak) IBOutlet UITableView *tableView;
@property (nonatomic, strong) NSArray *dataSource;
@property (weak, nonatomic) IBOutlet UIImageView *imgv;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.dataSource = @[@"拍摄"];
    [self.imgv sd_setImageWithURL:[NSURL URLWithString:@"http://test8093.huami.net.cn/about/"]];
}

- (void)viewWillAppear:(BOOL)animated{
    [super viewWillAppear:animated];
}


- (void)viewDidAppear:(BOOL)animated{
    [super viewDidAppear:animated];
    
}

#pragma mark - UITableView

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath{
    return 40;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section{
    return self.dataSource.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath{
    static NSString *key = @"CELL_KEY";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:key];
    if(!cell){
        cell = [[UITableViewCell alloc]initWithStyle:UITableViewCellStyleDefault reuseIdentifier:key];
    }
    NSString *item = [self.dataSource objectAtIndex:indexPath.row];
    cell.textLabel.text = item;
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath{
    if(indexPath.row == 0){
        VideoViewController *vc = [VideoViewController new];
        [self.navigationController pushViewController:vc animated:YES];
    }
}


@end
