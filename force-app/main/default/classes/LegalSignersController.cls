public without sharing class LegalSignersController {
  public class LegalSignersWrapper {
    @AuraEnabled
    public Boolean disalbeEdit { get; set; }
    @AuraEnabled
    public Boolean disalbeEditEntity { get; set; }
    @AuraEnabled
    public List<Signers> signers { get; set; }
    @AuraEnabled
    public List<Entity> entities { get; set; }
    @AuraEnabled
    public Case caseRecord { get; set; }
  }

  public class Signers {
    @AuraEnabled
    public String metadataId { get; set; }
    @AuraEnabled
    public String title { get; set; }
    @AuraEnabled
    public String name { get; set; }
    @AuraEnabled
    public String country { get; set; }
    @AuraEnabled
    public String address { get; set; }
    @AuraEnabled
    public String entity { get; set; }

    public Signers(String metadataId, String title, String name, String country, String address, String entity) {
      this.metadataId = metadataId;
      this.title = title;
      this.name = name;
      this.country = country;
      this.address = address;
      this.entity = entity;
    }
  }

  public class Entity {
    @AuraEnabled
    public String label { get; set; }
    @AuraEnabled
    public String value { get; set; }

    public Entity(String label, String value) {
      this.label = label;
      this.value = value;
    }
  }

  @AuraEnabled
  public static LegalSignersWrapper getSignerData(String caseId) {
    try {
      LegalSignersWrapper wrapper = new LegalSignersWrapper();
      wrapper.disalbeEditEntity = !Schema.sObjectType.Case.fields.UiPath_Signing_Entity__c.isUpdateable();

      if (
        !Schema.sObjectType.Case.fields.UiPath_Signer_Name__c.isUpdateable() ||
        !Schema.sObjectType.Case.fields.UiPath_Signer_Title__c.isUpdateable() ||
        !Schema.sObjectType.Case.fields.UiPath_Signing_Entity_Address__c.isUpdateable()
      ) {
        wrapper.disalbeEdit = true;
      }

      wrapper.caseRecord = [
        SELECT
          Id,
          UiPath_Signing_Entity__c,
          UiPath_Signer_Title__c,
          UiPath_Signer_Name__c,
          UiPath_Signer_Name__r.Name,
          UiPath_Signing_Entity_Address__c,
          RecordTypeId,
          RecordType.DeveloperName
        FROM Case
        WHERE Id = :caseId
      ];

      wrapper.signers = buildSignerList(wrapper);

      wrapper.entities = new List<Entity>();
      for (String entity : getUniqueEntities(wrapper)) {
        wrapper.entities.add(new Entity(entity, entity));
      }

      return wrapper;
    } catch (Exception e) {
      String error = e.getMessage() + ' ' + e.getStackTraceString();
      AuraHandledException ae = new AuraHandledException(error);
      ae.setMessage(error);
      throw ae;
    }
  }

  private static List<Signers> buildSignerList(LegalSignersWrapper wrapper) {
    List<Signers> signers = new List<Signers>();
    List<String> uniqueSigners = new List<String>();
    for (Legal_Signers__mdt mdt : CaseMetadata_SL.LegalSigners) {
      if (String.isBlank(mdt.Signer_Name__c) && String.isBlank(mdt.Legal_Product_Signer_Name__c)) {
        continue;
      }

      if (wrapper.caseRecord.RecordTypeId == CaseMetadata_SL.LegalProductRequestRecordType) {
        // To allow unique signers only
        String uniqueKey = mdt.Legal_Product_Signer_Name__c + mdt.Legal_Product_Signing_Entity__c;
        if (uniqueSigners.contains(uniqueKey)) {
          continue;
        }
        uniqueSigners.add(uniqueKey);
        signers.add(
          new Signers(
            mdt.Id,
            mdt.Legal_Product_Signer_Title__c,
            mdt.Legal_Product_Signer_Name__c,
            mdt.Country__c,
            mdt.Legal_Product_Signing_Entity_Address__c,
            mdt.Legal_Product_Signing_Entity__c
          )
        );
      } else if (wrapper.caseRecord.RecordTypeId == CaseMetadata_SL.LegalRequestRecordType) {
        // To allow unique signers only
        String uniqueKey = mdt.Signer_Name__c + mdt.Signing_Entity__c;
        if (uniqueSigners.contains(uniqueKey)) {
          continue;
        }
        uniqueSigners.add(uniqueKey);
        signers.add(
          new Signers(
            mdt.Id,
            mdt.Signer_Title__c,
            mdt.Signer_Name__c,
            mdt.Country__c,
            mdt.Signing_Entity_Address__c,
            mdt.Signing_Entity__c
          )
        );
      }
    }
    return signers;
  }

  private static Set<String> getUniqueEntities(LegalSignersWrapper wrapper) {
    Set<String> uniqueEntities = new Set<String>();
    for (Legal_Signers__mdt mdt : CaseMetadata_SL.LegalSigners) {
      if (wrapper.caseRecord.RecordTypeId == CaseMetadata_SL.LegalProductRequestRecordType) {
        uniqueEntities.add(mdt.Legal_Product_Signing_Entity__c);
      } else if (wrapper.caseRecord.RecordTypeId == CaseMetadata_SL.LegalRequestRecordType) {
        uniqueEntities.add(mdt.Signing_Entity__c);
      }
    }
    return uniqueEntities;
  }

  @AuraEnabled
  public static void saveSignerData(String caseId, String entityName, String metadataId) {
    try {
      Case cs = [
        SELECT
          Id,
          UiPath_Signing_Entity__c,
          UiPath_Signer_Title__c,
          UiPath_Signer_Name__c,
          UiPath_Signer_Name__r.Name,
          UiPath_Signing_Entity_Address__c,
          RecordTypeId,
          RecordType.DeveloperName
        FROM Case
        WHERE Id = :caseId
      ];

      Legal_Signers__mdt mdt = Legal_Signers__mdt.getInstance(metadataId);

      cs.UiPath_Signing_Entity__c = entityName;
      if (cs.RecordTypeId == CaseMetadata_SL.LegalProductRequestRecordType) {
        String signerName = mdt.Legal_Product_Signer_Name__c;
        if (!CaseMetadata_SL.SignerNameToUserIdMap.containsKey(signerName)) {
          throw new CustomException(
            'User ' +
            signerName +
            ' was not found. Please contact your salesforce administrator.'
          );
        }
        cs.UiPath_Signer_Name__c = CaseMetadata_SL.SignerNameToUserIdMap.get(signerName);
        cs.UiPath_Signer_Title__c = mdt.Legal_Product_Signer_Title__c;
        cs.UiPath_Signing_Entity__c = mdt.Legal_Product_Signing_Entity__c;
        cs.UiPath_Signing_Entity_Address__c = mdt.Legal_Product_Signing_Entity_Address__c;
      } else if (cs.RecordTypeId == CaseMetadata_SL.LegalRequestRecordType) {
        String signerName = mdt.Signer_Name__c;
        if (!CaseMetadata_SL.SignerNameToUserIdMap.containsKey(signerName)) {
          throw new CustomException(
            'User ' +
            signerName +
            ' was not found. Please contact your salesforce administrator.'
          );
        }
        cs.UiPath_Signer_Name__c = CaseMetadata_SL.SignerNameToUserIdMap.get(signerName);
        cs.UiPath_Signer_Title__c = mdt.Signer_Title__c;
        cs.UiPath_Signing_Entity__c = mdt.Signing_Entity__c;
        cs.UiPath_Signing_Entity_Address__c = mdt.Signing_Entity_Address__c;
      }
      update cs;
    } catch (CustomException e) {
      String error = e.getMessage();
      AuraHandledException ae = new AuraHandledException(error);
      ae.setMessage(error);
      throw ae;
    } catch (Exception e) {
      String error = e.getMessage() + ' ' + e.getStackTraceString();
      AuraHandledException ae = new AuraHandledException(error);
      ae.setMessage(error);
      throw ae;
    }
  }

  public class CustomException extends Exception {
  }
}