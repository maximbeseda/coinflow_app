import '../models/subscription_model.dart';
import 'storage_service.dart';

class SubscriptionService {
  // Винесли сюди складну логіку перенесення дати
  static Future<void> shiftSubscriptionDate(Subscription sub) async {
    DateTime now = DateTime.now();
    DateTime today = DateTime(now.year, now.month, now.day); // 00:00:00

    DateTime nextDate = DateTime(
      sub.nextPaymentDate.year,
      sub.nextPaymentDate.month,
      sub.nextPaymentDate.day,
    );

    while (nextDate.isBefore(today) || nextDate.isAtSameMomentAs(today)) {
      if (sub.periodicity == 'monthly') {
        int nextMonth = nextDate.month == 12 ? 1 : nextDate.month + 1;
        int nextYear = nextDate.month == 12 ? nextDate.year + 1 : nextDate.year;

        int nextDay = sub.nextPaymentDate.day;
        final lastDayOfNextMonth = DateTime(nextYear, nextMonth + 1, 0).day;
        if (nextDay > lastDayOfNextMonth) nextDay = lastDayOfNextMonth;

        nextDate = DateTime(nextYear, nextMonth, nextDay);
      } else if (sub.periodicity == 'yearly') {
        nextDate = DateTime(nextDate.year + 1, nextDate.month, nextDate.day);
      } else if (sub.periodicity == 'weekly') {
        nextDate = nextDate.add(const Duration(days: 7));
      }
    }

    sub.nextPaymentDate = nextDate;
    await StorageService.saveSubscription(sub);
  }
}
