#import "ViewController.h"
#import "ZADownloadManager.h"
#import "DownloadItem.h"
#import "DownloadItemTableViewCell.h"

#define urlString1 @"https://manuals.info.apple.com/MANUALS/1000/MA1565/en_US/iphone_user_guide.pdf"
#define urlString2 @"https://az764295.vo.msecnd.net/stable/c7d83e57cd18f18026a8162d042843bda1bcf21f/VSCode-darwin-stable.zip"
#define urlString3 @"https://dl.google.com/dl/android/studio/install/3.4.1.0/android-studio-ide-183.5522156-mac.dmg"
#define urlString4 @"https://files1.coccoc.com/browser/mac/setup.dmg"
#define urlString5 @"https://download.skype.com/s4l/download/mac/Skype-8.49.0.49.dmg"
#define urlString6 @"https://dl.google.com/chrome/mac/stable/CHFA/googlechrome.dmg"

#define kDownloadTableViewCellId @"kDownloadTableViewCellId"

@interface ViewController ()<UITableViewDelegate,UITableViewDataSource>

@property (strong, nonatomic) UITableView                             *downloaderTableView;
@property (strong, nonatomic) NSMutableArray<DownloadItem *>        *dowloadModels;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];

    [self setupviews];
    [self setupFakeData];
}

#pragma mark - Setup

- (void)setupviews {
    _downloaderTableView = [[UITableView alloc] initWithFrame:self.view.bounds style:UITableViewStylePlain];
    [_downloaderTableView registerClass:DownloadItemTableViewCell.class forCellReuseIdentifier:kDownloadTableViewCellId];
    _downloaderTableView.dataSource = self;
    _downloaderTableView.delegate = self;
    [self.view addSubview:_downloaderTableView];
    
    // setup DownloadManager
    ZADownloadManager.sharedZADownloadManager.maxConcurrentDownloads = 1;        // maximum concurrent downloads.
}

- (void)setupFakeData {
    _dowloadModels = [NSMutableArray new];

    [_dowloadModels addObject:CREATE_DOWNLOADITEM(urlString1, @"APPLE DOCS - BUSINESS 1", ZADownloadModelPriroityHigh)];
    [_dowloadModels addObject:CREATE_DOWNLOADITEM(urlString1, @"APPLE DOCS - BUSINESS 2", ZADownloadModelPriroityMedium)];
    [_dowloadModels addObject:CREATE_DOWNLOADITEM(urlString1, @"APPLE DOCS - BUSINESS 3", ZADownloadModelPriroityLow)];
    
    [_dowloadModels addObject:CREATE_DOWNLOADITEM(urlString2, @"VS CODE ZIP", ZADownloadModelPriroityMedium)];
    [_dowloadModels addObject:CREATE_DOWNLOADITEM(urlString3, @"Android Studio", ZADownloadModelPriroityLow)];
    [_dowloadModels addObject:CREATE_DOWNLOADITEM(urlString4, @"COC COC", ZADownloadModelPriroityHigh)];
    [_dowloadModels addObject:CREATE_DOWNLOADITEM(urlString5, @"SKYPE", ZADownloadModelPriroityMedium)];
    [_dowloadModels addObject:CREATE_DOWNLOADITEM(urlString6, @"CHROME", ZADownloadModelPriroityLow)];
}

#pragma mark - Layout

- (void)viewWillLayoutSubviews {
    [super viewWillLayoutSubviews];
    
    _downloaderTableView.frame = self.view.bounds;
}

#pragma mark - UITableView DataSource

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    DownloadItemTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:kDownloadTableViewCellId forIndexPath:indexPath];

    DownloadItem *downloadModel = _dowloadModels[indexPath.row];
    cell.downloadModel = downloadModel;
    
    return cell;
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return _dowloadModels.count;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return 180;
}

@end
