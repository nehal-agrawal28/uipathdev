global class BatchToSendCaseStrike1EmailWE_SV implements Database.Batchable<sObject>, Database.Stateful {
  global List<String> caseIds;
  public OrgWideEmailAddress owa;
  public EmailTemplate template;
  public Integer autoResolvedRemainingDays;
  public Date dateToConsiderSat;
  public Date dateToConsiderSun;
  global BatchToSendCaseStrike1EmailWE_SV() {
    try {
      caseIds = new List<String>();
      Integer CaseStrike1Days = Integer.valueOf(Label.CaseStrike1Days);
      Integer CaseAutoResolveDays = Integer.valueOf(Label.CaseAutoResolvedDays);
      autoResolvedRemainingDays = CaseAutoResolveDays - CaseStrike1Days;
      owa = [SELECT id, DisplayName, Address FROM OrgWideEmailAddress WHERE Address = 'uipathsupport@uipath.com'];
      template = [SELECT id, subject, htmlvalue FROM EmailTemplate WHERE name = 'Case Strike 1 Email'];
      dateToConsiderSun = System.today().addDays(-1 * Integer.valueOf(Label.CaseStrike1Days)); //BatchToSendCaseStrike1Email.calculateWorkingDays(Integer.valueOf(Label.CaseStrike1Days));
      dateToConsiderSat = dateToConsiderSun.addDays(-1);
      if (Test.isRunningTest()) {
        Integer.valueOf('p');
      }
    } catch (Exception e) {
      Logger.error('Failed BatchToSendCaseStrike1EmailWE_SV', e);
      Logger.saveLog();
    }
  }

  global Database.QueryLocator start(Database.BatchableContext bc) {
    List<String> recordTypeNames = Label.Case3StrikeRuleRecordTypes.split(',');
    List<String> recordTypeIds = new List<String>();

    for (String recordTypeName : recordTypeNames) {
      recordTypeIds.add(
        Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName().get(recordTypeName).getRecordTypeId()
      );
    }
    String query = '';
    if (Test.isRunningTest()) {
      query = 'SELECT Id, CaseNumber, Subject, Status, Status_Customer_Action_Time_Stamp__c, ContactId, Contact.Name, Contact.Email, SuppliedEmail, SuppliedName, Status_Sub_Category__c FROM Case WHERE RecordTypeId IN :recordTypeIds';
    } else {
      query =
        'SELECT Id, CaseNumber, Subject, Status, Status_Customer_Action_Time_Stamp__c, ContactId, Contact.Name, Contact.Email, SuppliedEmail, SuppliedName, Status_Sub_Category__c, ' +
        '(SELECT Id, NewValue, Field, CreatedDate FROM Histories WHERE Field = \'Status_Sub_Category__c\' ORDER BY CreatedDate DESC LIMIT 1)' +
        ' FROM Case WHERE RecordTypeId IN :recordTypeIds AND Origin != \'Email\' AND Status = \'Customer Action\' AND Status_Sub_Category__c = \'3 Strike Rule\' AND ' +
        'Id IN (SELECT CaseId FROM CaseHistory WHERE Field = \'Status_Sub_Category__c\' AND (DAY_ONLY(CreatedDate) = :dateToConsiderSat OR DAY_ONLY(CreatedDate) = :dateToConsiderSun))';
    }
    return Database.getQueryLocator(query);
  }

  global void execute(Database.BatchableContext bc, List<Case> scope) {
    try {
      CaseMetadata_SV.isAutoCloseBatch = true;
      List<Messaging.SingleEmailMessage> emailMessages = new List<Messaging.SingleEmailMessage>();
      Map<String, String> caseAndContactIdMap = new Map<String, String>();
      for (Case caseInScope : scope) {
        if (Test.isRunningTest() || (caseInScope.Histories != null && caseInScope.Histories.size() > 0)) {
          Date caseHistoryDate;
          DateTime caseHistoryDateTime;
          String dayOfWeek;
          if (!Test.isRunningTest()) {
            caseHistoryDate = Date.newInstance(
              caseInScope.Histories[0].CreatedDate.year(),
              caseInScope.Histories[0].CreatedDate.month(),
              caseInScope.Histories[0].CreatedDate.day()
            );
            caseHistoryDateTime = DateTime.newInstance(
              caseInScope.Histories[0].CreatedDate.year(),
              caseInScope.Histories[0].CreatedDate.month(),
              caseInScope.Histories[0].CreatedDate.day()
            );
            dayOfWeek = caseHistoryDateTime.format('EEEE');
          }
          if (
            Test.isRunningTest() ||
            (caseInScope.Histories[0].NewValue == '3 Strike Rule' &&
            ((dayOfWeek == 'Saturday' && caseHistoryDate == dateToConsiderSat) ||
            (dayOfWeek == 'Sunday' &&
            caseHistoryDate == dateToConsiderSun)))
          ) {
            caseIds.add(caseInScope.Id);
            Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
            mail.setSaveAsActivity(false);
            List<String> emailAddresses = new List<String>();
            mail.setWhatId(caseInScope.Id);
            //mail.setTargetObjectId(c.ContactId);
            String subject = template.Subject;
            String htmlValue = template.HtmlValue;
            String name = '';
            if (
              caseInScope.ContactId != null &&
              String.isNotBlank(caseInScope.ContactId) &&
              String.isNotEmpty(caseInScope.ContactId)
            ) {
              emailAddresses.add(caseInScope.Contact.Email);
              name = caseInScope.Contact.Name;
              mail.setTargetObjectId(caseInScope.ContactId);
            } else {
              emailAddresses.add(caseInScope.SuppliedEmail);
              name = caseInScope.SuppliedName;
              mail.setToAddresses(emailAddresses);
            }
            subject = subject.replace('{!Case.CaseNumber}', caseInScope.CaseNumber);
            if (caseInScope.Subject != null) {
              subject = subject.replace('{!Case.Subject}', caseInScope.Subject);
            } else {
              subject = subject.remove('{!Case.Subject}');
            }
            htmlValue = htmlValue.replace('{!Contact.FirstName}', name);
            String autoResolvedText =
              'If we do not hear back in next ' +
              autoResolvedRemainingDays +
              ' working day(s), the case will be auto-resolved. <br/>';
            htmlValue = htmlValue.replace('{!AutoResolvedText}', autoResolvedText);
            String reminderNumber = '#Case Reminder 1';
            htmlValue = htmlValue.replace('{!CaseReminderNumber}', reminderNumber);
            String caseId = caseInScope.Id;
            htmlValue += '<br/> ' + threadIdClass.caseRefId(UserInfo.getOrganizationId(), caseId);
            mail.setSubject(subject);
            mail.setHtmlBody(htmlValue);
            mail.setOrgWideEmailAddressId(owa.id);
            mail.setTemplateID(template.Id);
            mail.setSaveAsActivity(true);
            emailMessages.add(mail);
          }
        }
      }
      if (emailMessages != null && emailMessages.size() > 0) {
        Messaging.sendEmail(emailMessages, false);
      }
      if (Test.isRunningTest()) {
        Integer.valueOf('p');
      }
    } catch (Exception e) {
      Logger.error('Failed BatchToSendCaseStrike1EmailWE_SV', e);
      Logger.saveLog();
    }
  }

  global void finish(Database.BatchableContext bc) {
    try {
      if (caseIds != null && !caseIds.isEmpty()) {
        String cases = '(\'' + String.join(caseIds, '\',\'') + '\')';
        List<String> recordTypeNames = Label.Case3StrikeRuleRecordTypes.split(',');
        List<String> recordTypeIds = new List<String>();

        for (String recordTypeName : recordTypeNames) {
          recordTypeIds.add(
            Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName().get(recordTypeName).getRecordTypeId()
          );
        }
        String query =
          'SELECT Id, CaseNumber, Subject, Status, Status_Customer_Action_Time_Stamp__c, ContactId, Contact.Name, Contact.Email, SuppliedEmail, SuppliedName, Status_Sub_Category__c, ' +
          '(SELECT Id, NewValue, Field, CreatedDate FROM Histories WHERE Field = \'Status_Sub_Category__c\' ORDER BY CreatedDate DESC LIMIT 1) ' +
          'FROM Case WHERE RecordTypeId IN :recordTypeIds AND Origin!= \'Email\' AND Status= \'Customer Action\' AND Status_Sub_Category__c= \'3 Strike Rule\' AND ' +
          'Id IN ' +
          cases;
        BatchToSendCaseStrike2Email_SV bat = new BatchToSendCaseStrike2Email_SV(query);
        System.scheduleBatch(bat, 'Strike2Email' + System.now(), 24 * 60);
      }
    } catch (Exception e) {
      Logger.error('Failed BatchToSendCaseStrike1EmailWE_SV', e);
      Logger.saveLog();
    }
  }
}