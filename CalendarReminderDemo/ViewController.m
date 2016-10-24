//
//  ViewController.m
//  CalendarReminderDemo


#import "ViewController.h"
#import <EventKit/EventKit.h>

@interface ViewController() {
    EKEventStore *eventStore;
}
@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];

    UIButton *btn = [UIButton buttonWithType:UIButtonTypeCustom];
    btn.frame = CGRectMake(100, 100, 150, 60);
    btn.center = self.view.center;
    btn.backgroundColor = [UIColor grayColor];
    [btn setTitle:@"提醒" forState:UIControlStateNormal];
    [btn addTarget:self action:@selector(btnAction:) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:btn];

    eventStore = [[EKEventStore alloc] init];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

- (void)saveEventStartDate:(NSDate *)startDate
                   endDate:(NSDate *)endDate
                     alarm:(float)alarm
                eventTitle:(NSString *)eventTitle
                  location:(NSString *)location
                isReminder:(BOOL)isReminder {

    NSLog(@"处理事件");

    if ([eventStore respondsToSelector:@selector(requestAccessToEntityType:completion:)]) {
        __weak typeof(self) WeakSelf = self;

        [eventStore
        requestAccessToEntityType:EKEntityTypeEvent
                       completion:^(BOOL granted, NSError *error) {
                           dispatch_async(dispatch_get_main_queue(), ^{
                               if (error) {
                                   NSLog(@"%@", error.localizedDescription);
                               } else if (!granted) {

                                   NSLog(@"用户不允许访问日历");
                               } else {
                                   if (startDate && endDate) { // 删除之前插入的
                                       [WeakSelf deleteInsertedEvent];

                                       NSPredicate *predicate =
                                       [eventStore predicateForEventsWithStartDate:startDate endDate:endDate calendars:nil];
                                       if (predicate) {

                                           NSArray *eventsArray = [eventStore eventsMatchingPredicate:predicate];
                                           if (eventsArray.count) {
                                               for (EKEvent *item in eventsArray) {
                                                   NSLog(@"%@", item.title);
                                                   if ([item.title isEqualToString:eventTitle]) {
                                                       NSLog(@"已经存在ID一样的事件");
                                                       return;
                                                   }
                                               }
                                           }
                                       }

                                       EKEvent *event = [EKEvent eventWithEventStore:eventStore];
                                       event.title = eventTitle;

                                       event.location = location;
                                       event.allDay = NO;
                                       event.startDate = startDate;
                                       event.endDate = endDate;

                                       event.URL = [NSURL URLWithString:@"https://www.baidu.com"];

                                       [event addAlarm:[EKAlarm alarmWithRelativeOffset:1]];
                                       event.calendar = [eventStore defaultCalendarForNewEvents];
                                       NSError *error;
                                       [eventStore saveEvent:event span:EKSpanThisEvent error:&error];

                                       if (isReminder) {
                                           EKCalendar *iDefaultCalendar = [eventStore defaultCalendarForNewReminders];
                                           //
                                           EKReminder *reminder = [EKReminder reminderWithEventStore:eventStore];
                                           reminder.title = eventTitle;
                                           reminder.calendar = iDefaultCalendar;
                                           EKAlarm *alarm = [EKAlarm alarmWithAbsoluteDate:[NSDate dateWithTimeIntervalSinceNow:-10]];
                                           [reminder addAlarm:alarm];

                                           NSError *error = nil;
                                           [eventStore saveReminder:reminder commit:YES error:&error];
                                           if (error) {
                                               NSLog(@"error=%@", error.localizedDescription);
                                           }
                                       }
                                   }
                               }
                           });
                       }];
    }
}

- (void)btnAction:(UIButton *)sender {
    NSDate *startDate = [NSDate dateWithTimeIntervalSinceNow:1];
    NSDate *endDate = [NSDate dateWithTimeIntervalSinceNow:300];
    [self saveEventStartDate:startDate
                     endDate:endDate
                       alarm:-5
                  eventTitle:@"6元优惠券即将到期"
                    location:@"尊"
                             @"敬"
                             @"的用户，您有一张6元优惠券即将到期！（详情以优惠券中心实际展示为准）"
                  isReminder:NO];
}

//! 删除之前插入的事件
- (void)deleteInsertedEvent {
    BOOL isClear = [[NSUserDefaults standardUserDefaults] boolForKey:@"CLEAR"];
    if (!isClear) {
        NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
        formatter.dateFormat = @"yyyyMMddHHmmss";
        NSDate *startDate = [formatter dateFromString:@"20160101000000"];
        NSDate *endDate = [formatter dateFromString:@"20161231235959"];
        NSPredicate *predicate = [eventStore predicateForEventsWithStartDate:startDate endDate:endDate calendars:nil];

        NSArray *eventsArray = [eventStore eventsMatchingPredicate:predicate];
        if (eventsArray.count) {
            for (EKEvent *item in eventsArray) {
                NSLog(@"<删除方法事件信息：>%@",item.title);
                NSRange range = [item.title rangeOfString:@"即将到期"];
                if (range.location != NSNotFound) {

                    NSLog(@" 删除老版本插入的提醒----删除成功");
                    [eventStore removeEvent:item span:EKSpanThisEvent commit:YES error:nil];
                }
            }
            [[NSUserDefaults standardUserDefaults] setBool:YES forKey:@"CLEAR"];
        }
    }
}

@end
