global class ParentAccountMaintenanceBatch_SL implements Schedulable, Database.Batchable<sObject> {
  global void execute(SchedulableContext scon) {
    Database.executeBatch(new ParentAccountMaintenanceBatch_SL(), 10);
  }

  global Database.QueryLocator start(Database.batchableContext bc) {
    String query = 'SELECT id,Ultimate_Parent_Id__c FROM Account WHERE  LastModifiedDate >= LAST_N_DAYS:1';
    return Database.getQueryLocator(query);
  }

  global void execute(Database.BatchableContext bc, List<Account> accountList) {
    Set<String> ultimateParentAccountIds = new Set<String>();
    Map<Id, Double> parentIdToNoOfEmployes = new Map<Id, Double>();
    List<Account> accountsToUpdate = new List<Account>();
    for (Account acc : accountList) {
      if (acc.Ultimate_Parent_Id__c != null) {
        ultimateParentAccountIds.add(acc.Ultimate_Parent_Id__c);
      }
    }

    List<Account> allAccounts = [
      SELECT id, Ultimate_Parent_Id__c, Employees_per_Group__c, NumberOfEmployees
      FROM Account
      WHERE Ultimate_Parent_Id__c IN :ultimateParentAccountIds
    ];

    for (Account acc : allAccounts) {
      if (parentIdToNoOfEmployes.containsKey(acc.Ultimate_Parent_Id__c)) {
        if (acc.NumberOfEmployees != null) {
          Double noOfEmp = parentIdToNoOfEmployes.get(acc.Ultimate_Parent_Id__c);
          noOfEmp += acc.NumberOfEmployees;
          parentIdToNoOfEmployes.put(acc.Ultimate_Parent_Id__c, noOfEmp);
        }
      } else {
        Double noOfEmp = 0;
        if (acc.NumberOfEmployees != null) {
          noOfEmp += acc.NumberOfEmployees;
          parentIdToNoOfEmployes.put(acc.Ultimate_Parent_Id__c, noOfEmp);
        } else {
          parentIdToNoOfEmployes.put(acc.Ultimate_Parent_Id__c, noOfEmp);
        }
      }
    }

    for (Account acc : allAccounts) {
      if (parentIdToNoOfEmployes.containsKey(acc.Ultimate_Parent_Id__c)) {
        acc.Employees_per_Group__c = parentIdToNoOfEmployes.get(acc.Ultimate_Parent_Id__c);
        accountsToUpdate.add(acc);
      }
    }

    Database.update(accountsToUpdate);
  }

  global void finish(Database.BatchableContext BC) {
  }
}