@isTest
public with sharing class ParentAccountMaintenanceBatchTest_SL {
  @isTest
  private static void testGroupEmployeeCountCalculationOnAccout() {
    List<Account> ultimateParents = new List<Account>();
    for (Integer k = 0; k < 2; k++) {
      Account acc = DataFactory_CM.createAccount('Customer', false);
      acc.NumberOfEmployees = 5;
      ultimateParents.add(acc);
    }
    insert ultimateParents;

    List<Account> firstLevelChildAccounts = new List<Account>();
    for (Integer i = 0; i < 10; i++) {
      Account acc = DataFactory_CM.createAccount('Customer', false);
      acc.NumberOfEmployees = i + 1;
      acc.DNBoptimizer__DNB_D_U_N_S_Number__c = i + '123';
      if (i < 5) {
        acc.ParentId = ultimateParents[0].id;
      } else {
        acc.ParentId = ultimateParents[1].id;
      }
      firstLevelChildAccounts.add(acc);
    }

    insert firstLevelChildAccounts;

    List<Account> secondLevelChildAccounts = new List<Account>();

    for (Integer j = 0; j < 10; j++) {
      Account acc = DataFactory_CM.createAccount('Customer', false);
      acc.DNBoptimizer__DNB_D_U_N_S_Number__c = j + '689';
      acc.parentId = firstLevelChildAccounts[j].id;
      acc.NumberOfEmployees = j + 1;
      secondLevelChildAccounts.add(acc);
    }

    insert secondLevelChildAccounts;

    Test.startTest();
    ParentAccountMaintenanceBatch_SL batch = new ParentAccountMaintenanceBatch_SL();
    Database.executeBatch(batch);
    Test.stopTest();

    String parentId = ultimateParents[0].Id;
    String parentsId = parentId.substring(0, 15);

    List<Account> accts = [SELECT id, Employees_per_Group__c FROM Account WHERE Ultimate_Parent_Id__c = :parentsId];
    System.assertEquals(35, accts[0].Employees_per_Group__c);
  }
}