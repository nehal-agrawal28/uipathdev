public class RipReplaceSyncFactory_SL {
  private static Map<String, String> implementations = new Map<String, String>{
    'RipReplace_OppSync' => 'OppRipReplaceSyncQueueableSerial_SL',
    'RipReplace_QuoteSync' => 'QuoteRipReplaceSyncQueueableSerial_SL',
    'RipReplace_OrderSync' => 'OrderRipReplaceSyncQueueableSerial_SL'
  };

  public static IRipReplaceSync_SL getInstance(
    String syncType,
    List<Id> parentRecordIds,
    Id initiatingUserId,
    String initiatingUserTheme
  ) {
    IRipReplaceSync_SL syncInstance;
    if (implementations.containsKey(syncType)) {
      syncInstance = (IRipReplaceSync_SL) (Type.forName(implementations.get(syncType))).newInstance();
      syncInstance.init(parentRecordIds, initiatingUserId, initiatingUserTheme);
    } else {
      throw new RipReplaceSyncFactoryException('Implementation class for ' + syncType + ' is not registered');
    }
    return syncInstance;
  }

  public class RipReplaceSyncFactoryException extends Exception {
  }
}