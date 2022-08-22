public with sharing class QuoteSendPSEmailQueueable_SL extends AbstractQueueable {
  private final List<SObject> records;
  private final String PS_EDIT_EMAIL_TEMPLATE_NAME = 'PS_License_Deal_Edited';
  private final String PS_BOOKED_EMAIL_TEMPLATE_NAME = 'PS_License_Deal_Booked';
  private final String PS_EDIT_EMAIL_GROUP = 'Services AutoAttach Review';
  private final String PS_Booked_EMAIL_GROUP = 'Services Booked Deal Review';
  private String type;

  public QuoteSendPSEmailQueueable_SL(List<SObject> records, String type) {
    super('QuoteSendPSEmailQueueable_SL');
    this.records = records;
    this.type = type;
    //to allow for logging against record. only used in non-bulk contexts
    if (records != null && records.size() == 1) {
      this.setPrimaryRecordId(records.get(0).Id);
    }
  }
  public override void work() {
    if (type == 'Deal_Edited') {
      this.sendPSDealEmail(records, PS_EDIT_EMAIL_TEMPLATE_NAME, PS_EDIT_EMAIL_GROUP);
    } else if (type == 'Deal_Booked') {
      this.sendPSDealEmail(records, PS_BOOKED_EMAIL_TEMPLATE_NAME, PS_Booked_EMAIL_GROUP);
    }
  }

  private void sendPSDealEmail(List<SBQQ__Quote__c> records, String templateName, String groupName) {
    EmailTemplate template = [SELECT Id, DeveloperName, Name FROM EmailTemplate WHERE DeveloperName = :templateName];
    List<Messaging.SingleEmailMessage> emails = new List<Messaging.SingleEmailMessage>();
    List<Id> userIds = getGroupUsers(groupName);

    for (SBQQ__Quote__c quote : records) {
      for (Id uId : userIds) {
        Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
        mail.setTemplateId(template.Id);
        mail.setTargetObjectId(uId);
        mail.setWhatId(quote.Id);
        mail.saveAsActivity = false;
        emails.add(mail);
      }
    }

    if (emails.size() > 0) {
      Messaging.sendEmail(emails);
    }
  }

  private List<Id> getGroupUsers(String groupName) {
    List<Id> userIds = new List<String>();
    String userType = Schema.SObjectType.User.getKeyPrefix();
    Group g = [SELECT Id, (SELECT userOrGroupId FROM GroupMembers) FROM Group WHERE Name = :groupName];
    for (GroupMember gm : g.groupMembers) {
      if (((String) gm.UserOrGroupId).startsWith(userType)) {
        userIds.add(gm.UserOrGroupId);
      }
    }
    return userIds;
  }

  /**
   * @description : Send email to PS user's group when a Deal with PS and License was edited
   * @param  records         records description
   * @param  existingRecords existingRecords description
   */
  public static void autoAttachPSDealEditedEmail(List<SObject> records, Map<Id, SObject> existingRecords) {
    SObjectPredicate hasChanged = new HasRecordChanged(
      new Set<SObjectField>{ SBQQ__Quote__c.Total_Professional_Service__c },
      records,
      existingRecords
    );

    List<SBQQ__Quote__c> eligibleRecords = Collection.of(records)
      .filter(
        Match.field(SBQQ__Quote__c.Total_UiPath_Licenses__c)
          .greaterThan(0)
          .also(SBQQ__Quote__c.Total_Professional_Service__c)
          .greaterThan(0)
      )
      .filter(hasChanged)
      .asList();

    if (!eligibleRecords.isEmpty()) {
      AbstractQueueable.enqueue(new QuoteSendPSEmailQueueable_SL(eligibleRecords, 'Deal_Edited'));
    }
  }

  /**
   * @description : Send email to PS user's group when a Deal with PS and License was Booked
   * @param  records         records description
   * @param  existingRecords existingRecords description
   */
  public static void autoAttachPSDealBookedEmail(List<SObject> records, Map<Id, SObject> existingRecords) {
    SObjectPredicate hasChanged = new HasRecordChanged(
      new Set<SObjectField>{ SBQQ__Quote__c.SBQQ__Status__c },
      records,
      existingRecords
    );

    List<SBQQ__Quote__c> eligibleRecords = Collection.of(records)
      .filter(
        Match.field(SBQQ__Quote__c.Total_UiPath_Licenses__c)
          .greaterThan(0)
          .also(SBQQ__Quote__c.Total_Professional_Service__c)
          .greaterThan(0)
          .also(SBQQ__Quote__c.SBQQ__Status__c)
          .equals('Booked')
      )
      .filter(hasChanged)
      .asList();

    if (!eligibleRecords.isEmpty()) {
      AbstractQueueable.enqueue(new QuoteSendPSEmailQueueable_SL(eligibleRecords, 'Deal_Booked'));
    }
  }
}