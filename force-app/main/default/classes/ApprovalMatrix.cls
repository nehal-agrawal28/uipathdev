/**
 * Represents the Domain for Approval Matrix
 * 1.0 Girish Lakshmanan 23/08/2019 Initial Version
 *
 * @author Girish Lakshmanan
 * @date 23/08/2019
 *
 */

public with sharing class ApprovalMatrix {
  public List<ApprovalRuleMatrix__c> records { get; private set; }

  public static ApprovalMatrix newInstance(List<ApprovalRuleMatrix__c> sObjectList) {
    return new ApprovalMatrix(sObjectList);
  }

  public ApprovalMatrix(List<ApprovalRuleMatrix__c> sObjectList) {
    this.records = sObjectList;
  }

  public void generate(ApprovalRuleServiceFactory.ApprovalRuleFactory approvalRuleFactory) {
    for (ApprovalRuleMatrix__c matrixRecord : records) {
      approvalRuleFactory.add(matrixRecord);
    }
  }

  public static ApprovalMatrix newInstanceFor(List<Id> ids, Schema.FieldSet fieldSet) {
    String query = 'SELECT ';
    for (Schema.FieldSetMember field : fieldSet.getFields()) {
      query += field.getFieldPath() + ', ';
    }
    query +=
      'Id, ' +
      'Active__c, ' +
      'ApprovalRule__c, ' +
      'Name, ' +
      'ApprovalStep__c, ' +
      'Description__c, ' +
      'DynamicApproverField__c, ' +
      'Migration_ID__c, ' +
      'MD5Hash__c, ' +
      'StaticApprover__c, ' +
      'SyncMessage__c, ' +
      'SyncStatus__c, ' +
      'ApprovalChain__c, ' +
      'StaticApprover__r.name ' +
      ' FROM ApprovalRuleMatrix__c ' +
      'WHERE Id  in :ids ';

    return new ApprovalMatrix(Database.query(query));
  }

  /**
   * Get Query Locator for Approval Rule Generation Pending records
   *
   * @return
   */
  public static Database.QueryLocator getQueryLocator(List<String> statuses) {
    String query = 'SELECT ';
    for (
      Schema.FieldSetMember field : Schema.SObjectType.ApprovalRuleMatrix__c.fieldSets.ConditionsMapFields.getFields()
    ) {
      query += field.getFieldPath() + ', ';
    }
    query +=
      'Id, ' +
      'Active__c, ' +
      'ApprovalRule__c, ' +
      'Name, ' +
      'ApprovalStep__c, ' +
      'Description__c, ' +
      'DynamicApproverField__c, ' +
      'Migration_ID__c, ' +
      'MD5Hash__c, ' +
      'StaticApprover__c, ' +
      'SyncMessage__c, ' +
      'SyncStatus__c, ' +
      'ApprovalChain__c, ' +
      'StaticApprover__r.name ' +
      ' FROM ApprovalRuleMatrix__c ' +
      'WHERE SyncStatus__c in :statuses';

    return Database.getQueryLocator(query);
  }

  /**
   * generate MD5Hash from Approval Rule Matrix record
   * @param ApprovalRuleMatrix__c sObject
   * @return MD5 Hash string
   */
  public static String generateMatrixMD5Hash(ApprovalRuleMatrix__c matrix) {
    Set<String> fieldList = new Set<String>();
    fieldList.add('Active__c');
    fieldList.add('ApprovalChain__c');
    fieldList.add('Name');
    fieldList.add('StaticApprover__c');
    fieldList.add('ApprovalStep__c');
    fieldList.add('Description__c');
    fieldList.add('DynamicApproverField__c');
    fieldList.add('Migration_ID__c');

    //add ConditionsMapFields fieldset fields
    Map<String, Schema.FieldSet> fieldSetMap = SObjectType.ApprovalRuleMatrix__c.FieldSets.getMap();
    if (fieldSetMap.containsKey('ConditionsMapFields')) {
      for (Schema.FieldSetMember fieldMember : fieldSetMap.get('ConditionsMapFields').getFields()) {
        fieldList.add(fieldMember.getFieldPath());
      }
    }

    ApprovalRuleMatrix__c tempObj = new ApprovalRuleMatrix__c();
    for (String field : fieldList) {
      tempObj.put(field, matrix.get(field));
    }

    return getMD5Hash(JSON.serialize(tempObj));
  }

  public static String getMD5Hash(String jsonString) {
    Blob criteriaBlob = Blob.valueOf(jsonString);
    Blob hash = Crypto.generateDigest('MD5', criteriaBlob);
    String md5Hash = EncodingUtil.convertToHex(hash);
    System.debug('** MD5Hash' + md5Hash);
    return md5Hash;
  }
}