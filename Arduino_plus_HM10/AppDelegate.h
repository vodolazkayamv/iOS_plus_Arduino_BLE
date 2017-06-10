//
//  AppDelegate.h
//  Arduino_plus_HM10
//
//  Created by Мария Водолазкая on 10.06.17.
//  Copyright © 2017 Мария Водолазкая. All rights reserved.
//
// <a href="https://ru.icons8.com/icon/11670/Arduino-Filled">Arduino filled иконка в оригинале</a>

#import <UIKit/UIKit.h>
#import <CoreData/CoreData.h>

@interface AppDelegate : UIResponder <UIApplicationDelegate>

@property (strong, nonatomic) UIWindow *window;

@property (readonly, strong) NSPersistentContainer *persistentContainer;

- (void)saveContext;


@end

