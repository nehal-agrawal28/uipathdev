public without sharing class CaseCsmNotificationQueueable_SV extends AbstractQueueable {
  private List<Case> cases;
  public CaseCsmNotificationQueueable_SV(List<Case> cases) {
    super('CaseCsmNotificationQueueable_SV');
    this.cases = cases;
    //to allow for logging against record. only used in non-bulk contexts
    if (cases != null && cases.size() == 1) {
      this.setPrimaryRecordId(cases.get(0).Id);
    }
  }

  public override void work() {
    if (this.cases != null) {
      this.sendNotificationsCsm(this.cases);
    }
  }

  public void sendNotificationsCsm(List<Case> cases) {
    List<Case> eligibleCases = [
      SELECT
        Id,
        ContactId,
        Subject,
        Contact.Email,
        Account.Name,
        Account.CSM__r.IsActive,
        CaseNumber,
        Related_To__c,
        Account.CSM__r.Email,
        Account.CSM__c
      FROM Case
      WHERE Id IN :cases AND Account.Segmentation_CS_3_0__c IN ('Low', 'High', 'Strategic')
    ];

    if (eligibleCases.isEmpty()) {
      return;
    }

    String csmEmailTemplateName = 'Notify_CSM_of_Case_Created';
    Map<String, Id> emailTemplateNameIdMap = new Map<String, Id>();
    Set<String> emailTemplateNameSet = new Set<String>{ csmEmailTemplateName };

    List<Messaging.SingleEmailMessage> emailMessageList = new List<Messaging.SingleEmailMessage>();
    String orgWideAddress = Label.UIPathOrgWideAddress;
    OrgWideEmailAddress orgWideAddObj = [
      SELECT Id, Address, DisplayName
      FROM OrgWideEmailAddress
      WHERE Address = :orgWideAddress
    ];
    for (EmailTemplate emailObj : [
      SELECT Id, Subject, DeveloperName, Htmlvalue
      FROM EmailTemplate
      WHERE DeveloperName IN :emailTemplateNameSet
    ]) {
      emailTemplateNameIdMap.put(emailObj.DeveloperName, emailObj.Id);
    }

    for (Case caseObj : eligibleCases) {
      if (caseObj.Account.CSM__c != null && caseObj.Account.CSM__r.IsActive) {
        Messaging.SingleEmailMessage mailObject = new Messaging.SingleEmailMessage();

        mailObject.setTemplateID(emailTemplateNameIdMap.get(csmEmailTemplateName));
        mailObject.setSaveAsActivity(false);
        mailObject.setWhatId(caseObj.Id);
        mailObject.setTargetObjectId(caseObj.ContactId);
        mailObject.setToAddresses(new List<String>{ caseObj.Account.CSM__r.Email });
        mailObject.setOrgWideEmailAddressId(orgWideAddObj.id);

        emailMessageList.add(mailObject);
      }
    }

    Savepoint sp = Database.setSavepoint();
    Messaging.sendEmail(emailMessageList, false);
    Database.rollback(sp);
    //Sending Emails to Non-Contacts
    List<Messaging.SingleEmailMessage> lstOfMsgsToSend = new List<Messaging.SingleEmailMessage>();

    for (Messaging.SingleEmailMessage email : emailMessageList) {
      Messaging.SingleEmailMessage emailObject = new Messaging.SingleEmailMessage();
      emailObject.setToAddresses(email.getToAddresses());
      emailObject.setPlainTextBody(email.getPlainTextBody());
      emailObject.setHTMLBody(email.getHTMLBody());
      emailObject.setSubject(email.getSubject());
      emailObject.setOrgWideEmailAddressId(orgWideAddObj.id);
      lstOfMsgsToSend.add(emailObject);
    }

    try {
      Messaging.sendEmail(lstOfMsgsToSend);
    } catch (Exception error) {
      throw (error);
    }
  }

  public static void sendCsmNotifications(List<SObject> cases) {
    List<Case> filtered = (List<Case>) Collection.of(cases)
      .filter(
        Match.field(Case.RecordTypeId)
          .isIn(new Set<String>{ CaseMetadata_SV.IncidentRecordType, CaseMetadata_SV.CloudElementsRecordType })
      )
      .asList();
    if (!filtered.isEmpty()) {
      AbstractQueueable.enqueue(new CaseCsmNotificationQueueable_SV(filtered));
    }
  }
}