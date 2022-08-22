global class BatchToAutoResolveCase_SV implements Database.Batchable<sObject>, Database.Stateful {
  public Map<String, String> failedRecords;
  public Date dateToConsider;
  global BatchToAutoResolveCase_SV() {
    failedRecords = new Map<String, String>();
    dateToConsider = BatchToSendCaseStrike1Email_SV.calculateWorkingDays(Integer.valueOf(Label.CaseAutoResolvedDays));
  }

  global Database.QueryLocator start(Database.BatchableContext bc) {
    List<String> recordTypeNames = Label.Case3StrikeRuleRecordTypes.split(',');
    List<String> recordTypeIds = new List<String>();

    for (String recordTypeName : recordTypeNames) {
      recordTypeIds.add(
        Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName().get(recordTypeName).getRecordTypeId()
      );
    }

    String query;
    if (Test.isRunningTest()) {
      query = 'Select Id, CaseNumber, Status, Status_Customer_Action_Time_Stamp__c, ContactId, Contact.Name, Contact.Email, SuppliedEmail, SuppliedName from Case where RecordTypeId in :recordTypeIds';
    } else {
      query =
        'Select Id, CaseNumber, Subject, Status, Status_Customer_Action_Time_Stamp__c, ContactId, Contact.Name, Contact.Email, SuppliedEmail, SuppliedName, Status_Sub_Category__c, ' +
        '(Select Id, NewValue, Field, CreatedDate from Histories where Field = \'Status_Sub_Category__c\' order by createdDate desc limit 1)' +
        'from Case where RecordTypeId in :recordTypeIds and Origin!=\'Email\' and Status=\'Customer Action\' and Status_Sub_Category__c=\'3 Strike Rule\' and ' +
        'Id IN (SELECT CaseId FROM CaseHistory where Field = \'Status_Sub_Category__c\' and DAY_ONLY(CreatedDate)=:dateToConsider)';
    }
    return Database.getQueryLocator(query);
  }

  global void execute(Database.BatchableContext bc, List<Case> scope) {
    CaseMetadata_SV.isAutoCloseBatch = true;
    List<Case> casesToUpdate = new List<Case>();
    for (Case caseInScope : scope) {
      if (
        caseInScope.Histories != null &&
        caseInScope.Histories.size() > 0 &&
        caseInScope.Histories[0].NewValue == '3 Strike Rule' &&
        Date.newInstance(
          caseInScope.Histories[0].CreatedDate.year(),
          caseInScope.Histories[0].CreatedDate.month(),
          caseInScope.Histories[0].CreatedDate.day()
        ) == dateToConsider
      ) {
        caseInScope.Status = 'Resolved';
        caseInScope.Auto_Resolved__c = true;
        casesToUpdate.add(caseInScope);
      }
    }
    if (casesToUpdate != null && casesToUpdate.size() > 0) {
      Database.SaveResult[] saveResults = Database.update(casesToUpdate, false);
      for (integer i = 0; i < casesToUpdate.size(); i++) {
        Case caseToUpdate = casesToUpdate[i];
        Database.SaveResult saveResult = saveResults[i];
        if (!saveResult.isSuccess() && !saveResult.getErrors().isEmpty()) {
          failedRecords.put(caseToUpdate.CaseNumber, saveResult.getErrors()[0].getMessage());
        }
      }
    }
  }

  global void finish(Database.BatchableContext bc) {
    try {
      if (failedRecords != null && !failedRecords.isEmpty()) {
        OrgWideEmailAddress owa = [
          SELECT Id, DisplayName, Address
          FROM OrgWideEmailAddress
          WHERE Address = 'uipathsupport@uipath.com'
        ];
        EmailTemplate template = [
          SELECT Id, Subject, Htmlvalue
          FROM EmailTemplate
          WHERE DeveloperName = 'Case_Auto_Close_Errors'
        ];
        List<Messaging.SingleEmailMessage> lstMsgsToSend = new List<Messaging.SingleEmailMessage>();
        Messaging.SingleEmailMessage mailObj = new Messaging.SingleEmailMessage();
        mailObj.setSubject(template.Subject);
        String tableValues = '';
        integer counter = 1;
        for (String failedRecord : failedRecords.keySet()) {
          tableValues =
            tableValues +
            '<tr><td>' +
            counter +
            '</td><td>' +
            failedRecord +
            '</td><td>' +
            failedRecords.get(failedRecord) +
            '</td></tr>';
          counter++;
        }
        String htmlBody = template.HtmlValue.replace('{!tableValues}', tableValues);
        mailObj.setHtmlBody(htmlBody);
        mailObj.setSaveAsActivity(false);

        mailObj.setToAddresses(System.Label.SurveyErrorEmailRecepients.split(','));
        mailObj.setOrgWideEmailAddressId(owa.id);

        lstMsgsToSend.add(mailObj);
        Messaging.sendEmail(lstMsgsToSend);
      }
    } catch (Exception e) {
    }
  }
}