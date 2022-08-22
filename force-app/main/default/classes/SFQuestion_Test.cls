@IsTest
public class SFQuestion_Test {
@isTest(SeeAllData='true')
    private static void SFQuestion_Test(){
         Survey__c objsurvey= new Survey__c(name='Test Survey');
        insert objsurvey;
        Survey_Question__c objsurveyQues= new Survey_Question__c(Survey__c=objsurvey.Id,Name='q1',Question__c='How do you rate UiPath Product?',type__c='Single Select--Vertical',Choices__c='12345',OrderNumber__c=1);
        insert objsurveyQues;
        
        SFQuestion sfq=new SFQuestion(objsurveyQues);
        
        Survey_Question__c objsurveyQues1= new Survey_Question__c(Survey__c=objsurvey.Id,Name='q1',Question__c='How do you rate UiPath Product?',type__c='Multi-Select--Vertical',Choices__c='12345',OrderNumber__c=1);
        insert objsurveyQues1;
        
        SFQuestion sfq1=new SFQuestion(objsurveyQues1);
        
         Survey_Question__c objsurveyQues2= new Survey_Question__c(Survey__c=objsurvey.Id,Name='q1',Question__c='How do you rate UiPath Product?',type__c='Single Select--Horizontal',Choices__c='12345',OrderNumber__c=1);
        insert objsurveyQues2;
          SFQuestion sfq2=new SFQuestion(objsurveyQues2);
        
        Survey_Question__c objsurveyQues3= new Survey_Question__c(Survey__c=objsurvey.Id,Name='q1',Question__c='How do you rate UiPath Product?',type__c='Free Text - Single Row Visible',Choices__c='',OrderNumber__c=1);
        insert objsurveyQues3;
        SFQuestion sfq3=new SFQuestion(objsurveyQues3);
        
        
    }
}