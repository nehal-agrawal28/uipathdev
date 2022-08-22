/**
 * File Name: GenericNotificationsController_PP
 * Description:
 *
 * @author : architect ir. Wilhelmus G.J. Velzeboer
 */
public without sharing class GenericNotificationsController_PP {
  private static Id userAccountId {
    get {
      if (userAccountId == null) {
        User currentUser = [SELECT Id, AccountId FROM User WHERE Id = :UserInfo.getUserId() LIMIT 1];
        if (currentUser.AccountId == null)
          throw new GenericNotificationsControllerException('User not linked to an Account');

        userAccountId = currentUser.AccountId;
      }
      return userAccountId;
    }
    private set;
  }

  @AuraEnabled
  public static void deleteNotifications(List<Id> notificationIds) {
    try {
      GenericNotifications_PP notifications = GenericNotifications_PP.newInstance(new Set<Id>(notificationIds));

      fflib_ISObjectUnitOfWork unitOfWork = Application.UnitOfWork.newInstance(
        new List<SObjectType>{ GenericNotification_PP__c.SObjectType },
        new ElevatedDML()
      );

      unitOfWork.registerDeleted(
        // make sure we only select records from the current user
        notifications.selectByAccountId(userAccountId).getRecords()
      );
      unitOfWork.commitWork();
    } catch (Exception e) {
      AuraHandledException auraHandledException = new AuraHandledException(e.getMessage());
      auraHandledException.setMessage(e.getMessage());
      throw auraHandledException;
    }
  }

  @AuraEnabled(Cacheable=true)
  public static List<GenericNotification_PP__c> getNotifications() {
    return GenericNotificationsSelector_PP.newInstance().selectByAccountId(new Set<Id>{ userAccountId });
  }

  @AuraEnabled
  public static void saveNotification(String notificationId, String email, String type) {
    try {
      GenericNotifications_PP notifications;
      if (String.isBlank(notificationId)) {
        notifications = generateNewNotifications();
      } else {
        notifications = GenericNotifications_PP.newInstance(new Set<Id>{ notificationId });
      }

      fflib_ISObjectUnitOfWork unitOfWork = Application.UnitOfWork.newInstance(
        new List<SObjectType>{ GenericNotification_PP__c.SObjectType },
        new ElevatedDML()
      );
      unitOfWork.registerUpsert(
        notifications
          .setAccountId(userAccountId) // for max security
          .setEmail(String.escapeSingleQuotes(email))
          .setType(String.escapeSingleQuotes(type))
          .getRecords()
      );
      unitOfWork.commitWork();
    } catch (Exception e) {
      AuraHandledException auraHandledException = new AuraHandledException(e.getMessage());
      auraHandledException.setMessage(e.getMessage());
      throw auraHandledException;
    }
  }

  private static GenericNotifications_PP generateNewNotifications() {
    return GenericNotifications_PP.newInstance(
      new List<GenericNotification_PP__c>{ new GenericNotification_PP__c(Account__c = userAccountId) }
    );
  }

  private without sharing class ElevatedDML implements fflib_SObjectUnitOfWork.IDML {
    public void dmlInsert(List<SObject> objList) {
      insert objList;
    }
    public void dmlUpdate(List<SObject> objList) {
      update objList;
    }
    public void dmlDelete(List<SObject> objList) {
      delete objList;
    }
    public void eventPublish(List<SObject> objList) {
      EventBus.publish(objList);
    }
    public void emptyRecycleBin(List<SObject> objList) {
      if (objList.isEmpty())
        return;

      Database.emptyRecycleBin(objList);
    }
  }

  private class GenericNotificationsControllerException extends Exception {
  }
}