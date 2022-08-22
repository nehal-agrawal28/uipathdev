@isTest
public with sharing class SetSobjectFieldFunctionTest_SL {
  @isTest
  public static void setFieldOnOrderStringTest() {
    //SETUP
    Id o1Id = fflib_IDGenerator.generate(Order.SObjectType);
    Order o1 = new Order(AccountId = '0018E00001TLe6DQAT', EffectiveDate = Date.today(), Status = 'Draft', Id = o1Id);

    Id o2Id = fflib_IDGenerator.generate(Order.SObjectType);
    Order o2 = new Order(
      AccountId = '0018E00001TLe6DQAT',
      EffectiveDate = Date.today(),
      Status = 'Activated',
      Id = o2Id
    );

    List<Order> orders = new List<Order>{ o1, o2 };
    Map<Id, Order> ordersById = new Map<Id, Order>(orders);

    SObjectField field = Order.Status;
    DescribeFieldResult descrResult = field.getDescribe();
    String fieldName = descrResult.name;
    String fieldType = descrResult.getSoapType().name();

    //ACT
    List<Order> updatedOrders = Collection.of(orders)
      .mapAll(new SetSobjectFieldFunction_SL(field, descrResult, fieldName, fieldType))
      .asList();
    Map<Id, Order> updatedOrdersById = new Map<Id, Order>(updatedOrders);

    //ASSERT
    System.assertEquals(2, updatedOrders.size());
    for (Order o : updatedOrders) {
      System.assertNotEquals(null, o.Id);
      System.assertEquals(ordersById.get(o.Id).Status, o.Status);
      System.assertEquals(null, o.AccountId);
      System.assertEquals(null, o.EffectiveDate);
    }
    System.assertEquals(ordersById.get(o1Id).Status, updatedOrdersById.get(o1Id).Status);
    System.assertEquals(ordersById.get(o2Id).Status, updatedOrdersById.get(o2Id).Status);
  }

  @isTest
  public static void setFieldOnOrderDateTest() {
    //SETUP
    Id o1Id = fflib_IDGenerator.generate(Order.SObjectType);
    Order o1 = new Order(AccountId = '0018E00001TLe6DQAT', EffectiveDate = Date.today(), Status = 'Draft', Id = o1Id);

    Id o2Id = fflib_IDGenerator.generate(Order.SObjectType);
    Order o2 = new Order(
      AccountId = '0018E00001TLe6DQAT',
      EffectiveDate = Date.today(),
      Status = 'Activated',
      Id = o2Id
    );

    List<Order> orders = new List<Order>{ o1, o2 };
    Map<Id, Order> ordersById = new Map<Id, Order>(orders);

    SObjectField field = Order.EffectiveDate;
    DescribeFieldResult descrResult = field.getDescribe();
    String fieldName = descrResult.name;
    String fieldType = descrResult.getSoapType().name();

    //ACT
    List<Order> updatedOrders = Collection.of(orders)
      .mapAll(new SetSobjectFieldFunction_SL(field, descrResult, fieldName, fieldType))
      .asList();
    Map<Id, Order> updatedOrdersById = new Map<Id, Order>(updatedOrders);

    //ASSERT
    System.assertEquals(2, updatedOrders.size());
    for (Order o : updatedOrders) {
      System.assertNotEquals(null, o.Id);
      System.assertEquals(ordersById.get(o.Id).EffectiveDate, o.EffectiveDate);
      System.assertEquals(null, o.AccountId);
      System.assertEquals(null, o.Status);
    }
    System.assertEquals(ordersById.get(o1Id).EffectiveDate, updatedOrdersById.get(o1Id).EffectiveDate);
    System.assertEquals(ordersById.get(o2Id).EffectiveDate, updatedOrdersById.get(o2Id).EffectiveDate);
  }

  @isTest
  public static void setFieldOnAccountBooleanTest() {
    //SETUP
    Id a1Id = fflib_IDGenerator.generate(Account.SObjectType);
    Account a1 = new Account(Id = a1Id, Name = 'Acc1', Top_Account__c = true);

    Id a2Id = fflib_IDGenerator.generate(Account.SObjectType);
    Account a2 = new Account(Id = a2Id, Name = 'Acc2', Top_Account__c = false);

    List<Account> accounts = new List<Account>{ a1, a2 };
    Map<Id, Account> accountsById = new Map<Id, Account>(accounts);

    SObjectField field = Account.Top_Account__c;
    System.assert(field.getDescribe().isUpdateable());
    DescribeFieldResult descrResult = field.getDescribe();
    String fieldName = descrResult.name;
    String fieldType = descrResult.getSoapType().name();

    //ACT
    List<Account> updatedAccounts = Collection.of(accounts)
      .mapAll(new SetSobjectFieldFunction_SL(field, descrResult, fieldName, fieldType))
      .asList();
    Map<Id, Account> updatedAccountsById = new Map<Id, Account>(updatedAccounts);

    //ASSERT
    System.assertEquals(2, updatedAccounts.size());
    for (Account a : updatedAccounts) {
      System.assertNotEquals(null, a.Id);
      System.assertEquals(accountsById.get(a.Id).Top_Account__c, a.Top_Account__c);
      System.assertEquals(null, a.Name);
    }
    System.assertEquals(true, updatedAccountsById.get(a1Id).Top_Account__c);
    System.assertEquals(false, updatedAccountsById.get(a2Id).Top_Account__c);
  }

  @isTest
  public static void setFieldOnOrderBooleanTestNonEditableField() {
    //SETUP
    Id o1Id = fflib_IDGenerator.generate(Order.SObjectType);
    Order o1 = new Order(AccountId = '0018E00001TLe6DQAT', EffectiveDate = Date.today(), Status = 'Draft', Id = o1Id);

    Id o2Id = fflib_IDGenerator.generate(Order.SObjectType);
    Order o2 = new Order(
      AccountId = '0018E00001TLe6DQAT',
      EffectiveDate = Date.today(),
      Status = 'Activated',
      Id = o2Id
    );

    List<Order> orders = new List<Order>{ o1, o2 };
    Map<Id, Order> ordersById = new Map<Id, Order>(orders);

    //non-accessible field
    SObjectField field = Order.IsReductionOrder;
    //
    DescribeFieldResult descrResult = field.getDescribe();
    String fieldName = descrResult.name;
    String fieldType = descrResult.getSoapType().name();

    //ACT
    String exceptionMessage;
    Exception exceptionReceived;
    Exception exceptionExpected = new SetSobjectFieldFunction_SL.SetSobjectFieldFunctionnException();
    try {
      List<Order> updatedOrders = Collection.of(orders)
        .mapAll(new SetSobjectFieldFunction_SL(field, descrResult, fieldName, fieldType))
        .asList();
      Map<Id, Order> updatedOrdersById = new Map<Id, Order>(updatedOrders);
    } catch (Exception e) {
      exceptionReceived = e;
    }

    //ASSERT
    System.assertNotEquals(null, exceptionReceived);
    System.assertEquals(exceptionExpected.getTypeName(), exceptionReceived.getTypeName());
    System.assertEquals('The supplied field is not writable', exceptionReceived.getMessage());
  }
}