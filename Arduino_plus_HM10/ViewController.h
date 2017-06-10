//
//  ViewController.h
//  Arduino_plus_HM10
//
//  Created by Мария Водолазкая on 10.06.17.
//  Copyright © 2017 Мария Водолазкая. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <CoreBluetooth/CoreBluetooth.h>

#define TIMER_PAUSE_INTERVAL 10.0
#define TIMER_SCAN_INTERVAL  2.0

#define SENSOR_TAG_NAME @"HMSoft"


@interface ViewController : UIViewController <CBCentralManagerDelegate, CBPeripheralDelegate>

@property (nonatomic, strong) CBCentralManager *centralManager;
@property (nonatomic, strong) CBPeripheral *sensorTag;

@property (weak, nonatomic) IBOutlet UILabel *tempLabel;
@property (weak, nonatomic) IBOutlet UILabel *LPGLabel;
@property (weak, nonatomic) IBOutlet UILabel *methaneLabel;
@property (weak, nonatomic) IBOutlet UILabel *smokeLabel;
@property (weak, nonatomic) IBOutlet UILabel *hydrogenLabel;
@property (weak, nonatomic) IBOutlet UILabel *stateLabel;


@end

