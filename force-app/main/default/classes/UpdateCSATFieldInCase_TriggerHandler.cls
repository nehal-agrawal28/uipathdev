/***
TO DO: To be refactored and to be moved to service package
***/
public class UpdateCSATFieldInCase_TriggerHandler {
    public void onAfterInsert(List<SurveyQuestionResponse__c> newSurveyResponses){  
        
        Map<String, Integer> responseValueMap = new Map<String, Integer>{'Poor'=>1, 'Below Average'=>2, 'Average'=>3, 'Above Average'=>4, 'Excellent'=>5, 
            '不満'=>1, 'やや不満'=>2, 'どちらともいえない'=>3, 'やや満足'=>4, '満足'=>5, 
            '1 (Lowest)'=>1, '2'=>2, '3'=>3, '4'=>4, '5'=>5, '6'=>6, '7'=>7, '8'=>8, '9'=>9, '10 (Highest)'=>10,
            '1 (不満)'=>1, '10 (満足)'=>10, '1 (勧めたくない)'=>1, '10 (勧めたい)'=>10
            };
                
                List<String> allQuestionNames = new List<String>();
        allQuestionNames.addAll(Label.Survey_Question_for_calculations.split(','));
        allQuestionNames.addAll(Label.SurveyCalcQuestionInc.split(','));
        
        Set<Id> caseIds =new Set<Id>();
        
        Map<String, String> recordTypeIdMap = new Map<String, String>();
        
        List<Case> caseListToUpdate = new List<Case>();
        
        Map<Id,List<SurveyQuestionResponse__c>> surveyResponseWithCaseIdMap = new Map<Id,List<SurveyQuestionResponse__c>>();
        
        for(SurveyQuestionResponse__c sqr : [Select Id, SurveyTaker__r.Case__c,SurveyTaker__r.Case__r.RecordTypeId from SurveyQuestionResponse__c where id in :newSurveyResponses and SurveyTaker__r.case__c!=null]){
            caseIds.add(sqr.SurveyTaker__r.Case__c); 
            recordTypeIdMap.put(sqr.SurveyTaker__r.Case__c,sqr.SurveyTaker__r.Case__r.RecordTypeId);
        }
        
        if(!caseIds.isEmpty()){
            double avgCSAT=0;
            integer count=0;
            double totalCsat=0;
            
            Survey_Question__c sq = new Survey_Question__c();
            
            for(SurveyTaker__c st : [Select case__c,Case__r.CSAT__c,(Select Id,response__c,Survey_Question__r.name from Survey_Question_Answers__r where  Survey_Question__r.Name IN :allQuestionNames ) from SurveyTaker__c where case__c!=null and case__c in : caseIds] ){
                List<SurveyQuestionResponse__c> questionResponses = new List<SurveyQuestionResponse__c>();
                for(SurveyQuestionResponse__c response : st.Survey_Question_Answers__r){
                    if(recordTypeIdMap.get(st.case__c) != null && (recordTypeIdMap.get(st.case__c) == CaseMetadata_SV.AcademyRecordType || recordTypeIdMap.get(st.case__c) == CaseMetadata_SV.SalesOperationRecordType)){
                        if(Label.Survey_Question_for_calculations.split(',').contains(response.Survey_Question__r.name)){
                            questionResponses.add(response);
                        }
                    }else{
                        if(Label.SurveyCalcQuestionInc.split(',').contains(response.Survey_Question__r.name)){
                            questionResponses.add(response);
                        }
                    }
                }
                
                
                if(surveyResponseWithCaseIdMap.containsKey(st.case__c)){
                    List<SurveyQuestionResponse__c> lstresponse= surveyResponseWithCaseIdMap.get(st.case__c) ;
                    //lstresponse.addAll(st.Survey_Question_Answers__r);
                    lstresponse.addAll(questionResponses);
                    surveyResponseWithCaseIdMap.put(st.case__c,lstresponse);
                }
                else{
                    //surveyResponseWithCaseIdMap.put(st.case__c,st.Survey_Question_Answers__r);
                    surveyResponseWithCaseIdMap.put(st.case__c,questionResponses);
                }
            }
            
            for(Id recordId:surveyResponseWithCaseIdMap.keyset()){
                totalCsat=0;
                count=0;
                avgCSAT=0;
                for(SurveyQuestionResponse__c sqr:surveyResponseWithCaseIdMap.get(recordId)){
                    Integer responseValue=0;
                    if(String.isNotBlank(sqr.Response__c) && responseValueMap.get(sqr.Response__c)!=null)
                        responseValue = responseValueMap.get(sqr.Response__c);
                    /*if(sqr.Response__c=='Poor'||sqr.Response__c=='不満'){
responseValue=1;
}
else if(sqr.Response__c=='Below Average'|| sqr.Response__c=='やや不満'){
responseValue=2;
}
else if(sqr.Response__c=='Average'||sqr.Response__c=='どちらともいえない'){
responseValue=3;
}
else if(sqr.Response__c=='Above Average'||sqr.Response__c=='やや満足'){
responseValue=4;  
}
else if(sqr.Response__c=='Excellent'|| sqr.Response__c=='満足'){
responseValue=5; 
}
else{
responseValue=0;
}*/
                    totalCsat= totalCsat+ responseValue;
                    count++;
                }
                if (totalCsat>0){
                    avgCSAT= totalCsat/count;  
                }
                case objcase= new case(Id=recordId,CSAT__c=avgCSAT);
                caseListToUpdate.add(objcase);   
            }
            if(caseListToUpdate.size()>0){
                update  caseListToUpdate;
            }
        }   
    }
    
}