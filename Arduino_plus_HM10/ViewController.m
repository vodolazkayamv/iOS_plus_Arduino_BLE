//
//  ViewController.m
//  Arduino_plus_HM10
//
//  Created by Мария Водолазкая on 10.06.17.
//  Copyright © 2017 Мария Водолазкая. All rights reserved.
//

#import "ViewController.h"


@interface ViewController () 

@end

@implementation ViewController {
    BOOL keepScanning;
    int serialNum;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    self.tempLabel.font = [UIFont fontWithName:@"HelveticaNeue-Thin" size:56];
    self.LPGlabel.font = [UIFont fontWithName:@"HelveticaNeue-Thin" size:56];
    self.methaneLabel.font = [UIFont fontWithName:@"HelveticaNeue-Thin" size:56];
    self.smokeLabel.font = [UIFont fontWithName:@"HelveticaNeue-Thin" size:56];
    self.hydrogenLabel.font = [UIFont fontWithName:@"HelveticaNeue-Thin" size:56];
    
    serialNum = 0;
    
    [self startScan];
}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - UI methods

- (void) displayTemperature:(NSData *)dataBytes {
    NSString *str = [[NSString alloc] initWithData:dataBytes encoding:NSUTF8StringEncoding];
    NSLog(@"TEMPERATURE: %@ grad", str);
    
    self.tempLabel.text = str;
}

- (void) displayLPG:(NSData *)dataBytes {
    NSString *str = [[NSString alloc] initWithData:dataBytes encoding:NSUTF8StringEncoding];
    NSLog(@"LPG: %@ ppm", str);
    
    self.LPGlabel.text = str;
}

- (void) displayMethane:(NSData *)dataBytes {
    NSString *str = [[NSString alloc] initWithData:dataBytes encoding:NSUTF8StringEncoding];
    NSLog(@"Methane: %@ ppm", str);
    
    self.methaneLabel.text = str;
}

- (void) displaySmoke:(NSData *)dataBytes {
    NSString *str = [[NSString alloc] initWithData:dataBytes encoding:NSUTF8StringEncoding];
    NSLog(@"Smoke: %@ ppm", str);
    
    self.smokeLabel.text = str;
}

- (void) displayHydrogen:(NSData *)dataBytes {
    NSString *str = [[NSString alloc] initWithData:dataBytes encoding:NSUTF8StringEncoding];
    NSLog(@"Hydrogen: %@ ppm", str);
    
    self.hydrogenLabel.text = str;
    NSLog(@"-----------------------------");
}

#pragma mark - Helper Methods

-(void) startScan {
    // Create the CBCentralManager.
    // NOTE: Creating the CBCentralManager with initWithDelegate will immediately call centralManagerDidUpdateState.
    self.centralManager = [[CBCentralManager alloc] initWithDelegate:self queue:nil options:nil];
}

- (void)pauseScan {
    // Scanning uses up battery on phone, so pause the scan process for the designated interval.
    NSLog(@"*** PAUSING SCAN...");
    self.stateLabel.text = @"Paused scan";
    
    [NSTimer scheduledTimerWithTimeInterval:TIMER_PAUSE_INTERVAL target:self selector:@selector(resumeScan) userInfo:nil repeats:NO];
    [self.centralManager stopScan];
}

- (void)resumeScan {
    if (self->keepScanning) {
        // Start scanning again...
        NSLog(@"*** RESUMING SCAN!");
        self.stateLabel.text = @"Scanning";
        
        [NSTimer scheduledTimerWithTimeInterval:TIMER_SCAN_INTERVAL target:self selector:@selector(pauseScan) userInfo:nil repeats:NO];
        [self.centralManager scanForPeripheralsWithServices:nil options:nil];
    }
}

#pragma mark - Central Manager Delegate

- (void) centralManagerDidUpdateState:(nonnull CBCentralManager *)central {
    BOOL showAlert = YES;
    NSString *state = @"";
    switch ([central state])
    {
        case CBManagerStateUnsupported:
            state = @"This device does not support Bluetooth Low Energy.";
            break;
        case CBManagerStateUnauthorized:
            state = @"This app is not authorized to use Bluetooth Low Energy.";
            break;
        case CBManagerStatePoweredOff:
            state = @"Bluetooth on this device is currently powered off.";
            break;
        case CBManagerStateResetting:
            state = @"The BLE Manager is resetting; a state update is pending.";
            break;
        case CBManagerStatePoweredOn:
            showAlert = NO;
            state = @"Bluetooth LE is turned on and ready for communication.";
            NSLog(@"%@", state);
            self->keepScanning = YES;
            [NSTimer scheduledTimerWithTimeInterval:TIMER_SCAN_INTERVAL target:self selector:@selector(pauseScan) userInfo:nil repeats:NO];
            [self.centralManager scanForPeripheralsWithServices:nil options:nil];
            break;
        case CBManagerStateUnknown:
            state = @"The state of the BLE Manager is unknown.";
            break;
        default:
            state = @"The state of the BLE Manager is unknown.";
    }
    
    if (showAlert) {
        UIAlertController *ac = [UIAlertController alertControllerWithTitle:@"Central Manager State" message:state preferredStyle:UIAlertControllerStyleAlert];
        UIAlertAction *okAction = [UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleCancel handler:nil];
        [ac addAction:okAction];
        [self presentViewController:ac animated:YES completion:nil];
    }
}

- (void) centralManager:(CBCentralManager *)central didDiscoverPeripheral:(CBPeripheral *)peripheral advertisementData:(NSDictionary<NSString *,id> *)advertisementData RSSI:(NSNumber *)RSSI
{
    // Retrieve the peripheral name from the advertisement data using the "kCBAdvDataLocalName" key
    NSString *peripheralName = [advertisementData objectForKey:@"kCBAdvDataLocalName"];
    NSLog(@"NEXT PERIPHERAL: %@ (%@)", peripheralName, peripheral.identifier.UUIDString);
    if (peripheralName) {
        if ([peripheralName isEqualToString:SENSOR_TAG_NAME]) {
            self->keepScanning = NO;
            
            // save a reference to the sensor tag
            self.sensorTag = peripheral;
            self.sensorTag.delegate = self;
            
            // Request a connection to the peripheral
            [self.centralManager connectPeripheral:self.sensorTag options:nil];
        }
    }
}

- (void)centralManager:(CBCentralManager *)central didConnectPeripheral:(CBPeripheral *)peripheral {
    NSLog(@"**** SUCCESSFULLY CONNECTED TO %@!", SENSOR_TAG_NAME);
    self.stateLabel.text = @"Connected";
    
    // Now that we've successfully connected to the SensorTag, let's discover the services.
    // - NOTE:  we pass nil here to request ALL services be discovered.
    //          If there was a subset of services we were interested in, we could pass the UUIDs here.
    //          Doing so saves batter life and saves time.
    [peripheral discoverServices:nil];
}

- (void)centralManager:(CBCentralManager *)central didFailToConnectPeripheral:(CBPeripheral *)peripheral error:(NSError *)error {
    NSLog(@"**** CONNECTION FAILED!");
    self.stateLabel.text = @"Connection Failed";
    [self startScan];
}

- (void)centralManager:(CBCentralManager *)central didDisconnectPeripheral:(CBPeripheral *)peripheral error:(NSError *)error {
    NSLog(@"**** DISCONNECTED!");
    self.stateLabel.text = @"Disconnected";
    [self startScan];
}


#pragma mark - CBPeripheralDelegate methods

// When the specified services are discovered, the peripheral calls the peripheral:didDiscoverServices: method of its delegate object.
- (void)peripheral:(CBPeripheral *)peripheral didDiscoverServices:(NSError *)error {
    // Core Bluetooth creates an array of CBService objects —- one for each service that is discovered on the peripheral.
    for (CBService *service in peripheral.services) {
        NSLog(@"Discovered service: %@", service);
        [peripheral discoverCharacteristics:nil forService:service];
    }
}

- (void)peripheral:(CBPeripheral *)peripheral didDiscoverCharacteristicsForService:(CBService *)service error:(NSError *)error {
    for (CBCharacteristic *ch in service.characteristics) {
        [peripheral setNotifyValue:YES forCharacteristic:ch];
        
        NSData *dataBytes = ch.value;
        NSString *str = [[NSString alloc] initWithData:dataBytes encoding:NSUTF8StringEncoding];
        NSLog(@"Discovered Characteristic: UUID = %@, value = >%@<", ch.UUID, str);
    }
}

- (void)peripheral:(CBPeripheral *)peripheral didUpdateValueForCharacteristic:(CBCharacteristic *)characteristic error:(NSError *)error {
    if (error) {
        NSLog(@"Error changing notification state: %@", [error localizedDescription]);
    } else {
        // extract the data from the characteristic's value property and display the value based on the characteristic type
        NSData *dataBytes = characteristic.value;
        NSLog(@"Characteristic: %@", characteristic.UUID );
        
        switch (serialNum)
        {
            case 0:
                [self displayTemperature:dataBytes];
                serialNum++;
                break;
            case 1:
                [self displayLPG:dataBytes];
                serialNum++;
                break;
            case 2:
                [self displayMethane:dataBytes];
                serialNum++;
                break;
            case 3:
                [self displaySmoke:dataBytes];
                serialNum++;
                break;
            case 4:
                [self displayHydrogen:dataBytes];
                serialNum = 0;
                break;
            case 5:
                serialNum = 0;
                break;
            default:
                NSLog (@"serialNum out of range");
                break;
        }
    }
}

@end
