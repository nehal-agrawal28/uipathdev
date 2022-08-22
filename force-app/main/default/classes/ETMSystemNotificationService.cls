/**
 * @AUTHOR: UIPath
 * @DATE: 03/12/2021
 * @DESCRIPTION: The purpose of this class is to Send Notifications based on the Account.Geo__c field for the following scenarios:
 * SLTCHIN-1169:
 * Custom Metadata ETM_System_Notification__mdt has all the configuration for Geo Primary Email and Secondary Email Addresses,
 * Notifications will send to Primary and Secondary emails from metadata where Account.Geo__c == Metadata.DeveloperName (Geo)
 * Case 1: When ValidateTerritoryAssignment_ET batch removes any secondary territory from the account
 * Case 2: When AccountOwnerSyncBatch_ET doesn't sync owner becuase of missing Primary Account Manager and Interim Account Manager and marked Owner Sync Status as Exception
 * Case 3: When OpportunityOwnerSyncBatch_ET doesn't sync owner and marked Owner Sync Status as Exception
 */
public with sharing class ETMSystemNotificationService {
  public static String ENTER_KEY = '<br>';
  public Skip_Email_Alerts__c skipEmailAlert;
  public Set<String> setOfPrimaryEmailIds = new Set<String>();
  public List<OrgWideEmailAddress> listOfOrgWideEmailAddress = new List<OrgWideEmailAddress>();
  public Map<String, User> mapOfEmailToUser = new Map<String, User>();
  public Map<String, String> mapOfGeoToPartnerGeoName = new Map<String, String>{
    'AMER' => 'AMER_Partner_Management',
    'EMEA' => 'EMEA_Partner_Management',
    'APJ' => 'APJ_Partner_Management'
  };
  public Map<String, String> mapOfGeoToNFRNames = new Map<String, String>{
    'AMER' => 'AMER_NFR',
    'EMEA' => 'EMEA_NFR',
    'APJ' => 'APJ_NFR'
  };
  public Map<String, ETM_System_Notification__mdt> mapOfGeoToETMMetadata = new Map<String, ETM_System_Notification__mdt>();

  public ETMSystemNotificationService() {
    this.skipEmailAlert = Skip_Email_Alerts__c.getInstance();
    getETMMetadata();
    validatePrimaryEmailAddress(setOfPrimaryEmailIds);
  }

  private Boolean skipEmailAlert(String objName) {
    Boolean returnValue = false;
    if (
      objName == ETMConstant.OPPORTUNITY_OBJECT &&
      this.skipEmailAlert != null &&
      this.skipEmailAlert.Skip_Email_Alerts_Opportunity__c
    ) {
      returnValue = true;
    }
    if (
      objName == ETMConstant.ACCOUNT_OBJECT &&
      this.skipEmailAlert != null &&
      this.skipEmailAlert.Skip_Email_Alerts_Account__c
    ) {
      returnValue = true;
    }
    return returnValue;
  }
  private void validatePrimaryEmailAddress(Set<String> setOfPrimaryEmailIds) {
    listOfOrgWideEmailAddress = [SELECT Id FROM OrgWideEmailAddress WHERE Address = 'uipathsupport@uipath.com'];
    for (User objUser : [SELECT Id, Email FROM User WHERE isActive = TRUE AND Email IN :setOfPrimaryEmailIds]) {
      if (!mapOfEmailToUser.containsKey(objUser.Email)) {
        mapOfEmailToUser.put(objUser.Email, objUser);
      }
    }
  }

  private Map<String, ETM_System_Notification__mdt> getETMMetadata() {
    for (ETM_System_Notification__mdt etmMetadata : ETM_System_Notification__mdt.getAll().values()) {
      if (!mapOfGeoToETMMetadata.containsKey(etmMetadata.DeveloperName)) {
        setOfPrimaryEmailIds.add(etmMetadata.Primary_Email__c);
        mapOfGeoToETMMetadata.put(etmMetadata.DeveloperName, etmMetadata);
      }
    }
    return mapOfGeoToETMMetadata;
  }

  public void accountOwnerSyncException(List<Account> listOfExceptionAccounts) {
    if (skipEmailAlert(ETMConstant.ACCOUNT_OBJECT)) {
      return;
    }
    Map<String, Messaging.SingleEmailMessage> mapOfGeoToEmailMessageDraft = new Map<String, Messaging.SingleEmailMessage>();
    Set<Id> accountIds = new Set<Id>();

    for (Account objAccount : listOfExceptionAccounts) {
      accountIds.add(objAccount.Id);
    }

    AccountsService_ET service = (AccountsService_ET) Application_ET.Service.newInstance(AccountsService_ET.class);
    Map<Id, Territory2> mapOfAccountIdToTerritory = service.getAccountTerritory(accountIds);

    for (Account objAccount : listOfExceptionAccounts) {
      ETM_System_Notification__mdt etmMetadata = mapOfGeoToETMMetadata.get(objAccount.Geo__c);
      if (etmMetadata != null) {
        if (
          objAccount.Geo__c == etmMetadata.DeveloperName && !mapOfGeoToEmailMessageDraft.containsKey(objAccount.Geo__c)
        ) {
          if (etmMetadata.Primary_Email__c != null && mapOfEmailToUser.containsKey(etmMetadata.Primary_Email__c)) {
            List<String> toAddresses = new List<String>();
            Messaging.SingleEmailMessage emailMessage = new Messaging.SingleEmailMessage();
            toAddresses.add(etmMetadata.Primary_Email__c);
            emailMessage.setSubject(Label.AccountExceptionLabel + '(GEO: ' + objAccount.Geo__c + ')');
            emailMessage.setSaveAsActivity(false);
            if (listOfOrgWideEmailAddress.size() > 0) {
              emailMessage.setOrgWideEmailAddressId(listOfOrgWideEmailAddress.get(0).Id);
            }
            if (etmMetadata.Secondary_Emails__c != null) {
              for (String emailAddress : etmMetadata.Secondary_Emails__c.split(',')) {
                toAddresses.add(emailAddress);
              }
            }
            emailMessage.setToAddresses(toAddresses);
            emailMessage.setTargetObjectId(mapOfEmailToUser.get(etmMetadata.Primary_Email__c).Id);
            String body = 'Hi ' + ENTER_KEY + ENTER_KEY;
            String generateUrl = URL.getSalesforceBaseUrl().toExternalForm() + '/' + objAccount.Id;
            body += Label.AccountNotSyncedLabel + ENTER_KEY + ENTER_KEY;
            body += '<table border="1"><tr><th>Account</th><th>Territory</th></tr>';
            String territoryName;
            if (mapOfAccountIdToTerritory != null && mapOfAccountIdToTerritory.containsKey(objAccount.Id)) {
              territoryName = mapOfAccountIdToTerritory.get(objAccount.Id).Name;
            }
            body +=
              '<tr><td>' +
              '<a href="' +
              generateUrl +
              '">' +
              objAccount.Name +
              '</a>' +
              '</td><td>' +
              territoryName +
              '</td></tr>';
            emailMessage.setHtmlBody(body);
            mapOfGeoToEmailMessageDraft.put(objAccount.Geo__c, emailMessage);
          }
        } else if (
          objAccount.Geo__c == etmMetadata.DeveloperName && mapOfGeoToEmailMessageDraft.containsKey(objAccount.Geo__c)
        ) {
          Messaging.SingleEmailMessage emailMessage = mapOfGeoToEmailMessageDraft.get(objAccount.Geo__c);
          String body = emailMessage.getHtmlBody();
          String generateUrl = URL.getSalesforceBaseUrl().toExternalForm() + '/' + objAccount.Id;
          String territoryName;
          if (mapOfAccountIdToTerritory != null && mapOfAccountIdToTerritory.containsKey(objAccount.Id)) {
            territoryName = mapOfAccountIdToTerritory.get(objAccount.Id).Name;
          }
          body +=
            '<tr><td>' +
            '<a href="' +
            generateUrl +
            '">' +
            objAccount.Name +
            '</a>' +
            '</td><td>' +
            territoryName +
            '</td></tr>';
          emailMessage.setHtmlBody(body);
          mapOfGeoToEmailMessageDraft.put(objAccount.Geo__c, emailMessage);
        }
      }
    }
    sendEmail(mapOfGeoToEmailMessageDraft);
  }

  public void accountCSMTerritoryException(List<Account> listOfExceptionAccounts) {
    if (skipEmailAlert(ETMConstant.ACCOUNT_OBJECT)) {
      return;
    }
    Map<String, Messaging.SingleEmailMessage> mapOfGeoToEmailMessageDraft = new Map<String, Messaging.SingleEmailMessage>();

    for (Account objAccount : listOfExceptionAccounts) {
      ETM_System_Notification__mdt etmMetadata = mapOfGeoToETMMetadata.get(objAccount.Geo__c);
      if (etmMetadata != null) {
        if (
          objAccount.Geo__c == etmMetadata.DeveloperName && !mapOfGeoToEmailMessageDraft.containsKey(objAccount.Geo__c)
        ) {
          if (etmMetadata.Primary_Email__c != null && mapOfEmailToUser.containsKey(etmMetadata.Primary_Email__c)) {
            List<String> toAddresses = new List<String>();
            Messaging.SingleEmailMessage emailMessage = new Messaging.SingleEmailMessage();
            toAddresses.add(etmMetadata.Primary_Email__c);
            emailMessage.setSubject(Label.Account_CSM_Territory_Not_Assigned + '(GEO: ' + objAccount.Geo__c + ')');
            emailMessage.setSaveAsActivity(false);
            if (listOfOrgWideEmailAddress.size() > 0) {
              emailMessage.setOrgWideEmailAddressId(listOfOrgWideEmailAddress.get(0).Id);
            }
            if (etmMetadata.Secondary_Emails__c != null) {
              for (String emailAddress : etmMetadata.Secondary_Emails__c.split(',')) {
                toAddresses.add(emailAddress);
              }
            }
            emailMessage.setToAddresses(toAddresses);
            emailMessage.setTargetObjectId(mapOfEmailToUser.get(etmMetadata.Primary_Email__c).Id);
            String body = 'Hi ' + ENTER_KEY + ENTER_KEY;
            String generateUrl = URL.getSalesforceBaseUrl().toExternalForm() + '/' + objAccount.Id;
            body += Label.Account_CSM_Not_Synched_Label + ENTER_KEY + ENTER_KEY;
            body += '<table border="1"><tr><th>Account</th><th>CSM</th></tr>';
            body +=
              '<tr><td>' +
              '<a href="' +
              generateUrl +
              '">' +
              objAccount.Name +
              '</a>' +
              '</td><td>' +
              objAccount.CSM__r.Name +
              '</td>';
            emailMessage.setHtmlBody(body);
            mapOfGeoToEmailMessageDraft.put(objAccount.Geo__c, emailMessage);
          }
        } else if (
          objAccount.Geo__c == etmMetadata.DeveloperName && mapOfGeoToEmailMessageDraft.containsKey(objAccount.Geo__c)
        ) {
          Messaging.SingleEmailMessage emailMessage = mapOfGeoToEmailMessageDraft.get(objAccount.Geo__c);
          String body = emailMessage.getHtmlBody();
          String generateUrl = URL.getSalesforceBaseUrl().toExternalForm() + '/' + objAccount.Id;
          body +=
            '<tr><td>' +
            '<a href="' +
            generateUrl +
            '">' +
            objAccount.Name +
            '</a>' +
            '</td><td>' +
            objAccount.CSM__r.Name +
            '</td>';
          //body += '<tr><td>' + objAccount.Name + '</td>';
          emailMessage.setHtmlBody(body);
          mapOfGeoToEmailMessageDraft.put(objAccount.Geo__c, emailMessage);
        }
      }
    }
    sendEmail(mapOfGeoToEmailMessageDraft);
  }

  public void oppPartnerTerritoryException(List<Opportunity> listOfExceptionOpp) {
    if (skipEmailAlert(ETMConstant.OPPORTUNITY_OBJECT)) {
      return;
    }
    Map<String, Messaging.SingleEmailMessage> mapOfGeoToEmailMessageDraft = new Map<String, Messaging.SingleEmailMessage>();

    for (Opportunity objOpp : listOfExceptionOpp) {
      if (mapOfGeoToPartnerGeoName.containsKey(objOpp.Territory_Geo__c)) {
        String partnerGeo = mapOfGeoToPartnerGeoName.get(objOpp.Territory_Geo__c);
        ETM_System_Notification__mdt etmMetadata = mapOfGeoToETMMetadata.get(partnerGeo);
        if (etmMetadata != null) {
          if (partnerGeo == etmMetadata.DeveloperName && !mapOfGeoToEmailMessageDraft.containsKey(partnerGeo)) {
            if (etmMetadata.Primary_Email__c != null && mapOfEmailToUser.containsKey(etmMetadata.Primary_Email__c)) {
              List<String> toAddresses = new List<String>();
              Messaging.SingleEmailMessage emailMessage = new Messaging.SingleEmailMessage();
              toAddresses.add(etmMetadata.Primary_Email__c);
              emailMessage.setSubject(
                Label.Opportunity_Partner_Management_Territory_Missing +
                '(GEO: ' +
                partnerGeo +
                ')'
              );
              emailMessage.setSaveAsActivity(false);
              if (listOfOrgWideEmailAddress.size() > 0) {
                emailMessage.setOrgWideEmailAddressId(listOfOrgWideEmailAddress.get(0).Id);
              }
              if (etmMetadata.Secondary_Emails__c != null) {
                for (String emailAddress : etmMetadata.Secondary_Emails__c.split(',')) {
                  toAddresses.add(emailAddress);
                }
              }
              emailMessage.setToAddresses(toAddresses);
              emailMessage.setTargetObjectId(mapOfEmailToUser.get(etmMetadata.Primary_Email__c).Id);
              String body = 'Hi ' + ENTER_KEY + ENTER_KEY;
              String generateUrl = URL.getSalesforceBaseUrl().toExternalForm() + '/' + objOpp.Id;
              body += Label.Opportunity_Partner_Compensation_Split_Label + ENTER_KEY + ENTER_KEY;
              body += '<table border="1"><tr><th>Opportunity</th><th>Territory</th></tr>';
              body +=
                '<tr><td>' +
                '<a href="' +
                generateUrl +
                '">' +
                objOpp.Name +
                '</a>' +
                '</td><td>' +
                objOpp.Territory2.Name +
                '</td>';
              emailMessage.setHtmlBody(body);
              mapOfGeoToEmailMessageDraft.put(partnerGeo, emailMessage);
            }
          } else if (partnerGeo == etmMetadata.DeveloperName && mapOfGeoToEmailMessageDraft.containsKey(partnerGeo)) {
            Messaging.SingleEmailMessage emailMessage = mapOfGeoToEmailMessageDraft.get(partnerGeo);
            String body = emailMessage.getHtmlBody();
            String generateUrl = URL.getSalesforceBaseUrl().toExternalForm() + '/' + objOpp.Id;
            body +=
              '<tr><td>' +
              '<a href="' +
              generateUrl +
              '">' +
              objOpp.Name +
              '</a>' +
              '</td><td>' +
              objOpp.Territory2.Name +
              '</td>';
            //body += '<tr><td>' + objAccount.Name + '</td>';
            emailMessage.setHtmlBody(body);
            mapOfGeoToEmailMessageDraft.put(objOpp.Territory_Geo__c, emailMessage);
          }
        }
      }
    }
    sendEmail(mapOfGeoToEmailMessageDraft);
  }

  private void sendEmail(Map<String, Messaging.SingleEmailMessage> mapOfGeoToEmailMessageDraft) {
    List<Messaging.SingleEmailMessage> emailMessages = new List<Messaging.SingleEmailMessage>();
    for (Messaging.SingleEmailMessage emailMessage : mapOfGeoToEmailMessageDraft.values()) {
      String body = emailMessage.getHtmlBody();
      body += '</table>' + ENTER_KEY + 'Thank You';
      emailMessage.setHtmlBody(body);
      emailMessages.add(emailMessage);
    }
    try {
      List<Messaging.SendEmailResult> result = Messaging.sendEmail(emailMessages);
    } catch (Exception ex) {
      System.debug('Email Exception: ' + ex.getMessage());
    }
  }

  public void secondaryTerritoryRemovalNotification(Map<Id, Set<String>> mapOfAccountIdToTerritoriesName) {
    if (skipEmailAlert(ETMConstant.ACCOUNT_OBJECT)) {
      return;
    }
    Map<String, Messaging.SingleEmailMessage> mapOfGeoToEmailMessageDraft = new Map<String, Messaging.SingleEmailMessage>();

    Map<Id, Account> mapOfAccountIdToRecord = new Map<Id, Account>(
      [SELECT Id, Name, Geo__c FROM Account WHERE Id IN :mapOfAccountIdToTerritoriesName.KeySet()]
    );
    for (Id accountId : mapOfAccountIdToTerritoriesName.KeySet()) {
      Account objAccount = mapOfAccountIdToRecord.get(accountId);
      ETM_System_Notification__mdt etmMetadata = mapOfGeoToETMMetadata.get(objAccount.Geo__c);
      if (etmMetadata != null) {
        if (
          objAccount.Geo__c == etmMetadata.DeveloperName && !mapOfGeoToEmailMessageDraft.containsKey(objAccount.Geo__c)
        ) {
          if (etmMetadata.Primary_Email__c != null && mapOfEmailToUser.containsKey(etmMetadata.Primary_Email__c)) {
            List<String> toAddresses = new List<String>();
            Messaging.SingleEmailMessage emailMessage = new Messaging.SingleEmailMessage();
            toAddresses.add(etmMetadata.Primary_Email__c);
            emailMessage.setSubject(Label.SecondaryTerritoryRemovedLabel + ' (GEO: ' + objAccount.Geo__c + ')');
            emailMessage.setSaveAsActivity(false);
            if (listOfOrgWideEmailAddress.size() > 0) {
              emailMessage.setOrgWideEmailAddressId(listOfOrgWideEmailAddress.get(0).Id);
            }
            if (etmMetadata.Secondary_Emails__c != null) {
              for (String emailAddress : etmMetadata.Secondary_Emails__c.split(',')) {
                toAddresses.add(emailAddress);
              }
            }
            emailMessage.setToAddresses(toAddresses);
            emailMessage.setTargetObjectId(mapOfEmailToUser.get(etmMetadata.Primary_Email__c).Id);
            String body = 'Hi ' + ENTER_KEY + ENTER_KEY;
            String generateUrl = URL.getSalesforceBaseUrl().toExternalForm() + '/' + objAccount.Id;
            body += Label.SecondaryTerritoryRemovedBodyLabel + ENTER_KEY + ENTER_KEY;
            body += '<table border="1"><tr><th>Account</th><th>Secondary Territory</th></tr>';
            for (String territoryName : mapOfAccountIdToTerritoriesName.get(objAccount.Id)) {
              body +=
                '<tr><td>' +
                '<a href="' +
                generateUrl +
                '">' +
                objAccount.Name +
                '</a>' +
                '</td><td>' +
                territoryName +
                '</td></tr>';
              //body += '<tr><td>' + objAccount.Name + '</td><td>' + territoryName + '</td></tr>';
            }
            emailMessage.setHtmlBody(body);
            mapOfGeoToEmailMessageDraft.put(objAccount.Geo__c, emailMessage);
          }
        } else if (
          objAccount.Geo__c == etmMetadata.DeveloperName && mapOfGeoToEmailMessageDraft.containsKey(objAccount.Geo__c)
        ) {
          Messaging.SingleEmailMessage emailMessage = mapOfGeoToEmailMessageDraft.get(objAccount.Geo__c);
          String body = emailMessage.getHtmlBody();
          String generateUrl = URL.getSalesforceBaseUrl().toExternalForm() + '/' + objAccount.Id;
          for (String territoryName : mapOfAccountIdToTerritoriesName.get(objAccount.Id)) {
            body +=
              '<tr><td>' +
              '<a href="' +
              generateUrl +
              '">' +
              objAccount.Name +
              '</a>' +
              '</td><td>' +
              territoryName +
              '</td></tr>';
            //body += '<tr><td>' + objAccount.Name + '</td><td>' + territoryName + '</td></tr>';
          }
          emailMessage.setHtmlBody(body);
          mapOfGeoToEmailMessageDraft.put(objAccount.Geo__c, emailMessage);
        }
      }
    }
    sendEmail(mapOfGeoToEmailMessageDraft);
  }

  private void prepareEmailForNFROpps(List<Opportunity> listOfNFROpps) {
    Map<String, Messaging.SingleEmailMessage> mapOfGeoToEmailMessageDraft = new Map<String, Messaging.SingleEmailMessage>();
    for (Opportunity objOpp : listOfNFROpps) {
      if (mapOfGeoToNFRNames.containsKey(objOpp.Account_Geo__c)) {
        String geoNFR = mapOfGeoToNFRNames.get(objOpp.Account_Geo__c);
        ETM_System_Notification__mdt etmMetadata = mapOfGeoToETMMetadata.get(geoNFR);
        if (etmMetadata != null) {
          if (geoNFR == etmMetadata.DeveloperName && !mapOfGeoToEmailMessageDraft.containsKey(geoNFR)) {
            if (etmMetadata.Primary_Email__c != null && mapOfEmailToUser.containsKey(etmMetadata.Primary_Email__c)) {
              List<String> toAddresses = new List<String>();
              Messaging.SingleEmailMessage emailMessage = new Messaging.SingleEmailMessage();
              toAddresses.add(etmMetadata.Primary_Email__c);
              emailMessage.setSubject('NFR ' + Label.OpportunityExceptionLabel);
              emailMessage.setSaveAsActivity(false);
              if (listOfOrgWideEmailAddress.size() > 0) {
                emailMessage.setOrgWideEmailAddressId(listOfOrgWideEmailAddress.get(0).Id);
              }
              if (etmMetadata.Secondary_Emails__c != null) {
                for (String emailAddress : etmMetadata.Secondary_Emails__c.split(',')) {
                  toAddresses.add(emailAddress);
                }
              }
              emailMessage.setToAddresses(toAddresses);
              emailMessage.setTargetObjectId(mapOfEmailToUser.get(etmMetadata.Primary_Email__c).Id);
              String body = 'Hi ' + ENTER_KEY + ENTER_KEY;
              String generateUrl = URL.getSalesforceBaseUrl().toExternalForm() + '/' + objOpp.Id;
              body += Label.OpportunityNFRExceptionBodyLabel + ENTER_KEY + ENTER_KEY;
              body += '<table border="1"><tr><th>Opportunity</th></tr>';
              body += '<tr><td>' + '<a href="' + generateUrl + '">' + objOpp.Name + '</a>' + '</td>';
              emailMessage.setHtmlBody(body);
              mapOfGeoToEmailMessageDraft.put(geoNFR, emailMessage);
            }
          } else if (geoNFR == etmMetadata.DeveloperName && mapOfGeoToEmailMessageDraft.containsKey(geoNFR)) {
            Messaging.SingleEmailMessage emailMessage = mapOfGeoToEmailMessageDraft.get(geoNFR);
            String body = emailMessage.getHtmlBody();
            String generateUrl = URL.getSalesforceBaseUrl().toExternalForm() + '/' + objOpp.Id;
            body += '<tr><td>' + '<a href="' + generateUrl + '">' + objOpp.Name + '</a>' + '</td>';
            emailMessage.setHtmlBody(body);
            mapOfGeoToEmailMessageDraft.put(geoNFR, emailMessage);
          }
        }
      }
    }
    sendEmail(mapOfGeoToEmailMessageDraft);
  }

  private void prepareEmailForOtherOpps(List<Opportunity> listOfOtherOpps) {
    Map<String, Messaging.SingleEmailMessage> mapOfGeoToEmailMessageDraft = new Map<String, Messaging.SingleEmailMessage>();
    for (Opportunity objOpp : listOfOtherOpps) {
      ETM_System_Notification__mdt etmMetadata = mapOfGeoToETMMetadata.get(objOpp.Account_Geo__c);
      if (etmMetadata != null) {
        if (
          objOpp.Account_Geo__c == etmMetadata.DeveloperName &&
          !mapOfGeoToEmailMessageDraft.containsKey(objOpp.Account_Geo__c)
        ) {
          if (etmMetadata.Primary_Email__c != null && mapOfEmailToUser.containsKey(etmMetadata.Primary_Email__c)) {
            List<String> toAddresses = new List<String>();
            Messaging.SingleEmailMessage emailMessage = new Messaging.SingleEmailMessage();
            toAddresses.add(etmMetadata.Primary_Email__c);
            emailMessage.setSubject(Label.OpportunityExceptionLabel + ' (GEO: ' + objOpp.Account_Geo__c + ')');
            emailMessage.setSaveAsActivity(false);
            if (listOfOrgWideEmailAddress.size() > 0) {
              emailMessage.setOrgWideEmailAddressId(listOfOrgWideEmailAddress.get(0).Id);
            }
            if (etmMetadata.Secondary_Emails__c != null) {
              for (String emailAddress : etmMetadata.Secondary_Emails__c.split(',')) {
                toAddresses.add(emailAddress);
              }
            }
            emailMessage.setToAddresses(toAddresses);
            emailMessage.setTargetObjectId(mapOfEmailToUser.get(etmMetadata.Primary_Email__c).Id);
            String body = 'Hi ' + ENTER_KEY + ENTER_KEY;
            String generateUrl = URL.getSalesforceBaseUrl().toExternalForm() + '/' + objOpp.Id;
            body += Label.OpportunityExceptionBodyLabel + ENTER_KEY + ENTER_KEY;
            body += '<table border="1"><tr><th>Opportunity</th><th>Territory</th></tr>';
            body +=
              '<tr><td>' +
              '<a href="' +
              generateUrl +
              '">' +
              objOpp.Name +
              '</a>' +
              '</td><td>' +
              objOpp.Territory_Name__c +
              '</td></tr>';
            emailMessage.setHtmlBody(body);
            mapOfGeoToEmailMessageDraft.put(objOpp.Account_Geo__c, emailMessage);
          }
        } else if (
          objOpp.Account_Geo__c == etmMetadata.DeveloperName &&
          mapOfGeoToEmailMessageDraft.containsKey(objOpp.Account_Geo__c)
        ) {
          Messaging.SingleEmailMessage emailMessage = mapOfGeoToEmailMessageDraft.get(objOpp.Account_Geo__c);
          String body = emailMessage.getHtmlBody();
          String generateUrl = URL.getSalesforceBaseUrl().toExternalForm() + '/' + objOpp.Id;
          body +=
            '<tr><td>' +
            '<a href="' +
            generateUrl +
            '">' +
            objOpp.Name +
            '</a>' +
            '</td><td>' +
            objOpp.Territory_Name__c +
            '</td></tr>';
          emailMessage.setHtmlBody(body);
          mapOfGeoToEmailMessageDraft.put(objOpp.Account_Geo__c, emailMessage);
        }
      }
    }
    sendEmail(mapOfGeoToEmailMessageDraft);
  }

  public void opportunityOwnerSyncException(List<Opportunity> listOfExceptionOpportunities) {
    if (skipEmailAlert(ETMConstant.OPPORTUNITY_OBJECT)) {
      return;
    }
    List<Opportunity> listOfNFROpps = new List<Opportunity>();
    List<Opportunity> listOfOtherOpps = new List<Opportunity>();
    for (Opportunity objOpp : listOfExceptionOpportunities) {
      if (objOpp.Deal_Type__c == ETMConstant.DEAL_TYPE_NFR) {
        listOfNFROpps.add(objOpp);
      } else {
        listOfOtherOpps.add(objOpp);
      }
    }
    prepareEmailForNFROpps(listOfNFROpps);
    prepareEmailForOtherOpps(listOfOtherOpps);
  }
}