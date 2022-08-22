@isTest
private class SObjectDeepCloneTests {
  @isTest
  static void accountWithAddresses() {
    Account acc = DataFactory_CM.createAccount('Customer', false);
    acc.Name = 'SObjectDeepClone Tests';
    insert acc;

    Address__c add = DataFactory_CM.createAddress(1, acc.Id, false)[0];
    insert add;

    //pass opportunities just to test query gen on multiple children
    SObjectDeepClone cloner = new SObjectDeepClone(acc.Id, new Set<String>{ 'Addresses__r', 'opportunities' });
    String cloneName = 'Dupe Copy of The Account';
    Account toBeCloned = (Account) cloner.clone;
    toBeCloned.Name = cloneName; //change name
    toBeCloned.Legal__c = cloneName; //change name
    SObjectDeepClone.SaveResult saveResult = cloner.save();
    Id clonedId = saveResult.clone.Id;
    System.assertNotEquals(null, clonedId);
    System.assertNotEquals(acc.Id, clonedId);

    Account queriedClonedAccount = [SELECT Name, (SELECT Id FROM Addresses__r) FROM Account WHERE Id = :clonedId];

    System.assertEquals(cloneName, queriedClonedAccount.Name);
    System.assertEquals(1, queriedClonedAccount.Addresses__r.size());
  }
}