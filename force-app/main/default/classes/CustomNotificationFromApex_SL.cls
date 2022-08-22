public without sharing class CustomNotificationFromApex_SL {
  public static String notifyUsers(Set<String> recipientsIds, String targetId, String type, String title, String body) {
    // Get the Id for our custom notification type
    CustomNotificationType notificationType = [
      SELECT Id, DeveloperName
      FROM CustomNotificationType
      WHERE DeveloperName = :type
    ];

    // Create a new custom notification
    Messaging.CustomNotification notification = new Messaging.CustomNotification();

    // Set the contents for the notification
    notification.setTitle(title);
    notification.setBody(body);

    // Set the notification type + target
    notification.setNotificationTypeId(notificationType.Id);
    notification.setTargetId(targetId);

    // Actually send the notification
    String result = 'Success';
    try {
      if (!Test.isRunningTest()) {
        notification.send(recipientsIds);
      }
    } catch (Exception e) {
      result = 'Error';
      System.debug(LoggingLevel.ERROR, 'Problem sending custom notification: ' + e.getMessage());
    }
    return result;
  }
}