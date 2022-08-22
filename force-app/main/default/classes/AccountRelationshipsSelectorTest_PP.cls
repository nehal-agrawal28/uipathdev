@IsTest
private class AccountRelationshipsSelectorTest_PP {
  @TestSetup
  static void setup() {
    TestFactory_PP.init();
  }

  @IsTest
  static void itShouldSelectById() {
    // given
    List<AccountRelationship> givenRelationships = [SELECT Id FROM AccountRelationship];

    Set<Id> accountRelationshipIds = new Set<Id>{ givenRelationships.get(0).Id };

    AccountRelationshipsSelector_PP selector = (AccountRelationshipsSelector_PP) Application_PP.Selector.newInstance(
      AccountRelationship.SObjectType
    );

    // when
    List<AccountRelationship> relationships = selector.selectById(accountRelationshipIds, false);
    List<AccountRelationship> relationships2 = selector.selectById(accountRelationshipIds, true);

    // then
    System.assertEquals(false, relationships.isEmpty());
    System.assert(accountRelationshipIds.contains(relationships.get(0).Id));
  }

  @IsTest
  static void itShouldSelectByAccountToIdsAndTypes() {
    // given
    Account reseller = [SELECT Id FROM Account WHERE Name LIKE 'reselleraccount%' LIMIT 1];
    Account distributor = [SELECT Id FROM Account WHERE Name LIKE 'distributoraccount%' LIMIT 1];

    Set<Id> accountToIds = new Set<Id>{ reseller.Id };
    Set<String> types = new Set<String>{ 'Distributor' };

    AccountRelationshipsSelector_PP selector = (AccountRelationshipsSelector_PP) Application_PP.Selector.newInstance(
      AccountRelationship.SObjectType
    );

    // when
    List<AccountRelationship> relationships = selector.selectByAccountToIdsAndTypes(accountToIds, types, false);
    List<AccountRelationship> relationships2 = selector.selectByAccountToIdsAndTypes(accountToIds, types, true);

    // then
    System.assertEquals(false, relationships.isEmpty());
    System.assertEquals(distributor.Id, relationships.get(0).AccountFromId);
    System.assertEquals(reseller.Id, relationships.get(0).AccountToId);
  }
}