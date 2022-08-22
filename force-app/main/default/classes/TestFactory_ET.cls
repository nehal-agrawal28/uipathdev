/**
 * @AUTHOR: UIPath
 * @DATE: 01/10/2021
 * @DESCRIPTION: This class is used to setupdata for test class
 */
@IsTest(isParallel=true)
public class TestFactory_ET {
  private static Id territoryModelId;

  public static void init(String namedListAssignment) {
    List<Account> accList = createAccounts(1, 'Customer', namedListAssignment, true);
    List<Opportunity> oppList = createOpportunities(1, accList[0].Id, 'CPQ_Default', true);
  }

  public static Territory2 initTerritory(String geo, String area, String region) {
    Id objTerrModelId = getActiveTerritoryModelId();
    Territory2Type objTerrType = [SELECT Id, DeveloperName FROM Territory2Type LIMIT 1];

    Territory2 geoTerritory = new Territory2();
    geoTerritory.AccountAccessLevel = 'Edit';
    geoTerritory.CaseAccessLevel = 'Read';
    geoTerritory.Name = geo;
    geoTerritory.DeveloperName = geo;
    geoTerritory.Territory2ModelId = objTerrModelId;
    geoTerritory.Territory2TypeId = objTerrType.Id;
    geoTerritory.Ultimate_Geo__c = geo;
    geoTerritory.Sales_Geo__c = true;
    insert geoTerritory;

    Territory2 areaTerritory = new Territory2();
    areaTerritory.AccountAccessLevel = 'Edit';
    areaTerritory.CaseAccessLevel = 'Read';
    areaTerritory.Name = area;
    areaTerritory.DeveloperName = area.replace(' ', '_');
    areaTerritory.Territory2ModelId = objTerrModelId;
    areaTerritory.Territory2TypeId = objTerrType.Id;
    areaTerritory.Ultimate_Geo__c = geo;
    areaTerritory.Area__c = area;
    areaTerritory.Sales_Area__c = true;
    areaTerritory.ParentTerritory2Id = geoTerritory.Id;
    insert areaTerritory;

    Territory2 regionTerritory = new Territory2();
    regionTerritory.AccountAccessLevel = 'Edit';
    regionTerritory.CaseAccessLevel = 'Read';
    regionTerritory.Name = region;
    regionTerritory.DeveloperName = region.replace(' ', '_');
    regionTerritory.Territory2ModelId = objTerrModelId;
    regionTerritory.Territory2TypeId = objTerrType.Id;
    regionTerritory.Ultimate_Geo__c = geo;
    regionTerritory.Area__c = area;
    regionTerritory.Region__c = region;
    regionTerritory.Sales_Region__c = true;
    regionTerritory.Sales_Area__c = false;
    regionTerritory.ParentTerritory2Id = areaTerritory.Id;
    insert regionTerritory;

    return regionTerritory;
  }

  public static Territory2 createSalesTerritory(Territory2 parentTerritory, String salesTerritoryName) {
    Territory2 salesTerritory = new Territory2();
    salesTerritory.AccountAccessLevel = 'Edit';
    salesTerritory.OpportunityAccessLevel = 'Edit';
    salesTerritory.CaseAccessLevel = 'Read';
    salesTerritory.Name = salesTerritoryName;
    salesTerritory.DeveloperName = salesTerritoryName.replace(' ', '_');
    salesTerritory.Territory2ModelId = parentTerritory.Territory2ModelId;
    salesTerritory.Ultimate_Geo__c = parentTerritory.Ultimate_Geo__c;
    salesTerritory.Region__c = parentTerritory.Region__c;
    salesTerritory.Area__c = parentTerritory.Area__c;
    salesTerritory.Sales_Territory__c = true;
    salesTerritory.Sales_Area__c = false;
    salesTerritory.Territory2TypeId = parentTerritory.Territory2TypeID;
    insert salesTerritory;
    return salesTerritory;
  }

  public static Territory2 createNonSalesTerritory(
    Territory2 parentTerritory,
    String salesTerritoryName,
    Boolean isInsert
  ) {
    Territory2 NonsalesTerritory = new Territory2();
    NonsalesTerritory.AccountAccessLevel = 'Edit';
    NonsalesTerritory.OpportunityAccessLevel = 'Edit';
    NonsalesTerritory.CaseAccessLevel = 'Read';
    NonsalesTerritory.Name = salesTerritoryName;
    NonsalesTerritory.DeveloperName = salesTerritoryName.replace(' ', '_');
    NonsalesTerritory.Territory2ModelId = parentTerritory.Territory2ModelId;
    NonsalesTerritory.Ultimate_Geo__c = parentTerritory.Ultimate_Geo__c;
    NonsalesTerritory.Region__c = parentTerritory.Region__c;
    NonsalesTerritory.Area__c = parentTerritory.Area__c;
    NonsalesTerritory.Sales_Territory__c = false;
    NonsalesTerritory.Territory2TypeId = parentTerritory.Territory2TypeID;
    if (isInsert) {
      insert NonsalesTerritory;
    }
    return NonsalesTerritory;
  }
  public static Territory2 createSalesTerritory(
    Territory2 parentTerritory,
    String salesTerritoryName,
    boolean isInsert
  ) {
    Territory2 salesTerritory = new Territory2();
    salesTerritory.AccountAccessLevel = 'Edit';
    salesTerritory.OpportunityAccessLevel = 'Edit';
    salesTerritory.CaseAccessLevel = 'Read';
    salesTerritory.Name = salesTerritoryName;
    salesTerritory.DeveloperName = salesTerritoryName.replace(' ', '_');
    salesTerritory.Territory2ModelId = parentTerritory.Territory2ModelId;
    salesTerritory.Ultimate_Geo__c = parentTerritory.Ultimate_Geo__c;
    salesTerritory.Region__c = parentTerritory.Region__c;
    salesTerritory.Area__c = parentTerritory.Area__c;
    salesTerritory.Sales_Territory__c = true;
    salesTerritory.Territory2TypeId = parentTerritory.Territory2TypeID;
    if (isInsert) {
      insert salesTerritory;
    }
    return salesTerritory;
  }

  public static List<Account> createAccounts(
    Integer count,
    String recordTypeName,
    String namedListAssignment,
    Boolean insertFlag
  ) {
    List<Account> accountList = new List<Account>();
    Id recordTypeId = Schema.SobjectType.Account.getRecordTypeInfosByDeveloperName()
      .get(recordTypeName)
      .getRecordTypeId();
    for (Integer i = 0; i < count; i++) {
      accountList.add(
        new Account(
          Industry = 'Engineering',
          BillingCountry = 'United States',
          BillingPostalCode = '012345',
          Name = EncodingUtil.convertToHex(Crypto.generateAesKey(256)).substring(0, 32) + i,
          Named_List_Assignment__c = namedListAssignment,
          RecordTypeId = recordTypeId
        )
      );
    }
    if (insertFlag) {
      insert accountList;
    }
    return accountList;
  }

  public static List<Opportunity> createOpportunities(
    Integer count,
    Id accountId,
    String recordTypeName,
    Boolean insertFlag
  ) {
    List<Opportunity> oppList = new List<Opportunity>();
    Id recordTypeId = Schema.SobjectType.Opportunity.getRecordTypeInfosByDeveloperName()
      .get(recordTypeName)
      .getRecordTypeId();
    for (Integer i = 0; i < count; i++) {
      Opportunity newOpportunity = new Opportunity();
      newOpportunity.AccountId = accountId;
      newOpportunity.Name = 'Test ETM Opportunity ' + i;
      newOpportunity.StageName = 'Discovery';
      newOpportunity.CloseDate = System.today();
      newOpportunity.Deal_Type__c = 'BPO';
      newOpportunity.Type = 'Upsell';
      newOpportunity.RecordTypeId = recordTypeId;
      oppList.add(newOpportunity);
    }
    if (insertFlag) {
      insert oppList;
    }
    return oppList;
  }

  public static UserTerritory2Association assignPrimaryAccountManager(String territoryId) {
    List<UserTerritory2Association> assList = [
      SELECT Id, UserId
      FROM UserTerritory2Association
      WHERE
        Territory2Id = :territoryId
        AND RoleInTerritory2 IN (:ETMConstant.PRIMARY_ACCOUNT_MANAGER, :ETMConstant.PRIMARY_TEMPORARY_ABSENCE)
    ];
    UserTerritory2Association userAssociation;
    if (assList.size() == 0) {
      userAssociation = new UserTerritory2Association();
      userAssociation.UserId = Userinfo.getUserId();
      userAssociation.Territory2Id = territoryId;
      userAssociation.RoleInTerritory2 = ETMConstant.PRIMARY_ACCOUNT_MANAGER;
      insert userAssociation;
    } else {
      userAssociation = assList[0];
    }
    return userAssociation;
  }

  public static UserTerritory2Association createUserTerritoryAssociation(
    String territoryId,
    Id userId,
    String roleInTerritory
  ) {
    List<UserTerritory2Association> assList = [
      SELECT Id, UserId
      FROM UserTerritory2Association
      WHERE Territory2Id = :territoryId AND RoleInTerritory2 = :roleInTerritory
    ];
    UserTerritory2Association userAssociation;
    if (assList.size() == 0) {
      userAssociation = new UserTerritory2Association();
      userAssociation.UserId = userId;
      userAssociation.Territory2Id = territoryId;
      userAssociation.RoleInTerritory2 = roleInTerritory;
      insert userAssociation;
    } else {
      userAssociation = assList[0];
    }
    return userAssociation;
  }

  public static Id getActiveTerritoryModelId() {
    if (territoryModelId == null) {
      List<Territory2Model> modelList = [SELECT id FROM Territory2Model WHERE State = :ETMConstant.ACTIVE_STATE];
      if (modelList.size() > 0) {
        territoryModelId = modelList[0].Id;
      } else {
        Territory2Model model = new Territory2Model(
          Name = 'Test Territory Model',
          DeveloperName = 'Test_Territory_model'
        );
        insert model;
        territoryModelId = model.Id;
      }
    }
    return territoryModelId;
  }

  public static Territory2 getTerritoryId(String territoryName) {
    List<Territory2> terrList = [
      SELECT Id, Territory2ModelId, Ultimate_Geo__c, Name, Region__c, Area__c, Territory2TypeId
      FROM Territory2
      WHERE Name = :territoryName
    ];
    if (terrList.size() > 0) {
      return terrList[0];
    } else {
      Territory2Type objTerrType = [SELECT Id, DeveloperName FROM Territory2Type LIMIT 1];
      Territory2 terr2 = new Territory2(
        Name = territoryName,
        Territory2ModelId = getActiveTerritoryModelId(),
        Territory2TypeId = objTerrType.id,
        DeveloperName = territoryName.replace(' ', '_')
      );
      insert terr2;
      return terr2;
    }
  }

  public static void createTerritoryPostalCodeMapping(Map<String, String> postCodeTerritoryMap, boolean isTerr2) {
    List<Territory_Postal_Code_Mapping__c> terrMappingList = new List<Territory_Postal_Code_Mapping__c>();
    for (String postCode : postCodeTerritoryMap.keySet()) {
      Territory_Postal_Code_Mapping__c mapping = new Territory_Postal_Code_Mapping__c();
      String territory = postCodeTerritoryMap.get(postCode);
      String[] terrmap = postCode.split('-');
      mapping.Country_Code__c = terrmap[0];
      mapping.Postal_Code__c = terrmap[1];
      mapping.Territory_2__c = territory;
      mapping.Territory_1__c = territory;
      mapping.External_Id__c = postCode;
      terrMappingList.add(mapping);
    }
    insert terrMappingList;
  }

  public static void deleteAllUserTerritoryAssociation() {
    Database.delete([SELECT Id FROM UserTerritory2Association], false);
  }

  public static Partner_Involvement__c createPartnerInvolvement(Id oppId, String salesRole, Boolean isInsert) {
    Partner_Involvement__c record = new Partner_Involvement__c();
    record.Partner_Role__c = 'Reseller';
    record.CurrencyIsoCode = 'USD';
    record.PartnerOpp_Name__c = oppId;
    record.Selection_Status__c = 'preferred';
    record.Partner_Sales_Role__c = salesRole;
    record.Partner_Sales_Contribution__c = 'Led';
    record.Partner_Technical_Contribution__c = 'Led (Primary Implementation)';

    if (isInsert) {
      insert record;
    }
    return record;
  }
}