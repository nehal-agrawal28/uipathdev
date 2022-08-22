/**
 * @File Name          : FileUploadController.cls
 * @Description        :
 * @Author             : phUser@phDomain.com
 * @Group              :
 * @Last Modified By   : phUser@phDomain.com
 * @Last Modified On   : 12/19/2018, 4:47:44 PM
 * @Modification Log   :
 *==============================================================================
 * Ver         Date                     Author      		      Modification
 *==============================================================================
 * 1.0    12/12/2018, 3:14:26 PM   phUser@phDomain.com     Initial Version
 **/
public without sharing class FileUploadController {
  public transient Attachment objAttachment;

  public Boolean fileUploadProcessed { get; set; }
  public String message { get; set; }
  public String messageType { get; set; }

  public Attachment getObjAttachment() {
    objAttachment = new Attachment();
    return objAttachment;
  }

  public void uploadFile() {
    try {
      insert objAttachment;
      message = 'File was uploaded successfully';
      messageType = 'success';
    } catch (Exception e) {
      message = e.getMessage();
      messageType = 'error';
      System.debug('Error++:' + e);
    }
    fileUploadProcessed = true;
  }
  @AuraEnabled
  public static Id saveChunk(Id parentId, String fileName, String base64Data, String contentType, String fileId) {
    if (fileId == '') {
      fileId = saveTheFile(parentId, fileName, base64Data, contentType);
    } else {
      appendToFile(fileId, base64Data);
    }

    return Id.valueOf(fileId);
  }
  @AuraEnabled
  public static Case saveCase(String caseString) {
    if (String.isBlank(caseString))
      return null;
    try {
      Case caseObj = (Case) JSON.deserialize(caseString, Case.class);
      if (
        caseObj.RecordTypeId == CaseMetadata_SV.AcademyRecordType &&
        caseObj.AccountId == null &&
        caseObj.Country__c != null &&
        String.isNotBlank(caseObj.SuppliedEmail)
      ) {
        String emailDomain = caseObj.SuppliedEmail.substringAfter('@');
        List<AccountRelatedEmailDomain__c> relatedDomains = [
          SELECT Account__c, Account__r.BillingCountry, Account__r.Name
          FROM AccountRelatedEmailDomain__c
          WHERE EmailDomainName__c = :emailDomain AND Account__r.BillingCountry = :caseObj.Country__c
        ];
        if (!relatedDomains.isEmpty()) {
          caseObj.AccountId = relatedDomains.get(0).Account__c;
        }
      }
      Database.DMLOptions dlo = new Database.DMLOptions();
      dlo.EmailHeader.triggerAutoResponseEmail = true;
      dlo.AssignmentRuleHeader.useDefaultRule = true;
      caseObj.setOptions(dlo);
      insert caseObj;
      return caseObj;
    } catch (Exception e) {
      System.debug('Exception :' + e);
    }
    return null;
  }

  public static Id saveTheFile(Id parentId, String fileName, String base64Data, String contentType) {
    base64Data = EncodingUtil.urlDecode(base64Data, 'UTF-8');

    Attachment oAttachment = new Attachment();
    oAttachment.parentId = parentId;

    oAttachment.Body = EncodingUtil.base64Decode(base64Data);
    oAttachment.Name = fileName;
    oAttachment.ContentType = contentType;

    insert oAttachment;

    return oAttachment.Id;
  }

  private static void appendToFile(Id fileId, String base64Data) {
    try {
      base64Data = EncodingUtil.urlDecode(base64Data, 'UTF-8');

      Attachment a = [SELECT Id, Body FROM Attachment WHERE Id = :fileId];

      String existingBody = EncodingUtil.base64Encode(a.Body);

      a.Body = EncodingUtil.base64Decode(existingBody + base64Data);

      update a;
    } catch (Exception e) {
      System.debug('Ex :' + e);
    }
  }

  @AuraEnabled
  public static List<PickListValueWrapper> getCountryPickListValues() {
    Schema.DescribeFieldResult countryValues = Case.Country__c.getDescribe();
    List<Schema.PicklistEntry> valueList = countryValues.getPicklistValues();

    List<PickListValueWrapper> optionList = new List<PickListValueWrapper>();
    optionList.add(new PickListValueWrapper('--None--', ''));
    for (Schema.PicklistEntry entry : valueList) {
      optionList.add(new PickListValueWrapper(entry.getLabel(), entry.getValue()));
    }
    return optionList;
  }

  @AuraEnabled
  public static List<PickListValueWrapper> getPriorityPickListValues() {
    return Ui_PickListController.picklistValuesByRecordType('Case', 'Priority', SupportConstants.incidentRtId);
  }

  @AuraEnabled
  public static List<PickListValueWrapper> getRelatedPickListValues() {
    Schema.DescribeFieldResult countryValues = Case.Related_To__c.getDescribe();
    List<Schema.PicklistEntry> valueList = countryValues.getPicklistValues();

    List<PickListValueWrapper> optionList = new List<PickListValueWrapper>();
    optionList.add(new PickListValueWrapper('--None--', ''));
    for (Schema.PicklistEntry entry : valueList) {
      optionList.add(new PickListValueWrapper(entry.getLabel(), entry.getValue()));
    }
    System.debug('optionList' + optionList);
    return optionList;
  }

  @AuraEnabled
  public static List<PickListValueWrapper> getWhatFeatureIsThisRelatedToPickListValues() {
    Schema.DescribeFieldResult countryValues = Case.What_feature_is_this_related_to__c.getDescribe();
    List<Schema.PicklistEntry> valueList = countryValues.getPicklistValues();

    List<PickListValueWrapper> optionList = new List<PickListValueWrapper>();
    optionList.add(new PickListValueWrapper('--None--', ''));
    for (Schema.PicklistEntry entry : valueList) {
      optionList.add(new PickListValueWrapper(entry.getLabel(), entry.getValue()));
    }
    return optionList;
  }

  @AuraEnabled
  public static List<PickListValueWrapper> getRelatedPickListByRecordTypeId(String recordTypeId) {
    return Ui_PickListController.picklistValuesByRecordType('Case', 'Related_To__c', recordTypeId);
  }

  @AuraEnabled
  public static List<PickListValueWrapper> getEnvironmentPickListValues() {
    Schema.DescribeFieldResult countryValues = Case.Environment_Of_Issue__c.getDescribe();
    List<Schema.PicklistEntry> valueList = countryValues.getPicklistValues();

    List<PickListValueWrapper> optionList = new List<PickListValueWrapper>();
    optionList.add(new PickListValueWrapper('--None--', ''));
    for (Schema.PicklistEntry entry : valueList) {
      optionList.add(new PickListValueWrapper(entry.getLabel(), entry.getValue()));
    }
    return optionList;
  }
  @AuraEnabled
  public static List<PickListValueWrapper> getIssueTypePickListValues() {
    Schema.DescribeFieldResult countryValues = Case.Issue_type_1__c.getDescribe();
    List<Schema.PicklistEntry> valueList = countryValues.getPicklistValues();

    List<PickListValueWrapper> optionList = new List<PickListValueWrapper>();
    optionList.add(new PickListValueWrapper('--None--', ''));
    for (Schema.PicklistEntry entry : valueList) {
      optionList.add(new PickListValueWrapper(entry.getLabel(), entry.getValue()));
    }
    return optionList;
  }

  @AuraEnabled
  public static List<PickListValueWrapper> getNumRobPickListValues() {
    Schema.DescribeFieldResult countryValues = Case.No_Of_robots_impacted_by_issue__c.getDescribe();
    List<Schema.PicklistEntry> valueList = countryValues.getPicklistValues();

    List<PickListValueWrapper> optionList = new List<PickListValueWrapper>();
    optionList.add(new PickListValueWrapper('--None--', ''));
    for (Schema.PicklistEntry entry : valueList) {
      optionList.add(new PickListValueWrapper(entry.getLabel(), entry.getValue()));
    }
    return optionList;
  }

  @AuraEnabled
  public static List<PickListValueWrapper> getTimeZoneList() {
    Schema.DescribeFieldResult countryValues = Case.Time_Zone__c.getDescribe();
    List<Schema.PicklistEntry> valueList = countryValues.getPicklistValues();

    List<PickListValueWrapper> optionList = new List<PickListValueWrapper>();
    optionList.add(new PickListValueWrapper('--None--', ''));
    for (Schema.PicklistEntry entry : valueList) {
      optionList.add(new PickListValueWrapper(entry.getLabel(), entry.getValue()));
    }
    return optionList;
  }

  @AuraEnabled
  public static List<PickListValueWrapper> getStudioPickListValues() {
    Schema.DescribeFieldResult countryValues = Case.Studio_Version__c.getDescribe();
    List<Schema.PicklistEntry> valueList = countryValues.getPicklistValues();

    List<PickListValueWrapper> optionList = new List<PickListValueWrapper>();
    optionList.add(new PickListValueWrapper('--None--', ''));
    for (Schema.PicklistEntry entry : valueList) {
      optionList.add(new PickListValueWrapper(entry.getLabel(), entry.getValue()));
    }
    return optionList;
  }

  @AuraEnabled
  public static List<PickListValueWrapper> getOrchestratorPickListValues() {
    Schema.DescribeFieldResult countryValues = Case.Orchestrator_Version__c.getDescribe();
    List<Schema.PicklistEntry> valueList = countryValues.getPicklistValues();

    List<PickListValueWrapper> optionList = new List<PickListValueWrapper>();
    optionList.add(new PickListValueWrapper('--None--', ''));
    for (Schema.PicklistEntry entry : valueList) {
      optionList.add(new PickListValueWrapper(entry.getLabel(), entry.getValue()));
    }
    return optionList;
  }

  @AuraEnabled
  public static List<PickListValueWrapper> getExpertisePickListValues() {
    Schema.DescribeFieldResult countryValues = Case.What_s_your_field_of_expertise__c.getDescribe();
    List<Schema.PicklistEntry> valueList = countryValues.getPicklistValues();

    List<PickListValueWrapper> optionList = new List<PickListValueWrapper>();
    optionList.add(new PickListValueWrapper('--None--', ''));
    for (Schema.PicklistEntry entry : valueList) {
      optionList.add(new PickListValueWrapper(entry.getLabel(), entry.getValue()));
    }
    return optionList;
  }

  @AuraEnabled
  public static List<PickListValueWrapper> getJobLevelPickListValues() {
    Schema.DescribeFieldResult countryValues = Case.Job_Level__c.getDescribe();
    List<Schema.PicklistEntry> valueList = countryValues.getPicklistValues();

    List<PickListValueWrapper> optionList = new List<PickListValueWrapper>();
    optionList.add(new PickListValueWrapper('--None--', ''));
    for (Schema.PicklistEntry entry : valueList) {
      optionList.add(new PickListValueWrapper(entry.getLabel(), entry.getValue()));
    }
    return optionList;
  }

  @AuraEnabled
  public static List<PickListValueWrapper> getRequestPickListValues() {
    Schema.DescribeFieldResult countryValues = Case.What_is_your_request_related_to__c.getDescribe();
    List<Schema.PicklistEntry> valueList = countryValues.getPicklistValues();

    List<PickListValueWrapper> optionList = new List<PickListValueWrapper>();
    optionList.add(new PickListValueWrapper('--None--', ''));
    for (Schema.PicklistEntry entry : valueList) {
      optionList.add(new PickListValueWrapper(entry.getLabel(), entry.getValue()));
    }
    return optionList;
  }

  @AuraEnabled
  public static List<PickListValueWrapper> getLicenseCatgryPickListValues() {
    Schema.DescribeFieldResult countryValues = Case.License_Category__c.getDescribe();
    List<Schema.PicklistEntry> valueList = countryValues.getPicklistValues();

    List<PickListValueWrapper> optionList = new List<PickListValueWrapper>();
    optionList.add(new PickListValueWrapper('--None--', ''));
    for (Schema.PicklistEntry entry : valueList) {
      optionList.add(new PickListValueWrapper(entry.getLabel(), entry.getValue()));
    }
    return optionList;
  }

  @AuraEnabled
  public static List<PickListValueWrapper> getIssueCatgryPickListValues() {
    Schema.DescribeFieldResult countryValues = Case.Issue_Category__c.getDescribe();
    List<Schema.PicklistEntry> valueList = countryValues.getPicklistValues();

    List<PickListValueWrapper> optionList = new List<PickListValueWrapper>();
    optionList.add(new PickListValueWrapper('--None--', ''));
    for (Schema.PicklistEntry entry : valueList) {
      optionList.add(new PickListValueWrapper(entry.getLabel(), entry.getValue()));
    }
    return optionList;
  }

  @AuraEnabled
  public static Map<String, List<String>> getCountryCodePickListValues(
    sObject objDetail,
    string contrfieldApiName,
    string depfieldApiName
  ) {
    return DependentPickListUtil.getDependentMap(objDetail, contrfieldApiName, depfieldApiName);
  }

  @AuraEnabled
  public static Map<String, List<String>> getJobDependentPickListValues(
    sObject objDetail,
    string contrfieldApiName,
    string depfieldApiName
  ) {
    return DependentPickListUtil.getDependentMap(objDetail, contrfieldApiName, depfieldApiName);
  }

  @AuraEnabled
  public static Map<String, List<String>> getAcademyDependentPicklistValues(
    sObject objDetail,
    string contrfieldApiName,
    string depfieldApiName
  ) {
    Map<String, List<String>> depMap = DependentPickListUtil.getDependentMap(
      objDetail,
      contrfieldApiName,
      depfieldApiName
    );
    Map<String, List<String>> depMapToBeReturned = new Map<String, List<String>>();
    List<PickListValueWrapper> valuesInRecordType = Ui_PickListController.picklistValuesByRecordType(
      'Case',
      contrfieldApiName,
      SupportConstants.academyRtId
    );
    for (PickListValueWrapper wrapper : valuesInRecordType) {
      depMapToBeReturned.put(wrapper.label, depMap.get(wrapper.label));
    }
    return depMapToBeReturned;
  }

  @AuraEnabled
  public static List<CaseProductRecordType__mdt> getproductRecordTypes() {
    return [SELECT Id, RecordTypeId__c, MasterLabel FROM CaseProductRecordType__mdt LIMIT 49999];
  }
  @AuraEnabled
  public static List<CaseLicenceCategoryMessage__mdt> getLicensingMessages() {
    return [SELECT Id, Message__c, MasterLabel FROM CaseLicenceCategoryMessage__mdt LIMIT 49999];
  }
  /*
This method fetches active BlackListedDomain's List
Considering the MasterLabel as Comparing value
*/
  @AuraEnabled
  public static List<BlackListedDomain__mdt> getBlackListDomains() {
    return [SELECT Id, MasterLabel, IsActive__c FROM BlackListedDomain__mdt WHERE IsActive__c = TRUE LIMIT 49999];
  }

  /*@AuraEnabled
public static String validateLicenseCode (String endCustomerName, String licenseCode) {
Map <String, Object> resMap = new Map<String, Object> ();

if (String.isBlank(endCustomerName) || String.isBlank(licenseCode)) {
resMap.put ('status', 'ERROR');
resMap.put ('message', Label.Required_Field_missing);
} else {
List<License_Code__c> licenseCodeList = new List <License_Code__c> ([SELECT Id 
FROM License_Code__c 
WHERE  LicenseCode__c =: licenseCode  
AND CompanyName__c =: endCustomerName
LIMIT 1]);
if (licenseCodeList != null && !licenseCodeList.isEmpty ()) {
resMap.put ('status', 'SUCCESS');
resMap.put ('message', Label.Valid_License_Code);
} else {
resMap.put ('status', 'ERROR');
resMap.put ('message', Label.Invalid_License_code);
}
}
return JSON.serialize(resMap);
}*/

  @AuraEnabled //Added By Maanas 20-April-2020
  public static String validateLicenseCode(String licenseCode) {
    Map<String, Object> resMap = new Map<String, Object>();

    if (String.isBlank(licenseCode)) {
      resMap.put('status', 'ERROR');
      resMap.put('message', Label.Required_Field_missing);
    } else {
      /*  List<License_Code__c> licenseCodeList = new List <License_Code__c> ([SELECT Id, CompanyName__c
FROM License_Code__c 
WHERE  LicenseCode__c =: licenseCode
LIMIT 1]);*/

      String response = Ui_PathValidateLicenseCode.validateLicenseCode(licenseCode);
      String jsonStr = string.valueof(response);
      System.debug('jsonStr***' + jsonStr);
      if (!jsonStr.contains('status=404')) {
        BoonWrapper boonWrap = BoonWrapper.parse(response);
        resMap.put('status', 'SUCCESS');
        resMap.put('name', boonWrap.accountName);
        resMap.put('message', Label.Valid_License_Code);
        resMap.put('accountId', boonWrap.accountId);
        resMap.put('caseType', boonWrap.licenseObj.name);
        resMap.put('subscriptionCode', boonWrap.licenseObj.subscriptionCode);
        resMap.put('endDate', boonWrap.licenseObj.endDate);
        resMap.put('duration', boonWrap.licenseObj.duration);
        resMap.put('createdDateTime', boonWrap.licenseObj.createdDateTime);
        Map<String, Object> responseMap = (Map<String, Object>) System.JSON.deserializeUntyped(jsonStr);
        Map<String, Object> licenseObjMap, bundleMap;
        if (responseMap != null && responseMap.get('license') != null) {
          licenseObjMap = (Map<String, Object>) System.JSON.deserializeUntyped(
            System.JSON.serialize(responseMap.get('license'))
          );
          if (licenseObjMap != null && licenseObjMap.get('bundle') != null) {
            bundleMap = (Map<String, Object>) System.JSON.deserializeUntyped(
              System.JSON.serialize(licenseObjMap.get('bundle'))
            );
            if (bundleMap != null && bundleMap.get('name') != null) {
              resMap.put('bundleName', (String) bundleMap.get('name'));
            }
          }
        }
      } else {
        resMap.put('status', 'ERROR');
        resMap.put('message', Label.Invalid_License_code);
      }
    }
    return JSON.serialize(resMap);
  }

  @AuraEnabled
  public static Apex_Callouts.cloudRPAValidated cloudRPAAccount(String validateSiteURL) {
    Apex_Callouts.cloudRPAValidated crv = new Apex_Callouts.cloudRPAValidated();
    if (validateSiteURL != null) {
      String AccountName = null;
      List<String> tempList = new List<String>();
      tempList = validateSiteURL.split('.com/');
      if (tempList.size() == 2) {
        List<String> tempList1 = new List<String>();
        if (tempList[1].contains('/')) {
          tempList1 = tempList[1].split('/');
          accountName = tempList1[0];
        } else {
          accountName = tempList[1];
        }
      }
      try {
        crv = Apex_Callouts.validateSiteName(accountName);
        return crv;
      } catch (exception ex) {
        return crv;
      }
    } else {
      return crv;
    }
  }

  @AuraEnabled
  public static WrapperwithQueue expertRequest(String RecordId) {
    List<Case> Li = [
      SELECT
        Id,
        AccountId,
        RecordTypeId,
        Status,
        ContactId,
        Subject,
        OwnerId,
        Description,
        CSM_Email_From_Accout__c,
        Related_To__c,
        Sub_Component__c,
        Steps_Performed__c,
        Problem__c,
        Cause__c,
        Validation__c,
        Solution__c,
        Solution_Instructions__c,
        Priority,
        CreatedDate
      FROM Case
      WHERE Id = :RecordId
    ];
    WrapperwithQueue newWrapper = new WrapperwithQueue(Li);
    system.debug('newWrapper' + newWrapper);
    return newWrapper;
  }

  public class WrapperwithQueue {
    @AuraEnabled
    public String QueID;
    @AuraEnabled
    public List<Case> associatedCases;
    @AuraEnabled
    public String parentCaseStatus;
    @AuraEnabled
    public String reasonForAging;
    @AuraEnabled
    public Id expertReqRecTypeId = Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName()
      .get('Engagement_Request')
      .getRecordTypeId();

    public WrapperwithQueue(List<case> cases) {
      this.queId = [SELECT id FROM Group WHERE type = 'Queue' AND developername = 'ER_Queue'].Id;
      this.associatedCases = cases;
      this.parentCaseStatus = cases[0].Status;
      if (cases.get(0).CreatedDate.date().daysBetween(System.today()) > 7) {
        this.reasonForAging = 'Escalated to MCS';
      }
    }
  }
  @AuraEnabled
  public static Id createERCase(Case caseObj) {
    if (null != caseObj) {
      try {
        Case parentCase = [SELECT Id, Reason_For_Aging__c, CreatedDate FROM Case WHERE Id = :caseObj.ParentId];
        if (parentCase.CreatedDate.date().daysBetween(System.today()) > 7) {
          parentCase.Reason_For_Aging__c = 'Escalated to MCS';
          update parentCase;
        }
        insert caseObj;
        return caseObj.Id;
      } catch (exception e) {
        String error = e.getMessage();
        throw new AuraHandledException(error);
      }
    }
    return null;
  }

  @AuraEnabled
  public static List<PickListValueWrapper> getGenericPicklistValues(String objName, String fieldName) {
    Schema.SObjectType sobjName = Schema.getGlobalDescribe().get(objName);
    Schema.DescribeSObjectResult r = sobjName.getDescribe();
    Map<String, Schema.SObjectField> fields = r.fields.getMap();
    Schema.DescribeFieldResult fieldResult = fields.get(fieldName).getDescribe();
    List<Schema.PicklistEntry> ple = fieldResult.getPicklistValues();
    List<PickListValueWrapper> optionList = new List<PickListValueWrapper>();
    optionList.add(new PickListValueWrapper('--None--', ''));
    for (Schema.PicklistEntry entry : ple) {
      optionList.add(new PickListValueWrapper(entry.getLabel(), entry.getValue()));
    }
    return optionList;
  }

  @AuraEnabled
  public static Id getGenericRecordTyeId(String objName, String devlperName) {
    Id RecTypeId;
    Schema.SObjectType sobjName = Schema.getGlobalDescribe().get(objName);
    Schema.DescribeSObjectResult r = sobjName.getDescribe();
    RecTypeId = r.getRecordTypeInfosByDeveloperName().get(devlperName).getRecordTypeId();
    return RecTypeId;
  }

  @AuraEnabled
  public static Case saveCaseCreateContact(String caseString) {
    try {
      if (String.isNotBlank(caseString)) {
        Case caseObj = (Case) JSON.deserialize(caseString, Case.class);
        System.debug('caseObj.AccountId**' + caseObj.AccountId);
        if (
          caseObj.Subscription_Code__c == 'TRIAL' &&
          caseObj.AccountId != null &&
          String.isNotBlank(caseObj.AccountId) &&
          String.isNotEmpty(caseObj.AccountId)
        ) {
          List<Contact> con = [SELECT Id FROM Contact WHERE Email = :caseObj.SuppliedEmail];
          if (con != null && !con.isEmpty()) {
            caseObj.ContactId = con[0].Id;
          } else {
            Account acc = [SELECT Id, OwnerId FROM Account WHERE Id = :caseObj.AccountId];
            String[] nameParts = caseObj.SuppliedName.split(' ', 2);
            system.debug('LastName-------' + nameParts.size());
            String lastNameFromWeb;
            String FirstNameFromWeb = '';
            if (nameParts.size() > 1) {
              FirstNameFromWeb = nameParts[0];
              lastNameFromWeb = nameParts[1];
            } else if (nameParts.size() == 1) {
              lastNameFromWeb = nameParts[0];
            }
            String contactRecordtypeId = Schema.SObjectType.Contact.getRecordTypeInfosByName()
              .get('Contact')
              .getRecordTypeId();
            Contact cont = new Contact(
              ownerId = acc.OwnerId,
              FirstName = FirstNameFromWeb,
              LastName = lastNameFromWeb,
              Email = caseObj.SuppliedEmail,
              Autocreated__c = true,
              Title = 'Title',
              AccountId = caseObj.AccountId,
              recordtypeId = contactRecordtypeId
            );
            insert cont;
            caseObj.ContactId = cont.Id;
          }
        }
        Database.DMLOptions dlo = new Database.DMLOptions();

        dlo.EmailHeader.triggerAutoResponseEmail = true;
        //dlo.EmailHeader.triggerOtherEmail = true;
        //dlo.EmailHeader.triggerUserEmail = true;
        dlo.AssignmentRuleHeader.useDefaultRule = true;

        System.debug('Case Obj :' + caseObj);

        caseObj.setOptions(dlo);
        insert caseObj;
        //database.SaveResult res =  database.insert(caseObj, dlo);
        system.debug('Exception :**CaseGx' + caseObj);
        return caseObj;
      }
    } catch (Exception e) {
      system.debug('Exception :**CaseG' + e);
    }
    return null;
  }

  @AuraEnabled
  public static List<PickListValueWrapper> getGenericObjectfieldValues(
    String objAPIName,
    String fieldName,
    String recordTypeDevName
  ) {
    Id recordTypeId = Schema.getGlobalDescribe()
      .get(objAPIName)
      .getDescribe()
      .getRecordTypeInfosByDeveloperName()
      .get(recordTypeDevName)
      .getRecordTypeId();
    return Ui_PickListController.picklistValuesByRecordType(objAPIName, fieldName, recordTypeId);
  }
  @AuraEnabled
  public static EscalationTaskWrapper getEscalationTaskWrapper(String caseId) {
    return new EscalationTaskWrapper(caseId);
  }

  public class EscalationTaskWrapper {
    public String caseId;

    public EscalationTaskWrapper(String cId) {
      caseId = cId;
    }

    @AuraEnabled
    public String EscalationRecordType {
      get {
        return getGenericRecordTyeId('Task', 'Escalation');
      }
      set;
    }
    @AuraEnabled
    public Case caseObj {
      get {
        return [SELECT Id, CaseNumber, AccountId FROM Case WHERE id = :caseId];
      }
      set;
    }
    @AuraEnabled
    public String userId {
      get {
        return UserInfo.getUserId();
      }
      set;
    }
    @AuraEnabled
    public String queueId {
      get {
        return [
          SELECT Id, Type, DeveloperName, Name
          FROM Group
          WHERE DeveloperName = 'Escalations' AND Type = 'Queue'
        ][0]
        .Id;
      }
      set;
    }
  }
}