@IsTest
public with sharing class LicenseValidatorTest_SV {
  @IsTest
  static void methodName() {
    Test.startTest();
    LicenseValidator_SV.Response response = LicenseValidator_SV.validateLicenseCode('dummy');
    Test.stopTest();
    System.assertEquals(response.name, 'Demo Energy');
  }
}