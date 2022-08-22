public with sharing class MyProfileDocumentsController_PP {
  @AuraEnabled
  public static List<My_Profile_Documents__mdt> getDocuments() {
    return (My_Profile_Documents__mdt.getAll().values().isEmpty()) ? null : My_Profile_Documents__mdt.getAll().values();
  }

  @AuraEnabled
  public static String getPDFUrlHost() {
    Site mySite = [SELECT Id FROM Site WHERE Name = 'Global_Partner_Portal'];
    return [SELECT SecureURL FROM SiteDetail WHERE DurableId = :mySite.Id].SecureURL + '/apex/';
  }
}