//
//  ViewController.m
//  ArrowsObjC
//
//  Created by rd on 12/2/18.
//  Copyright © 2018 rd. All rights reserved.
//

#import "ViewController.h"

@interface ViewController ()<UISearchBarDelegate>

@property (weak, nonatomic) IBOutlet UISearchBar *searchView;
@property (weak, nonatomic) IBOutlet WKWebView *webView;

@end

@implementation ViewController

- (void)log:(NSString*)str {
    NSLog(@"%@", str);
}

- (void)load:(NSURL*)url {
    NSURLRequest* request = [[NSURLRequest alloc] initWithURL:url];
    [self log:[NSString stringWithFormat:@"%@", request]];
    [self.webView loadRequest:request];
}

- (void)searchBarSearchButtonClicked:(UISearchBar *)searchBar {
    [self load:[NSURL URLWithString:self.searchView.text]];
}

- (void)viewDidLoad {
    [super viewDidLoad];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    [self load:[NSURL URLWithString:self.searchView.text]];
}

@end
