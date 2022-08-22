@isTest
public class CPQRenewalUpliftSelectorTest_SL {
  @isTest
  public static void itShouldRetrieveRecords() {
    //GIVEN
    CPQRenewalUpliftSelector_SL selector = new CPQRenewalUpliftSelector_SL();

    //WHEN
    List<CPQ_Renewal_Uplift__mdt> records = selector.getAll();

    //THEN
    System.assertEquals(false, records.isEmpty(), 'The selector should return records');
  }
}