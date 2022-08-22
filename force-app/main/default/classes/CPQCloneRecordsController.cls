public with sharing class CPQCloneRecordsController {
  public class CPQCloneRecordsWrapper {
    @AuraEnabled
    public SObject record { get; set; }
    @AuraEnabled
    public List<String> childRelationLabels { get; set; }
  }

  @AuraEnabled
  public static CPQCloneRecordsWrapper getInitialData(String recordId, String objectApiName) {
    CPQCloneRecordsWrapper wrapper = new CPQCloneRecordsWrapper();

    if (objectApiName == 'Product2') {
      Product2 p = [
        SELECT
          Id,
          Name,
          Migration_ID__c,
          (SELECT Id, Migration_ID__c FROM SBQQ__ConfigurationAttributes__r),
          (SELECT Id, Migration_ID__c FROM SBQQ__ConfigurationRules__r),
          (SELECT Id, Migration_ID__c FROM SBQQ__Features__r),
          (SELECT Id, Migration_ID__c FROM SBQQ__Options__r),
          (SELECT Id FROM PricebookEntries)
        FROM Product2
        WHERE Id = :recordId
      ];
      List<String> childRelationLabels = new List<String>();
      childRelationLabels.add('Configuration Attributes (' + p.SBQQ__ConfigurationAttributes__r.size() + ')');
      childRelationLabels.add('Configuration Rules (' + p.SBQQ__ConfigurationRules__r.size() + ')');
      childRelationLabels.add('Product Features (' + p.SBQQ__Features__r.size() + ')');
      childRelationLabels.add('Product Options (' + p.SBQQ__Options__r.size() + ')');
      childRelationLabels.add('Pricebook Entries (' + p.PricebookEntries.size() + ')');

      wrapper.record = p;
      wrapper.childRelationLabels = childRelationLabels;
    }

    return wrapper;
  }

  @AuraEnabled
  public static String cloneAndSaveRecords(String migrationIdPrefix, String recordId, String objectApiName) {
    try {
      if (objectApiName == 'Product2') {
        Map<Id, SBQQ__ProductFeature__c> originalFeaturesMap = new Map<Id, SBQQ__ProductFeature__c>(
          [SELECT Id, Name FROM SBQQ__ProductFeature__c WHERE SBQQ__ConfiguredSKU__c = :recordId]
        );

        SObjectDeepClone cloner = new SObjectDeepClone(
          recordId,
          new Set<String>{
            'SBQQ__ConfigurationAttributes__r',
            'SBQQ__ConfigurationRules__r',
            'SBQQ__Features__r',
            'SBQQ__Options__r',
            'PricebookEntries'
          }
        );
        Product2 beforeClone = (Product2) cloner.clone;
        beforeClone.Migration_ID__c = migrationIdPrefix + '_PROD_' + new Uuid().getValue();
        beforeClone.Name = 'Copy ' + beforeClone.Name;
        beforeClone.NS_Item_Internal_ID__c = null;
        SObjectDeepClone.SaveResult result = cloner.save(true);

        for (String relationship : result.cloneChildren.keySet()) {
          for (SObject child : result.cloneChildren.get(relationship)) {
            // Process Product Options for mapping new Feature Ids
            if (relationship == 'SBQQ__OPTIONS__R') {
              Id ftrId = getNewFeatureId(
                String.valueOf(child.get('SBQQ__Feature__c')),
                result.cloneChildren.get('SBQQ__FEATURES__R'),
                originalFeaturesMap
              );
              child.put('SBQQ__Feature__c', ftrId);
            }

            String relString = relationship.replace('__r', '');
            relString = relString.replace('__R', '');
            relString = relString.replace('SBQQ__', '');
            child.put('Migration_ID__c', migrationIdPrefix + '_' + relString + '_' + new Uuid().getValue());
          }

          // DML in the loop : Inserting relationships one by one
          if (relationship == 'PRICEBOOKENTRIES') {
            // Insert standard pricebook entries
            Database.insert(result.cloneChildren.get(relationship), false);
            // Insert other pricebook entries
            Database.upsert(result.cloneChildren.get(relationship), false);
          } else {
            insert result.cloneChildren.get(relationship);
          }
        }

        return result.clone.Id;
      }
      return null;
    } catch (Exception e) {
      String error = e.getMessage() + ' ' + e.getStackTraceString();
      AuraHandledException ae = new AuraHandledException(error);
      ae.setMessage(error);
      throw ae;
    }
  }

  public static Id getNewFeatureId(
    Id clonedFeatureId,
    List<SObject> newFeatures,
    Map<Id, SBQQ__ProductFeature__c> originalFeaturesMap
  ) {
    if (originalFeaturesMap.containsKey(clonedFeatureId)) {
      SBQQ__ProductFeature__c originalFeature = originalFeaturesMap.get(clonedFeatureId);
      for (SObject newFeature : newFeatures) {
        if (String.valueOf(newFeature.get('Name')) == originalFeature.Name) {
          return String.valueOf(newFeature.get('Id'));
        }
      }
    }
    return null;
  }
}