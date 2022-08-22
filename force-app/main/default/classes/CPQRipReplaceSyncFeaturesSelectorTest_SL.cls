@isTest
public with sharing class CPQRipReplaceSyncFeaturesSelectorTest_SL {
  @isTest
  public static void itShouldReturnSObjectType() {
    //GIVEN
    CPQRipReplaceSyncFeaturesSelector_SL selector = new CPQRipReplaceSyncFeaturesSelector_SL();

    //WHEN
    Schema.SObjectType actualSobjectType = selector.getSObjectType();

    //THEN
    System.assertEquals(
      CPQ_RR_Sync_Feature__mdt.SObjectType,
      actualSobjectType,
      'Returned SObject Type does not match the expected type'
    );
  }

  @isTest
  public static void itShouldReturnSObjectField() {
    //GIVEN
    CPQRipReplaceSyncFeaturesSelector_SL selector = new CPQRipReplaceSyncFeaturesSelector_SL();

    //WHEN

    List<Schema.SObjectField> fieldList = selector.getSObjectFieldList();

    //THEN
    System.assertNotEquals(0, fieldList.size(), 'Returned field list did not return the expected records');
  }
}