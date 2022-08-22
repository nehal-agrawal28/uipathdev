/**
 * --
 * @date 2020
 *
 * @group CPQQuote
 * @group-content ../../ApexDocContent/CPQQuote.htm
 *
 * @description This Service class is used in the custom Guided selling solution. Primary purpose is to consolidate all the separate slave quotes into the primary.
 * The custom CPQ contract merge solution(which is part of the guided selling solution) produces N quotes. one for each pair of master slave contracts.
 * At the end of the process, the last quote (which will also be primary) is considered master. The contents of
 * the other slave quotes are merged into the master
 */
public with sharing class CPQQuoteClonerService {
  //make sure only lower case field names are used
  private static final Set<String> fieldExclusionList = new Set<String>{
    'sbqq__quote__c',
    'id',
    'lastvieweddate',
    'lastreferenceddate',
    'createdbyid',
    'createddate',
    'lastmodifieddate',
    'lastmodifiedbyid',
    'systemmodstamp',
    'isdeleted'
  };

  private static List<Schema.SObjectField> filterFieldsToCopy(Map<String, Schema.SObjectField> sObjectFields) {
    // Filter fields to copy
    List<Schema.SObjectField> eligibleFields = new List<Schema.SObjectField>();
    List<String> fieldNames = new List<String>(sObjectFields.keySet());
    fieldNames.sort();
    for (String fieldName : fieldNames) {
      Schema.SObjectField sObjectField = sObjectFields.get(fieldName);
      if (fieldExclusionList.contains(fieldName.toLowerCase())) {
        continue;
      }
      // Skip read only fields, such as auto numbers and formula fields
      Schema.DescribeFieldResult sObjectFieldDescribe = sObjectField.getDescribe();
      if (sObjectFieldDescribe.isAutoNumber() || sObjectFieldDescribe.isCalculated()) {
        continue;
      }

      eligibleFields.add(sObjectField);
    }
    return eligibleFields;
  }

  /**
   * @description Clones all lines into the master specified in one pass.
   * Be careful to split the slaves into multiple batches to avoid giv limits issues
   *
   * @param masterQuoteId target quote where lines are cloned into
   * @param slaveQuoteIds source quotes for lines
   * @return List of cloned lines
   */
  public static List<SBQQ__QuoteLine__c> cloneLinesIntoMasterQuote(Id masterQuoteId, Set<Id> slaveQuoteIds) {
    Schema.DescribeSObjectResult sObjectDesc = SBQQ__QuoteLine__c.SObjectType.getDescribe(
      SObjectDescribeOptions.DEFERRED
    );

    Map<String, Schema.SObjectField> sObjectFields = sObjectDesc.fields.getMap();

    List<Schema.SObjectField> sObjectFieldsToCopy = filterFieldsToCopy(sObjectFields);

    // Query records to copy
    String fieldList = null;
    for (Schema.SObjectField sObjectField : sObjectFieldsToCopy) {
      fieldList = fieldList == null
        ? sObjectField.getDescribe().getName()
        : fieldList + ',' + sObjectField.getDescribe().getName();
    }

    List<Id> subIds = getSubscriptionIds(masterQuoteId);

    String query = String.format(
      'select {0} from SBQQ__QuoteLine__c where SBQQ__Quote__c in :slaveQuoteIds and SBQQ__RenewedSubscription__c not in :subIds order by Name',
      new List<String>{ fieldList }
    );

    Map<Id, SObject> linesToCopyById = new Map<Id, SObject>(Database.query(query));
    if (linesToCopyById.size() == 0) {
      return new List<SBQQ__QuoteLine__c>();
    }

    SBQQ__Quote__c masterQuote = [SELECT Id FROM SBQQ__Quote__c WHERE Id = :masterQuoteId];

    List<SBQQ__QuoteLine__c> clonedQuoteLines = new List<SBQQ__QuoteLine__c>();

    for (SBQQ__QuoteLine__c line : (List<SBQQ__QuoteLine__c>) linesToCopyById.values()) {
      SBQQ__QuoteLine__c clonedLine = new SBQQ__QuoteLine__c(SBQQ__Quote__c = masterQuote.Id);
      for (Schema.SObjectField sObjectField : sObjectFieldsToCopy) {
        clonedLine.put(sObjectField.getDescribe().getName(), line.get(sObjectField.getDescribe().getName()));
      }
      clonedQuoteLines.add(clonedLine);
    }

    //disable CPQ triggers as they can cause limits issues. We will make them run separately by invoking Calculate API
    SBQQ.TriggerControl.disable();
    insert clonedQuoteLines;
    SBQQ.TriggerControl.enable();

    return clonedQuoteLines;
  }

  private static List<Id> getSubscriptionIds(Id masterQuoteId) {
    List<SBQQ__QuoteLine__c> subsLines = [
      SELECT SBQQ__RenewedSubscription__c
      FROM SBQQ__QuoteLine__c
      WHERE SBQQ__Quote__c = :masterQuoteId
    ];
    List<Id> subIds = new List<Id>();
    for (SBQQ__QuoteLine__c subsLine : subsLines) {
      subIds.add(subsLine.SBQQ__RenewedSubscription__c);
    }

    return subIds;
  }
}