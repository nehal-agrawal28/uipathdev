@IsTest
public class ReportFinderUtil_Test {
@isTest(SeeAllData='true')
     private static void findReportId_Test(){
         ReportFinderUtil rfu= new ReportFinderUtil();
         rfu.findReportId('Survey with Questions and Responses');
     }
}