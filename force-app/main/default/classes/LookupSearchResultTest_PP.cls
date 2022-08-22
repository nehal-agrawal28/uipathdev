@IsTest
private class LookupSearchResultTest_PP {
  @IsTest
  static void itShouldSortItemsByTitle() {
    // given
    String sObjectType = 'ErrorLog__c';
    String icon = 'standard:account';

    List<ErrorLog__c> errors = new List<ErrorLog__c>{
      new ErrorLog__c(LineNumber__c = 346, ExceptionType__c = 'Charlie', ExceptionMessage__c = 'Foobarbaz'),
      new ErrorLog__c(LineNumber__c = 346, ExceptionType__c = 'Alpha', ExceptionMessage__c = 'Foobarbaz'),
      new ErrorLog__c(LineNumber__c = 346, ExceptionType__c = 'Tango', ExceptionMessage__c = 'Foobarbaz')
    };
    insert errors;

    List<LookupSearchResult_PP> results = new List<LookupSearchResult_PP>();

    for (ErrorLog__c error : errors) {
      results.add(
        new LookupSearchResult_PP(error.Id, sObjectType, icon, error.ExceptionType__c, error.ExceptionMessage__c)
      );
    }

    System.assertEquals(errors.get(0).ExceptionType__c, results.get(0).getTitle());
    System.assertEquals(errors.get(1).ExceptionType__c, results.get(1).getTitle());
    System.assertEquals(errors.get(2).ExceptionType__c, results.get(2).getTitle());

    // when
    results.sort();

    // then
    System.assertEquals(errors.get(1).ExceptionType__c, results.get(0).getTitle());
    System.assertEquals(errors.get(0).ExceptionType__c, results.get(1).getTitle());
    System.assertEquals(errors.get(2).ExceptionType__c, results.get(2).getTitle());

    System.assertEquals(errors.get(1).Id, results.get(0).getId());
    System.assertEquals(sObjectType, results.get(0).getSObjectType());
    System.assertEquals(icon, results.get(0).getIcon());
    System.assertEquals(errors.get(1).ExceptionMessage__c, results.get(0).getSubtitle());
  }
}