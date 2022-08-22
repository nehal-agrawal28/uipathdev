/**
 *
 * Author:       Dharani
 * Date:         01/10/2018
 * Description:  Test class for UpdateCSATFieldInCase_TriggerHandler
 *
 **/

@isTest
public class UpdateCSATFieldInCase_Trigger_test {
  public static testMethod void createTestData() {
    Id RecordTypeIdEr = Schema.SObjectType.Case.getRecordTypeInfosByName().get('Expert Request').getRecordTypeId();
    Survey__c objsurvey = new Survey__c(name = 'Test Survey');
    insert objsurvey;
    Survey_Question__c objsurveyQues = new Survey_Question__c(
      Survey__c = objsurvey.Id,
      Name = 'Q2',
      Question__c = 'How do you rate UiPath Product?',
      type__c = 'Single Select--Vertical',
      Choices__c = 'PoorBelow AverageAverageAbove AverageExcellent',
      OrderNumber__c = 1
    );
    insert objsurveyQues;
    system.debug('Print' + objsurveyQues);

    Account objAcc = new Account();
    objAcc.Name = 'Unassigned Account';
    objAcc.RecordTypeId = Utilities.getRecordTypeId('Customer', 'Account');
    objAcc.BillingStreet = 'Test  Street';
    objAcc.BillingCity = 'Test City';
    objAcc.BillingPostalCode = '123abc';
    objAcc.BillingCountry = 'United Kingdom';
    objAcc.Phone = '12345678';
    objAcc.Industry = 'Others';
    insert objAcc;
    Contact objcontact = new Contact(
      LastName = 'Test Contact',
      Email = 'dharani@warpdrivetech.in',
      AccountId = objAcc.Id,
      Department__c = 'IT'
    );
    insert objcontact;

    Case objcase = new case(
      ContactId = objcontact.Id,
      Status = 'Closed',
      Steps_Performed__c = 'Steps performed',
      Resolution_Provided__c = 'Test Resolution provided',
      Related_To__c = 'Studio',
      Sub_Component__c = 'Others',
      RecordTypeId = RecordTypeIdEr,
      UiPath_Srl_Signer_Title__c = 'Chief Financial Officer',
      Resolution_from_L2__c = 'Test Resolution_from_L2 for ER'
    );

    insert objcase;
    SurveyTaker__c objsurveytaken = new SurveyTaker__c(
      Case__c = objcase.Id,
      Contact__c = objcontact.Id,
      Survey__c = objsurvey.Id
    );
    insert objsurveytaken;
    SurveyQuestionResponse__c objSQR1 = new SurveyQuestionResponse__c(
      Response__c = 'Poor',
      SurveyTaker__c = objsurveytaken.Id,
      Survey_Question__c = objsurveyQues.Id
    );
    insert objSQR1;
    SurveyQuestionResponse__c objSQR2 = new SurveyQuestionResponse__c(
      Response__c = 'Average',
      SurveyTaker__c = objsurveytaken.Id,
      Survey_Question__c = objsurveyQues.Id
    );
    insert objSQR2;
    SurveyQuestionResponse__c objSQR3 = new SurveyQuestionResponse__c(
      Response__c = 'Excellent',
      SurveyTaker__c = objsurveytaken.Id,
      Survey_Question__c = objsurveyQues.Id
    );
    insert objSQR3;
  }
}