@IsTest
private class DefaultApplicationManagersTest_PP {
  @IsTest
  static void testNewInstanceWithIds() {
    final Id id = fflib_IDGenerator.generate(Schema.Default_Application_Manager_PP__mdt.SObjectType);
    final Set<Id> ids = new Set<Id>{ id };
    final List<Default_Application_Manager_PP__mdt> records = new List<Default_Application_Manager_PP__mdt>{
      new Default_Application_Manager_PP__mdt(Id = id)
    };

    fflib_ApexMocks mocks = new fflib_ApexMocks();
    IDefaultApplicationManagersSelector_PP selectorMock = (IDefaultApplicationManagersSelector_PP) mocks.mock(
      IDefaultApplicationManagersSelector_PP.class
    );

    mocks.startStubbing();
    mocks.when(selectorMock.sObjectType()).thenReturn(Schema.Default_Application_Manager_PP__mdt.SObjectType);
    mocks.when(selectorMock.selectSObjectsById(ids)).thenReturn(records);
    mocks.stopStubbing();

    Application_PP.Selector.setMock(selectorMock);

    System.Test.startTest();
    IDefaultApplicationManagers_PP result = DefaultApplicationManagers_PP.newInstance(ids);
    System.Test.stopTest();

    System.assertEquals(records, result.getDefaultApplicationManagers());
  }

  @IsTest
  static void testNewInstanceWithRecords() {
    final List<Default_Application_Manager_PP__mdt> records = new List<Default_Application_Manager_PP__mdt>{
      new Default_Application_Manager_PP__mdt(
        Id = fflib_IDGenerator.generate(Schema.Default_Application_Manager_PP__mdt.SObjectType)
      )
    };

    System.Test.startTest();
    IDefaultApplicationManagers_PP result = DefaultApplicationManagers_PP.newInstance(records);
    System.Test.stopTest();

    System.assertEquals(records, result.getDefaultApplicationManagers());
  }
}