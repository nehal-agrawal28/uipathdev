@IsTest
private class UtilitiesTest_PP {
  private static testMethod void testObjectToString() {
    System.assertEquals(
      new List<String>{ '123', '456', '789' },
      Utilities_PP.objectToString(new List<Object>{ 123, 456, 789 })
    );
  }

  private static testMethod void testObjectStringToString() {
    System.assertEquals(
      new List<String>{ '123', '456', '789' },
      Utilities_PP.objectToString(new List<Object>{ '123', '456', '789' })
    );
  }

  static testMethod void itShouldReturnEmptyListOnEmptyObjectToString() {
    System.assertEquals(new List<String>(), Utilities_PP.objectToString(new List<Object>()));
  }

  static testMethod void itShouldConvertSetToListOfString() {
    System.assertEquals(new List<String>{ '1', '2', '3' }, Utilities_PP.objectToString(new Set<Object>{ 1, 2, 3 }));
  }

  static testMethod void itShouldConvertSetObjectToSetOfIds() {
    Id idA = fflib_IDGenerator.generate(Account.SObjectType);
    Id idB = fflib_IDGenerator.generate(Account.SObjectType);
    System.assertEquals(
      new Set<Id>{ idA, idB },
      Utilities_PP.objectToIds(new Set<Object>{ (Object) idA, (Object) idB })
    );
  }

  static testMethod void itShouldReturnReversedObjectList() {
    System.assertEquals(
      new List<Object>{ (Object) 'C', (Object) 'B', (Object) 'A' },
      Utilities_PP.reverse(new List<Object>{ (Object) 'A', (Object) 'B', (Object) 'C' })
    );
  }

  static testMethod void itShouldReturnReversedSObjectList() {
    System.assertEquals(
      new List<SObject>{
        (SObject) new Account(Name = 'C'),
        (SObject) new Account(Name = 'B'),
        (SObject) new Account(Name = 'A')
      },
      Utilities_PP.reverse(
        new List<SObject>{
          (SObject) new Account(Name = 'A'),
          (SObject) new Account(Name = 'B'),
          (SObject) new Account(Name = 'C')
        }
      )
    );
  }

  static testMethod void itShouldConvertListOfStringsIntoUpperCase() {
    System.assertEquals(
      new List<String>{ 'TEST A', 'TEST B', 'TEST C' },
      Utilities_PP.upperCase(new List<String>{ 'test a', 'test b', 'test c' })
    );
  }

  static testMethod void itShouldPluckTheIdField() {
    // GIVEN a list of Accounts with Ids
    Set<Id> ids = new Set<Id>{
      fflib_IDGenerator.generate(Account.SObjectType),
      fflib_IDGenerator.generate(Account.SObjectType),
      fflib_IDGenerator.generate(Account.SObjectType)
    };
    List<Account> accounts = new List<Account>();
    for (Id accountId : ids) {
      accounts.add(new Account(Id = accountId));
    }

    // WHEN we extract the Ids
    Set<Id> result = Utilities_PP.pluckIdField(accounts, Account.Id);

    // THEN the result should contain all the account Ids
    System.assertEquals(ids, result);
  }

  static testMethod void itShouldPluckTheEmptyIdField() {
    System.assertEquals(new Set<Id>(), Utilities_PP.pluckIdField(new List<Account>(), Account.Id));
  }

  static testMethod void itShouldPluckTheStringField() {
    // GIVEN a list of Accounts with Names
    Set<String> names = new Set<String>{ 'Account A', 'Account B', 'Account C' };
    List<Account> accounts = new List<Account>();
    for (String accountName : names) {
      accounts.add(new Account(Name = accountName));
    }

    // WHEN we extract the Name field
    Set<String> result = Utilities_PP.pluckStringField(accounts, Account.Name);

    // THEN the result should contain all the account Names
    System.assertEquals(names, result);
  }

  static testMethod void itShouldPluckTheEmptyStringField() {
    System.assertEquals(new Set<String>(), Utilities_PP.pluckStringField(new List<Account>(), Account.Name));
  }

  private static testMethod void testLowerCase() {
    System.assertEquals(new List<String>{ 'abc', 'def' }, Utilities_PP.lowerCase(new List<String>{ 'ABC', 'DEF' }));
  }

  private static testMethod void testPluck() {
    System.assertEquals(
      new List<String>{ 'abc123', 'xyz789' },
      Utilities_PP.pluck(
        new List<SObject>{ (SObject) new Account(Name = 'abc123'), (SObject) new Account(name = 'xyz789') },
        Account.Name
      )
    );
  }

  private static testMethod void testPluckSet() {
    System.assertEquals(
      new Set<Object>{ 'abc123', 'xyz789' },
      Utilities_PP.pluckSet(
        new List<SObject>{
          (SObject) new Account(Name = 'abc123'),
          (SObject) new Account(Name = 'abc123'),
          (SObject) new Account(name = 'xyz789')
        },
        Account.Name
      )
    );
  }

  static testMethod void itShouldSplitAnEmptySetIntoAndEmptyMap() {
    // GIVEN
    Set<Id> idSet = new Set<Id>();

    // WHEN
    Map<Integer, Set<Id>> result = Utilities_PP.splitIdSet(idSet, 5);

    // THEN
    System.assertEquals(0, result.size(), 'Incorrect amount of returned batches');
  }

  static testMethod void itShouldSplitAnSmallSetIntoASingleMap() {
    // GIVEN
    Set<Id> idSet = new Set<Id>{
      fflib_IDGenerator.generate(Account.SObjectType),
      fflib_IDGenerator.generate(Account.SObjectType),
      fflib_IDGenerator.generate(Account.SObjectType)
    };

    // WHEN
    Map<Integer, Set<Id>> result = Utilities_PP.splitIdSet(idSet, 5);

    // THEN
    System.assertEquals(1, result.size(), 'Incorrect amount of returned batches');
    System.assertEquals(idSet, result.get(0), 'Incorrect returned IdSet');
  }

  static testMethod void itShouldSplitAnLargeSetIntoASingleMap() {
    // GIVEN
    Set<Id> idSet = new Set<Id>{
      fflib_IDGenerator.generate(Account.SObjectType),
      fflib_IDGenerator.generate(Account.SObjectType),
      fflib_IDGenerator.generate(Account.SObjectType)
    };

    // WHEN
    Map<Integer, Set<Id>> result = Utilities_PP.splitIdSet(idSet, 2);

    // THEN
    System.assertEquals(2, result.size(), 'Incorrect amount of returned batches');
    System.assertEquals(2, result.get(0).size(), 'Incorrect amount of elements in first Batch');
    System.assertEquals(1, result.get(1).size(), 'Incorrect amount of elements in second Batch');
  }

  static testMethod void itShouldSplitAnSetWithMaxLimitIntoSingleMap() {
    // GIVEN
    Set<Id> idSet = new Set<Id>{
      fflib_IDGenerator.generate(Account.SObjectType),
      fflib_IDGenerator.generate(Account.SObjectType),
      fflib_IDGenerator.generate(Account.SObjectType)
    };

    // WHEN
    Map<Integer, Set<Id>> result = Utilities_PP.splitIdSet(idSet, 3);

    // THEN
    System.assertEquals(1, result.size(), 'Incorrect amount of returned batches');
    System.assertEquals(idSet, result.get(0), 'Incorrect returned IdSet');
  }

  @IsTest
  static void itShouldReturnMostRecentDatetime() {
    // GIVEN - a list of unsorted Datetime values
    List<Datetime> datetimes = generateDateTimes();

    // WHEN - we request the maxDatetime
    Datetime maxDatetime = Utilities_PP.maxDatetime(datetimes);

    // THEN - the highest Datetime should be returned
    System.assertEquals(datetimes.get(1), maxDatetime);
  }

  @IsTest
  static void itShouldReturnOldestDatetime() {
    // GIVEN - a list of unsorted Datetime values
    List<Datetime> datetimes = generateDateTimes();

    // WHEN - we request the maxDatetime
    Datetime maxDatetime = Utilities_PP.minDatetime(datetimes);

    // THEN - the highest Datetime should be returned
    System.assertEquals(datetimes.get(4), maxDatetime);
  }

  @IsTest
  static void itShouldHandleNullInputsForMaxDatatime() {
    System.assertEquals(
      null,
      Utilities_PP.maxDatetime(new List<Datetime>()),
      'maxDatatime method was unable to handle an empty list as input'
    );
    System.assertEquals(null, Utilities_PP.maxDatetime(null), 'maxDatatime method was unable to handle null as input');
  }

  @IsTest
  static void itShouldCloneAndSortTheList() {
    // GIVEN - a list of unsorted numbers
    List<Integer> unsorted = new List<Integer>{ 1, 30, 2, 76, -7 };

    // WHEN - we request the a cloned and sorted list
    List<Integer> sorted = Utilities_PP.cloneAndSort(unsorted);
    System.assertNotEquals(unsorted, sorted, 'The original object was modified, something went wrong with the cloning');
    System.assertEquals(new List<Integer>{ -7, 1, 2, 30, 76 }, sorted, 'Incorrect sorted list returned');
  }

  @IsTest
  static void itShouldReturnTheLastValueInTheList() {
    // GIVEN - a list of unsorted values
    List<Object> objects = new List<Object>{ 1, 2, 3, 9, 4, 7, 8 };

    // WHEN - we request the last value
    Object result = Utilities_PP.lastValue(objects);

    // THEN - the highest Datetime should be returned
    System.assertEquals(8, result, 'Did not return the last value in the list of objects');
  }

  private static List<Datetime> generateDateTimes() {
    return new List<Datetime>{
      Datetime.newInstance(2020, 1, 1, 7, 59, 7),
      Datetime.newInstance(2020, 2, 1, 7, 40, 7),
      Datetime.newInstance(2020, 2, 1, 7, 0, 7),
      Datetime.newInstance(2019, 2, 1, 7, 59, 7),
      Datetime.newInstance(2018, 7, 7, 7, 7, 7)
    };
  }
}