/**================================================================
 * Appirio, Inc
 * Name: ApprovalRuleMatrixManagerController
 * Description: Controller class for ApprovalRuleMatrixManager LWC
 * Created Date: 26-Aug-2019
 * Created By: Raghu Rankawat (Appirio)
 *
 * Date Modified      Modified By      Description of the update
 *
 ==================================================================*/

public with sharing class ApprovalRuleMatrixManagerController {
  public class ApprovalRuleMatrixManagerWrapper {
    @AuraEnabled
    public List<ApprovalRuleMatrix__c> matrixList { get; set; }
    @AuraEnabled
    public List<ApproverWrapper> approverList { get; set; }
    @AuraEnabled
    public List<FieldSetFieldWrapper> criteriaFieldList { get; set; }
    @AuraEnabled
    public List<FieldSetFieldWrapper> ruleGenerationUIFieldList { get; set; }
    @AuraEnabled
    public Boolean isSandbox { get; set; }
  }

  public class ApproverWrapper {
    @AuraEnabled
    public String label { get; set; }
    @AuraEnabled
    public String value { get; set; }
    @AuraEnabled
    public String type { get; set; }
    @AuraEnabled
    public Boolean isStaticApprover { get; set; }

    public ApproverWrapper(String label, String value, String type, Boolean isStaticApprover) {
      this.label = label;
      this.value = value;
      this.type = type;
      this.isStaticApprover = isStaticApprover;
    }
  }

  public class FieldSetFieldWrapper {
    @AuraEnabled
    public String fieldAPI { get; set; }
    @AuraEnabled
    public String fieldType { get; set; }

    public FieldSetFieldWrapper(String fieldAPI, String fieldType) {
      this.fieldAPI = fieldAPI;
      this.fieldType = fieldType;
    }
  }

  /**
   * fetch data on LWC component load
   */
  @AuraEnabled
  public static ApprovalRuleMatrixManagerWrapper getInitialData() {
    ApprovalRuleMatrixManagerWrapper wrapper = new ApprovalRuleMatrixManagerWrapper();

    wrapper.isSandbox = [SELECT TrialExpirationDate, IsSandbox FROM Organization LIMIT 1].IsSandbox;

    //fetch matrix records
    wrapper.matrixList = getMatrixList(null, null);

    //fetch approver list
    Map<String, String> staticApproverNameIdMap = new Map<String, String>();
    wrapper.approverList = new List<ApproverWrapper>();
    for (Approver_Mapping__mdt mapping : [
      SELECT
        Id,
        DeveloperName,
        MasterLabel,
        Dynamic_Approver_Field_API__c,
        Dynamic_Approver_Role__c,
        Static_Approver_Name__c,
        Type__c
      FROM Approver_Mapping__mdt
      ORDER BY Type__c ASC, Static_Approver_Name__c ASC, Dynamic_Approver_Role__c ASC
    ]) {
      if (mapping.Type__c == 'Static Approver') {
        wrapper.approverList.add(new ApproverWrapper(mapping.Static_Approver_Name__c, '', 'Static Approver', true));
        staticApproverNameIdMap.put(mapping.Static_Approver_Name__c, '');
      } else if (mapping.Type__c == 'Dynamic Approver') {
        wrapper.approverList.add(
          new ApproverWrapper(
            mapping.Dynamic_Approver_Role__c,
            mapping.Dynamic_Approver_Field_API__c,
            'Dynamic Approver',
            false
          )
        );
      }
    }

    if (!staticApproverNameIdMap.isEmpty()) {
      for (sbaa__Approver__c sbaa_approver : [
        SELECT Id, Name
        FROM sbaa__Approver__c
        WHERE Name IN :staticApproverNameIdMap.keyset()
      ]) {
        staticApproverNameIdMap.put(sbaa_approver.Name, sbaa_approver.Id);
      }

      for (ApproverWrapper approver : wrapper.approverList) {
        if (approver.type == 'Static Approver') {
          approver.value = staticApproverNameIdMap.get(approver.label);
        }
      }
    }

    //fetch fields API name from ConditionsMapFields FieldSet
    wrapper.criteriaFieldList = new List<FieldSetFieldWrapper>();
    for (FieldSetMember fm : SObjectType.ApprovalRuleMatrix__c.FieldSets.ConditionsMapFields.getFields()) {
      wrapper.criteriaFieldList.add(new FieldSetFieldWrapper(fm.getFieldPath(), fm.getType() + ''));
    }

    //fetch fields API name from RuleGenerationUIFields FieldSet
    wrapper.ruleGenerationUIFieldList = new List<FieldSetFieldWrapper>();
    for (FieldSetMember fm : SObjectType.ApprovalRuleMatrix__c.FieldSets.RuleGenerationUIFields.getFields()) {
      wrapper.ruleGenerationUIFieldList.add(new FieldSetFieldWrapper(fm.getFieldPath(), fm.getType() + ''));
    }

    return wrapper;
  }

  /**
   * fetch filtered Matrix record list
   */
  @AuraEnabled
  public static List<ApprovalRuleMatrix__c> getMatrixList(String filterCondition, String orderByCondition) {
    String query = getInitialMatrixQuery();

    if (String.isNotBlank(filterCondition)) {
      query += ' WHERE Id != null ' + filterCondition;
    }

    if (String.isNotBlank(orderByCondition)) {
      query += ' ORDER BY ' + orderByCondition;
    } else {
      query += ' ORDER BY SyncStatus__c ASC, Name ASC';
    }

    query += ' LIMIT 2000';

    System.debug('** getMatrixList query: ' + query);

    return Database.query(query);
  }

  /**
   * fetch specific Matrix record
   */
  @AuraEnabled
  public static ApprovalRuleMatrix__c getSingleMatrixrRecord(String matrixRecId) {
    String query = getInitialMatrixQuery();
    query += ' WHERE Id = \'' + matrixRecId + '\'';
    return Database.query(query);
  }

  @AuraEnabled
  public static ApprovalRuleMatrix__c toggleMatrixAndRuleStatus(String matrixRecId) {
    try {
      String query = getInitialMatrixQuery();
      query += ' WHERE Id = \'' + matrixRecId + '\'';
      ApprovalRuleMatrix__c matrix = Database.query(query);

      sbaa__ApprovalRule__c rule = new sbaa__ApprovalRule__c();
      rule.Id = matrix.ApprovalRule__c;
      rule.sbaa__Active__c = !matrix.Active__c;
      update rule;

      matrix.Active__c = !matrix.Active__c;
      matrix.SyncStatus__c = 'Processed';
      update matrix;

      return matrix;
    } catch (Exception e) {
      System.debug('Exception:' + e.getMessage() + ' StackTrace:' + e.getStackTraceString());
      if (e.getTypeName() == 'System.DmlException') {
        throw new AuraHandledException(e.getDmlMessage(0));
      } else {
        throw new AuraHandledException(e.getMessage());
      }
    }
  }

  /**
   * @return query string with all required matrix fields
   */
  public static String getInitialMatrixQuery() {
    return 'SELECT Id, Name, Active__c, ApprovalChain__c, ApprovalChain__r.Name, ApprovalRule__c, ApprovalRule__r.Name, ApprovalStep__c,' +
      ' Migration_ID__c, DynamicApproverField__c, StaticApprover__c, StaticApprover__r.Name, SyncStatus__c, Deployed_To_Production__c' +
      ' FROM ApprovalRuleMatrix__c';
  }

  /**
   * generate Approval Rule record using Matrix record
   */
  @AuraEnabled
  public static ApprovalRuleMatrix__c generateRule(String matrixRecId) {
    try {
      List<Id> approvalRuleIdList = ApprovalRuleServiceFactory.generate(new List<Id>{ matrixRecId });

      ApprovalRuleMatrix__c matrixRec = new ApprovalRuleMatrix__c(Id = matrixRecId);
      matrixRec.ApprovalRule__c = approvalRuleIdList[0];
      matrixRec.SyncStatus__c = 'Processed';
      matrixRec.SyncMessage__c = '';
      update matrixRec;
    } catch (Exception e) {
      System.debug('Exception:' + e.getMessage() + ' StackTrace:' + e.getStackTraceString());
      ApprovalRuleMatrix__c matrixRec = new ApprovalRuleMatrix__c(Id = matrixRecId);
      matrixRec.SyncStatus__c = 'Error';
      matrixRec.SyncMessage__c = 'Exception: ' + e.getMessage() + '\n\nStackTrace: ' + e.getStackTraceString();
      update matrixRec;
    }

    //query to get Rule Name and other fields
    ApprovalRuleMatrix__c updatedMatrixRec = [
      SELECT Id, ApprovalRule__c, ApprovalRule__r.Name, SyncMessage__c, SyncStatus__c
      FROM ApprovalRuleMatrix__c
      WHERE Id = :matrixRecId
    ];
    return updatedMatrixRec;
  }

  /**
   * save Approval Rule Matrix record
   */
  @AuraEnabled
  public static ApprovalRuleMatrix__c saveMatrixRule(String matrixRecString) {
    try {
      System.debug('** matrixRecString' + matrixRecString);
      ApprovalRuleMatrix__c matrixRec = (ApprovalRuleMatrix__c) JSON.deserialize(
        matrixRecString,
        ApprovalRuleMatrix__c.class
      );
      System.debug('** matrixRec' + matrixRec);

      update matrixRec;

      return ApprovalRuleMatrixManagerController.getSingleMatrixrRecord(matrixRec.Id);
    } catch (Exception e) {
      System.debug('Exception:' + e.getMessage() + ' StackTrace:' + e.getStackTraceString());
      if (e.getTypeName() == 'System.DmlException') {
        throw new AuraHandledException(e.getDmlMessage(0));
      } else {
        throw new AuraHandledException(e.getMessage());
      }
    }
  }

  /**
   * delete Approval Matrix records without generated Approval Rule
   */
  @AuraEnabled
  public static void deleteMatrixRecords(List<String> matrixIdList) {
    try {
      List<ApprovalRuleMatrix__c> deleteRuleList = new List<ApprovalRuleMatrix__c>();
      for (String matrixId : matrixIdList) {
        deleteRuleList.add(new ApprovalRuleMatrix__c(Id = matrixId));
      }

      delete deleteRuleList;
    } catch (Exception e) {
      System.debug('Exception:' + e.getMessage() + ' StackTrace:' + e.getStackTraceString());
      if (e.getTypeName() == 'System.DmlException') {
        throw new AuraHandledException(e.getDmlMessage(0));
      } else {
        throw new AuraHandledException(e.getMessage());
      }
    }
  }
}