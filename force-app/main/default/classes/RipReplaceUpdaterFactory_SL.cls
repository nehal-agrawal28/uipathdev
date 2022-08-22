public with sharing class RipReplaceUpdaterFactory_SL {
  private static Map<String, String> implementations = new Map<String, String>{
    'RipReplace_OppSync' => 'OppRipReplaceUpdateQueueableSerial_SL',
    'RipReplace_QuoteSync' => 'QuoteRipReplaceUpdateQueueableSerial_SL',
    'RipReplace_OrderSync' => 'OrderRipReplaceUpdateQueueableSerial_SL',
    'RipReplace_QuoteSyncOrdered' => 'QuoteRipReplaceUpdateQueueableOrdered_SL'
  };

  public static IRipReplaceUpdater_SL getInstance(
    String updaterType,
    Map<Id, Map<String, String>> recordIdToFieldUpdateMap,
    List<Id> childRecordIds,
    Id initiatingUserId,
    String initiatingUserTheme,
    List<String> retryJob
  ) {
    IRipReplaceUpdater_SL updaterInstance;
    if (implementations.containsKey(updaterType)) {
      updaterInstance = (IRipReplaceUpdater_SL) (Type.forName(implementations.get(updaterType))).newInstance();
      updaterInstance.init(recordIdToFieldUpdateMap, childRecordIds, initiatingUserId, initiatingUserTheme, retryJob);
    } else {
      throw new RipReplaceUpdaterFactoryException('Implementation class for ' + updaterType + ' is not registered');
    }
    return updaterInstance;
  }

  public static IRipReplaceUpdater_SL getInstance(
    String updaterType,
    Map<Id, Map<String, String>> recordIdToFieldUpdateMap,
    List<Id> childRecordIds,
    Id initiatingUserId,
    String initiatingUserTheme
  ) {
    return getInstance(
      updaterType,
      recordIdToFieldUpdateMap,
      childRecordIds,
      initiatingUserId,
      initiatingUserTheme,
      new List<String>()
    );
  }

  public class RipReplaceUpdaterFactoryException extends Exception {
  }
}