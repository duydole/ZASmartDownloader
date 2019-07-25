#import "ViewController.h"
#import "DowloaderTableViewCell.h"
#import "ZADownloadManager.h"

#define urlString1 @"https://manuals.info.apple.com/MANUALS/1000/MA1565/en_US/iphone_user_guide.pdf";
#define urlString2 @"https://az764295.vo.msecnd.net/stable/c7d83e57cd18f18026a8162d042843bda1bcf21f/VSCode-darwin-stable.zip";
#define urlString3 @"https://dl.google.com/dl/android/studio/install/3.4.1.0/android-studio-ide-183.5522156-mac.dmg";
#define urlString4 @"https://files1.coccoc.com/browser/mac/setup.dmg"
#define urlString5 @"https://download.skype.com/s4l/download/mac/Skype-8.49.0.49.dmg"
#define urlString6 @"https://dl.google.com/chrome/mac/stable/CHFA/googlechrome.dmg"

@interface DownloadItem : NSObject

@property NSString *downloadUrlString;
@property NSString *downloadFileName;
@property ZADownloadModelPriroity priority;

@end

@implementation DownloadItem

- (instancetype) init {
    self = [super init];
    if (self) {
        _downloadFileName = [[NSString alloc] init];
        _downloadUrlString = [[NSString alloc] init];
    }
    return self;
}

@end

@interface ViewController ()<UITableViewDelegate,UITableViewDataSource>

@property (weak, nonatomic) IBOutlet UITableView *downloaderTableView;
@property NSMutableArray *downloadFiles;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];

    [self setup];
    [self loadData];
    
    // setup DownloadManager
    ZADownloadManager.sharedInstance.maxConcurrentDownloads = 1;        // maximum concurrent downloads.
}

- (void) setup {
    _downloadFiles = [[NSMutableArray alloc] init];
    _downloaderTableView.dataSource = self;
    _downloaderTableView.delegate = self;
}

- (void) loadData {
    DownloadItem *download1 = [[DownloadItem alloc] init];
    download1.downloadFileName = @"APPLE DOCS - BUSINESS 1";
    download1.downloadUrlString = urlString1;
    download1.priority = ZADownloadModelPriroityHigh;
    [_downloadFiles addObject:download1];
   
    DownloadItem *download11 = [[DownloadItem alloc] init];
    download11.downloadFileName = @"APPLE DOCS - BUSINESS 2";
    download11.downloadUrlString = urlString1;
    download11.priority = ZADownloadModelPriroityMedium;
    [_downloadFiles addObject:download11];
    
    DownloadItem *download111 = [[DownloadItem alloc] init];
    download111.downloadFileName = @"APPLE DOCS - BUSINESS 3";
    download111.downloadUrlString = urlString1;
    download111.priority = ZADownloadModelPriroityLow;
    [_downloadFiles addObject:download111];
    
    DownloadItem *download2 = [[DownloadItem alloc] init];
    download2.downloadFileName = @"VS CODE ZIP";
    download2.downloadUrlString = urlString2;
    download2.priority = ZADownloadModelPriroityMedium;
    [_downloadFiles addObject:download2];
    
    DownloadItem *download3 = [[DownloadItem alloc] init];
    download3.downloadFileName = @"Android Studio";
    download3.downloadUrlString = urlString3;
    download3.priority = ZADownloadModelPriroityLow;
    [_downloadFiles addObject:download3];
    
    DownloadItem *download4 = [[DownloadItem alloc] init];
    download4.downloadFileName = @"COC COC";
    download4.downloadUrlString = urlString4;
    download4.priority = ZADownloadModelPriroityHigh;
    [_downloadFiles addObject:download4];
    
    DownloadItem *download5 = [[DownloadItem alloc] init];
    download5.downloadFileName = @"SKYPE";
    download5.downloadUrlString = urlString5;
    download5.priority = ZADownloadModelPriroityMedium;
    [_downloadFiles addObject:download5];
    
    DownloadItem *download6 = [[DownloadItem alloc] init];
    download6.downloadFileName = @"CHROME";
    download6.downloadUrlString = urlString6;
    download6.priority = ZADownloadModelPriroityLow;
    [_downloadFiles addObject:download6];
}

// pragma mark - uitableview datasource
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    DowloaderTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"cellId" forIndexPath:indexPath];
    DownloadItem *downloadFile = _downloadFiles[indexPath.row];
    
    cell.fileName.text = [downloadFile downloadFileName];
    cell.urlLabel.text = [downloadFile downloadUrlString];
    cell.priority = downloadFile.priority;

    return cell;
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return _downloadFiles.count;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return 180;
}

@end
