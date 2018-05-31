//
//  ViewController.m
//  蓝牙4.0Demo
//

#import "ViewController.h"
#import <CoreBluetooth/CoreBluetooth.h>

@interface ViewController ()<CBCentralManagerDelegate,CBPeripheralDelegate,UITextFieldDelegate>

/// 中央管理者 -->管理设备的扫描 --连接
@property (nonatomic, strong) CBCentralManager *centralManager;
// 存储的设备
@property (nonatomic, strong) NSMutableArray *peripherals;
// 扫描到的设备
@property (nonatomic, strong) CBPeripheral *cbPeripheral;
// 扫描到的特征
@property (nonatomic, strong) CBCharacteristic *cbCharacteristic;
// 用于读取温度的特征
@property (nonatomic, strong) CBCharacteristic *cbReadTempCharacteristic;
// 文本
@property (weak, nonatomic) IBOutlet UITextView *peripheralText;
// 蓝牙状态
@property (nonatomic, assign) CBManagerState peripheralState;
// 第一路继电器
@property (weak, nonatomic) IBOutlet UISwitch *firstSwitch;
// 第二路继电器
@property (weak, nonatomic) IBOutlet UISwitch *secondSwitch;
// 温度标签1
@property (weak, nonatomic) IBOutlet UILabel *firstTempLabel;
// 温度标签2
@property (weak, nonatomic) IBOutlet UILabel *secondTempLabel;
@property (strong, nonatomic) IBOutlet UITextField *temperature_hightextfield;
@property (strong, nonatomic) IBOutlet UITextField *temperture_lowfiled;
@property (strong, nonatomic) IBOutlet UITextField *temperture_police;
@property (strong, nonatomic) IBOutlet UILabel *temperture_first;
@property (strong, nonatomic) IBOutlet UILabel *temperture_second;
@property (strong, nonatomic) IBOutlet UILabel *state_first;
@property (strong, nonatomic) IBOutlet UILabel *state_second;


@end

// 蓝牙4.0设备名
static NSString * const kBlePeripheralName = @"temp01";
// 通知服务
static NSString * const kNotifyServerUUID = @"FFE0";
// 写服务
static NSString * const kWriteServerUUID = @"1000";
// 通知特征值
static NSString * const kNotifyCharacteristicUUID = @"FFE2";
// 写特征值
static NSString * const kWriteCharacteristicUUID = @"1001";
//读特征值
static NSString * const kReadCharacteristicUUID = @"1002";

@implementation ViewController
- (NSMutableArray *)peripherals
{
    if (!_peripherals) {
        _peripherals = [NSMutableArray array];
    }
    return _peripherals;
}

- (CBCentralManager *)centralManager
{
    if (!_centralManager)
    {
        _centralManager = [[CBCentralManager alloc] initWithDelegate:self queue:nil];
    
    }
    return _centralManager;
}

// 扫描设备
- (IBAction)scanForPeripherals
{
    [self.centralManager stopScan];
    NSLog(@"扫描设备");
    [self showMessage:@"扫描设备"];
    if (self.peripheralState ==  CBManagerStatePoweredOn)
    {
        [self.centralManager scanForPeripheralsWithServices:nil options:nil];
    }
}

// 连接设备
- (IBAction)connectToPeripheral
{
    if (self.cbPeripheral != nil)
    {
        [self showMessage:@"连接设备"];
        [self.centralManager connectPeripheral:self.cbPeripheral options:nil];
    }
    else
    {
        [self showMessage:@"无设备可连接"];
    }
}

// 清空设备
- (IBAction)clearPeripherals
{
    [self.peripherals removeAllObjects];
    self.peripheralText.text = @"";
    
    if (self.cbPeripheral != nil)
    {
        // 取消连接
        [self showMessage:@"断开连接..."];
        [self.centralManager cancelPeripheralConnection:self.cbPeripheral];
        
        self.cbPeripheral = nil;
    }
}
- (IBAction)writeData:(id)sender {
    
    if (self.cbPeripheral) {
        // 写入数据
        [self showMessage:@"写入特征值"];
        Byte first = 0;
        Byte second = 0;
        first = self.firstSwitch.on ? 1 : 0;
        second = self.secondSwitch.on ? 1 : 0;
        
        Byte spFirst = 0x10 | first;
        Byte spSecond = 0x20 | second;
        int high;
        if(self.temperature_hightextfield.text.length)
        high = [self.temperature_hightextfield.text floatValue]*10;
        else
        high = 291;
        
        unsigned long red
        = strtoul([[self getHexByDecimal:high] UTF8String],0,16);
        unsigned char lo4,hi4;
        hi4 = red>> 8;
        lo4 = red & 0xff;
        
        int low;
        if(self.temperture_lowfiled.text.length)
        {
           low = [self.temperture_lowfiled.text floatValue]*10;
        }
        else
        low = 291;
        
        unsigned long red1
        = strtoul([[self getHexByDecimal:low] UTF8String],0,16);
        unsigned char lo5,hi5;
        hi5 = red1>> 8;
        lo5 = red1 & 0xff;
        
        
        
        Byte byte[] = {0xBE, 0x01, spFirst, spSecond, hi4,lo4,hi5,lo5, 0x88, 0xEB};
        NSString *str = [NSString stringWithFormat:@"%02X %02X %02X %02X %02X %02X %02X %02X %02X %02X", byte[0], byte[1], byte[2], byte[3], byte[4], byte[5], byte[6], byte[7], byte[8], byte[9]];
        [self showMessage:str];
        NSData *data = [NSData dataWithBytes:byte length:10];
        if (!self.cbCharacteristic) {
            [self showMessage:@"无法写入设备"];
        } else {
            [self.cbPeripheral writeValue:data forCharacteristic:self.cbCharacteristic type:CBCharacteristicWriteWithResponse];
        }
    } else {
        [self showMessage:@"没有连接到设备"];
    }
}
- (IBAction)betweenHighlow:(id)sender {
    
    if (self.temperature_hightextfield.text.length&&self.temperture_lowfiled.text.length) {
        // 写入数据
        [self showMessage:@"写入特征值"];
        Byte first = 0;
        Byte second = 0;
        first = self.firstSwitch.on ? 1 : 0;
        second = self.secondSwitch.on ? 1 : 0;
        
        int high = [self.temperature_hightextfield.text floatValue]*10;
        unsigned long red
        = strtoul([[self getHexByDecimal:high] UTF8String],0,16);
        unsigned char lo4,hi4;
        hi4 = red>> 8;
        lo4 = red & 0xff;
        
        int low = [self.temperture_lowfiled.text floatValue]*10;
        unsigned long red1
        = strtoul([[self getHexByDecimal:low] UTF8String],0,16);
        unsigned char lo5,hi5;
        hi5 = red1>> 8;
        lo5 = red1 & 0xff;
//
        Byte byte[] = {0xBE, 0x02, hi4, lo4, hi5,lo5,0x01, 0x23, 0x88, 0xEB};
        NSString *str = [NSString stringWithFormat:@"%02X %02X %02X %02X %02X %02X %02X %02X %02X %02X", byte[0], byte[1], byte[2], byte[3], byte[4], byte[5], byte[6], byte[7], byte[8], byte[9]];
        [self showMessage:str];
        NSData *data = [NSData dataWithBytes:byte length:10];
        if (!self.cbCharacteristic) {
            [self showMessage:@"无法写入设备"];
        } else {
            [self.cbPeripheral writeValue:data forCharacteristic:self.cbCharacteristic type:CBCharacteristicWriteWithResponse];
        }
    } else {
        [self showMessage:@"没有连接到设备"];
    }
}


- (IBAction)highestemperature:(id)sender {
    
    if (self.temperture_police.text.length) {
        // 写入数据
        [self showMessage:@"写入特征值"];
        Byte first = 0;
        Byte second = 0;
        first = self.firstSwitch.on ? 1 : 0;
        second = self.secondSwitch.on ? 1 : 0;
        
        int high = [self.temperture_police.text floatValue]*10;
        unsigned long red
        = strtoul([[self getHexByDecimal:high] UTF8String],0,16);
        unsigned char lo4,hi4;
        hi4 = red>> 8;
        lo4 = red & 0xff;
        
        int low = [self.temperture_police.text floatValue]*10;
        unsigned long red1
        = strtoul([[self getHexByDecimal:low] UTF8String],0,16);
        unsigned char lo5,hi5;
        hi5 = red1>> 8;
        lo5 = red1 & 0xff;
        //
        Byte byte[] = {0xBE, 0x03, hi4, lo4, hi5,lo5,0x01, 0x23, 0x88, 0xEB};
        NSString *str = [NSString stringWithFormat:@"%02X %02X %02X %02X %02X %02X %02X %02X %02X %02X", byte[0], byte[1], byte[2], byte[3], byte[4], byte[5], byte[6], byte[7], byte[8], byte[9]];
        [self showMessage:str];
        NSData *data = [NSData dataWithBytes:byte length:10];
        if (!self.cbCharacteristic) {
            [self showMessage:@"无法写入设备"];
        }
        else
        {
            [self.cbPeripheral writeValue:data forCharacteristic:self.cbCharacteristic type:CBCharacteristicWriteWithResponse];
        }
    }
    else
    {
        [self showMessage:@"没有连接到设备"];
    }

}


- (IBAction)writeTempData:(id)sender {
    [self showMessage:@"写入温度值"];
    
//    Byte byte[] = {0xBE, 0x01, spFirst, spSecond, 0x44,0x55, 0x66, 0x77, 0x88, 0xEB};
//    NSString *str = [NSString stringWithFormat:@"%02X %02X %02X %02X %02X %02X %02X %02X %02X %02X", byte[0], byte[1], byte[2], byte[3], byte[4], byte[5], byte[6], byte[7], byte[8], byte[9]];
//    [self showMessage:str];
//    NSData *data = [NSData dataWithBytes:byte length:10];
//    if (!self.cbCharacteristic) {
//        [self showMessage:@"无法写入设备"];
//    } else {
//        [self.cbPeripheral writeValue:data forCharacteristic:self.cbCharacteristic type:CBCharacteristicWriteWithResponse];
//    }
}

- (IBAction)readTempData:(id)sender {
    [self showMessage:@"读取温度值"];
    if (self.cbPeripheral) {
        self.temperture_first.hidden = NO;
        self.temperture_second.hidden = NO;
        [self.cbPeripheral setNotifyValue:YES forCharacteristic:self.cbReadTempCharacteristic];
//        [self.cbPeripheral discoverDescriptorsForCharacteristic:characteristic];
    }
}
- (IBAction)stopReadTempData:(id)sender {
    [self showMessage:@"停止读取温度值"];
    if (self.cbPeripheral) {
        self.temperture_first.hidden = YES;
        self.temperture_second.hidden = YES;
        [self.cbPeripheral setNotifyValue:NO forCharacteristic:self.cbReadTempCharacteristic];
    }
}

- (void)viewDidLoad {

    self.temperature_hightextfield.delegate = self;
    self.temperture_lowfiled.delegate = self;
    self.temperture_police.delegate = self;
   
    self.temperture_first.hidden = YES;
    self.temperture_second.hidden = YES;
    
    _firstSwitch.transform = CGAffineTransformMakeScale(0.75, 0.75);
    _secondSwitch.transform = CGAffineTransformMakeScale(0.75, 0.75);
    [super viewDidLoad];
    [self centralManager];
}
// 状态更新时调用
- (void)centralManagerDidUpdateState:(CBCentralManager *)central
{
    switch (central.state) {
        case CBManagerStateUnknown:{
            NSLog(@"为知状态");
            self.peripheralState = central.state;
        }
            break;
        case CBManagerStateResetting:
        {
            NSLog(@"重置状态");
            self.peripheralState = central.state;
        }
            break;
        case CBManagerStateUnsupported:
        {
            NSLog(@"不支持的状态");
            self.peripheralState = central.state;
        }
            break;
        case CBManagerStateUnauthorized:
        {
            NSLog(@"未授权的状态");
            self.peripheralState = central.state;
        }
            break;
        case CBManagerStatePoweredOff:
        {
            NSLog(@"关闭状态");
            self.peripheralState = central.state;
            
        }
            break;
        case CBManagerStatePoweredOn:
        {
            NSLog(@"开启状态－可用状态");
            self.peripheralState = central.state;
//            NSLog(@"%ld",(long)self.peripheralState);
        }
            break;
        default:
            break;
    }
}
/**
 扫描到设备
 
 @param central 中心管理者
 @param peripheral 扫描到的设备
 @param advertisementData 广告信息
 @param RSSI 信号强度
 */
- (void)centralManager:(CBCentralManager *)central didDiscoverPeripheral:(CBPeripheral *)peripheral advertisementData:(NSDictionary<NSString *,id> *)advertisementData RSSI:(NSNumber *)RSSI
{
    if ([peripheral.name isEqualToString:kBlePeripheralName]) {
        [self showMessage:[NSString stringWithFormat:@"发现护理毯设备,设备名:%@",peripheral.name]];
        if (![self.peripherals containsObject:peripheral])
        {
            [self.peripherals addObject:peripheral];
            self.cbPeripheral = peripheral;
            [self showMessage:@"准备就绪"];
//            [self.centralManager connectPeripheral:peripheral options:nil];
        }
    }
}

/**
 连接失败
 
 @param central 中心管理者
 @param peripheral 连接失败的设备
 @param error 错误信息
 */

- (void)centralManager:(CBCentralManager *)central didFailToConnectPeripheral:(CBPeripheral *)peripheral error:(NSError *)error
{
    [self showMessage:@"连接失败"];
    if ([peripheral.name isEqualToString:kBlePeripheralName])
    {
        [self.centralManager connectPeripheral:peripheral options:nil];
    }
}

/**
 连接断开
 
 @param central 中心管理者
 @param peripheral 连接断开的设备
 @param error 错误信息
 */

- (void)centralManager:(CBCentralManager *)central didDisconnectPeripheral:(CBPeripheral *)peripheral error:(NSError *)error
{
    [self showMessage:@"断开连接成功！"];
    self.temperture_first.text = [[NSString alloc]initWithFormat:@""];
    self.temperture_second.text = [[NSString alloc]initWithFormat:@""];
    [_state_first setText:@"关"];
    [_state_second setText:@"关"];
//    if ([peripheral.name isEqualToString:kBlePeripheralName])
//    {
//        [self.centralManager connectPeripheral:peripheral options:nil];
//    }
}

/**
 连接成功
 
 @param central 中心管理者
 @param peripheral 连接成功的设备
 */
- (void)centralManager:(CBCentralManager *)central didConnectPeripheral:(CBPeripheral *)peripheral
{
    NSLog(@"连接设备:%@成功",peripheral.name);
    
    [self showMessage:[NSString stringWithFormat:@"连接设备:%@成功",peripheral.name]];
    // 设置设备的代理
    peripheral.delegate = self;
    // services:传入nil  代表扫描所有服务
    [peripheral discoverServices:nil];
}

/**
 扫描到服务
 
 @param peripheral 服务对应的设备
 @param error 扫描错误信息
 */
- (void)peripheral:(CBPeripheral *)peripheral didDiscoverServices:(NSError *)error
{
    // 遍历所有的服务
    for (CBService *service in peripheral.services)
    {
        NSLog(@"服务:%@",service.UUID.UUIDString);
        // 获取对应的服务
        if ([service.UUID.UUIDString isEqualToString:kWriteServerUUID])
        {
            // 根据服务去扫描特征
            [peripheral discoverCharacteristics:nil forService:service];
        }
    }
}

/**
 扫描到对应的特征
 
 @param peripheral 设备
 @param service 特征对应的服务
 @param error 错误信息
 */
- (void)peripheral:(CBPeripheral *)peripheral didDiscoverCharacteristicsForService:(CBService *)service error:(NSError *)error
{
    // 遍历所有的特征
    for (CBCharacteristic *characteristic in service.characteristics)
    {
//        NSLog(@"特征值:%@",characteristic.UUID.UUIDString);
        if ([characteristic.UUID.UUIDString isEqualToString:kWriteCharacteristicUUID]) {
            self.cbCharacteristic = characteristic;
        }
        if ([characteristic.UUID.UUIDString isEqualToString:kReadCharacteristicUUID]) {
            self.cbReadTempCharacteristic = characteristic;
        }
    }
}

/**
 根据特征读到数据
 
 @param peripheral 读取到数据对应的设备
 @param characteristic 特征
 @param error 错误信息
 */
- (void)peripheral:(CBPeripheral *)peripheral didUpdateValueForCharacteristic:(nonnull CBCharacteristic *)characteristic error:(nullable NSError *)error
{
    if ([characteristic.UUID.UUIDString isEqualToString:kReadCharacteristicUUID])
    {
        NSData *data = characteristic.value;
        Byte *byte = (Byte *)[data bytes];
        //解析数据
        if (data.length == 8) {
            NSString *str = [NSString stringWithFormat:@"%02X %02X %02X %02X %02X %02X %02X %02X", byte[0], byte[1], byte[2], byte[3], byte[4], byte[5], byte[6], byte[7]];
            [self showMessage:str];
            
            Byte firstTemp = byte[2];
            Byte secondTemp = byte[4];
            
            Byte firstState = byte[5];
            Byte secondState = byte[6];
            
            Byte isFirstOpen = firstState & 0x01;
            Byte isSecondOpen = secondState & 0x01;
            
            self.firstTempLabel.text = [NSString stringWithFormat:@"第一路温度：%.1f℃ 开关状态：%@", (float)firstTemp/10, (isFirstOpen? @"闭合" : @"断开")];
            self.secondTempLabel.text = [NSString stringWithFormat:@"第二路温度：%.1f℃ 开关状态：%@", (float)secondTemp/10, (isSecondOpen? @"闭合" : @"断开")];
        } else {
            [self showMessage:[NSString stringWithFormat:@"%@", data]];
        }
    }
}

- (void)showMessage:(NSString *)message
{
    
    
//     NSLog(@"%@",[self numberHexString:@"00e5"]);
    
    if (message.length >20 ) {
        NSString *str1 = [message substringWithRange:NSMakeRange(3,4)];
        
        self.temperture_first.text = [[NSString alloc]initWithFormat:@"%.1lf℃",[[self numberHexString:str1] integerValue]/10.0];
        
        NSString *str2 = [message substringWithRange:NSMakeRange(7,5)];
        //删除字符串中的空格
        NSString *str3 = [str2 stringByReplacingOccurrencesOfString:@" " withString:@""];
        self.temperture_second.text = [[NSString alloc]initWithFormat:@"%.1lf℃",[[self numberHexString:str3] integerValue]/10.0];
        
        NSString *state1 = [message substringWithRange:NSMakeRange(12,2)];
        NSString *state2 = [message substringWithRange:NSMakeRange(14,2)];
        if ([state1 isEqualToString:@"11"]) {
            [_state_first setText:@"开"];
        }
        else
        {
            [_state_first setText:@"关"];
        }
        if ([state2 isEqualToString:@"21"]) {
            [_state_second setText:@"开"];
        }
        else
        {
            [_state_second setText:@"关"];
        }
    }
    else
    {
        self.temperture_first.text = [[NSString alloc]initWithFormat:@"0.0℃"];
        self.temperture_second.text = [[NSString alloc]initWithFormat:@"0.0℃"];
    }
    
    
    
    self.peripheralText.text = [self.peripheralText.text stringByAppendingFormat:@"%@\n",message];
    [self.peripheralText scrollRectToVisible:CGRectMake(0, self.peripheralText.contentSize.height -15, self.peripheralText.contentSize.width, 10) animated:YES];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}
- (NSString *)getHexByDecimal:(NSInteger)decimal {
    
    NSString *hex =@"";
    NSString *letter;
    NSInteger number;
    for (int i = 0; i<9; i++) {
        
        number = decimal % 16;
        decimal = decimal / 16;
        switch (number) {
                
            case 10:
                letter =@"A"; break;
            case 11:
                letter =@"B"; break;
            case 12:
                letter =@"C"; break;
            case 13:
                letter =@"D"; break;
            case 14:
                letter =@"E"; break;
            case 15:
                letter =@"F"; break;
            default:
                letter = [NSString stringWithFormat:@"%ld", number];
        }
        hex = [letter stringByAppendingString:hex];
        if (decimal == 0) {
            
            break;
        }
    }
    return hex;
}

// 16进制转10进制
- (NSNumber *) numberHexString:(NSString *)aHexString
{
    // 为空,直接返回.
    if (nil == aHexString)
    {
        return nil;
    }
    
    NSScanner * scanner = [NSScanner scannerWithString:aHexString];
    unsigned long long longlongValue;
    [scanner scanHexLongLong:&longlongValue];
    
    //将整数转换为NSNumber,存储到数组中,并返回.
    NSNumber * hexNumber = [NSNumber numberWithLongLong:longlongValue];
    
    return hexNumber;
    
}

//补位
- (NSString *)supplement:(NSString *)string
{
    if (string.length == 1) {
        string = [[NSString alloc]initWithFormat:@"000%@",string];
    }
    else if (string.length == 2) {
        string = [[NSString alloc]initWithFormat:@"00%@",string];
    }
    else if (string.length == 3) {
        string = [[NSString alloc]initWithFormat:@"0%@",string];
    }
    return string;
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField
{
    
    [textField resignFirstResponder];
    return YES;
}

- (BOOL)textView:(UITextView *)textView shouldChangeTextInRange:(NSRange)range replacementText:(NSString*)text
{
    if ([text isEqualToString:@"\n"]) {
        [textView resignFirstResponder];
        return NO;
    }
    return YES;
}


@end
