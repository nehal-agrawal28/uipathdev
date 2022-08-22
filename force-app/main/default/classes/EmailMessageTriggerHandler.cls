public class EmailMessageTriggerHandler {

    public EmailMessageTriggerHandler(){        
    }
    private boolean isExecuting = false;
    private integer batchSize = 0;
    public EmailMessageTriggerHandler(boolean triggerExecuting, integer size) {
        isExecuting = triggerExecuting;
        batchSize = size;
    }

    public void onBeforInsert(List<EmailMessage> emailList){
        System.debug('Inside before insert email handler');
        try{
            addCaseNumberToEmailSubject(emailList);            
        }catch(Exception ex){
                System.debug('onBeforInsert' + ex.getMessage() +ex.getLineNumber() + ex.getTypeName() +ex.getCause());
            }
        
        
    /*  List<EmailMessage> caseEmails = new List<EmailMessage>();
        //Set<Id> caseIdSet = new Set<Id>();
        for(EmailMessage email : emailList){
            if(String.valueOf((email.RelatedToId).getSobjectType()) == 'Case'){
                System.debug('******556******');
                caseEmails.add(email);
                //caseIdSet.add(email.Parent);
            }
        }
        System.debug('caseEmails' + caseEmails);
        //System.debug('caseIdSet' + caseIdSet);
        if(!caseEmails.isEmpty()){
            addCaseNumberToEmailSubject(caseEmails);
        } */
    }

    private static void addCaseNumberToEmailSubject(List<EmailMessage> caseEmails){
        System.debug('Inside before addCaseNumberToEmailSubject');  
        try{
            
            Id incidentCaseRTId = SupportConstants.incidentRtId;
            Id Service_RequestRTId = SupportConstants.serviceRequestRtId;
            Id Service_IncidentRTId = SupportConstants.serviceIncidentRtId;
            Id Engagement_RequestRTId = SupportConstants.engagementRequestRtId;
            Id Japan_Engagement_RequestRTId = SupportConstants.jsEngagementRequestRtId;
            // Id Sales_OperationRTId = SupportConstants.salesOpsRtId;
            Id AcademyRTId = SupportConstants.academyRtId;
            Id Japan_AcademyRTId = SupportConstants.jsAcademyRtId;
            Id Japan_LicensingRTId = SupportConstants.jsLicensingRtId;
            Id Japan_IncidentRTId = SupportConstants.jsIncidentRtId;
            
            Set<Id> emailsIdSet = new Set<Id>();
            Set<id> casidset=new Set<id>();
            for(EmailMessage em:caseEmails){
                //if condition modified by deepali for checking if parentid is not null
                if(em.ParentId != Null && (em.ParentId).getSobjectType()==case.sobjectType){
                    System.debug('*******111**email**');
                    casidset.add(em.ParentId);
                }
              //  if((em.RelatedtoId).getSobjectType()==case.sobjectType){
                //    System.debug('*******121**email**');
                   // casidset.add(em.ParentId);
                //}
            }
            Map<id,case> casmap=new Map<id,case>();
            if(!casidset.isEmpty()){
                System.debug('*********email**');
                casmap=new Map<id,case>([Select id,subject,CaseNumber 
                                         from case 
                                         where id in :casidset
                                        AND(
                                            RecordtypeId = :incidentCaseRTId OR 
                                            RecordtypeId = :Service_RequestRTId OR 
                                            RecordtypeId = :Service_IncidentRTId OR 
                                            RecordtypeId = :Engagement_RequestRTId OR
                                            RecordtypeId = :Japan_Engagement_RequestRTId OR
                                            // RecordtypeId = :Sales_OperationRTId OR 
                                            RecordtypeId = :AcademyRTId OR 
                                            RecordtypeId = :Japan_AcademyRTId OR 
                                            RecordtypeId = :Japan_LicensingRTId OR
                                            RecordtypeId = :Japan_IncidentRTId OR
                                            RecordtypeId = :Japan_IncidentRTId
                                        )]);
            }
            
            
            for(EmailMessage email :caseEmails){
               
                    if(casmap.containsKey(email.ParentId)){
                        System.debug('email.Parent.CaseNumber' + email.Parent.CaseNumber);
                        if(( email.Subject!=null) && !(email.Subject.contains('RE:')))
                        {
                            //if-else condition added by deepali to not print case subject twice in email subject
                            if(casmap.get(email.ParentId).Subject != null && email.Subject.contains(casmap.get(email.ParentId).Subject)){   
                                email.Subject =  casmap.get(email.ParentId).CaseNumber + '_' + casmap.get(email.ParentId).Subject;
                            }else{
                                email.Subject =  casmap.get(email.ParentId).CaseNumber + '_' + casmap.get(email.ParentId).Subject + '_' + email.Subject;
                            }
                        }
                        else if(email.Subject==null && casmap.get(email.ParentId).Subject != null )
                        {
                            email.Subject =  casmap.get(email.ParentId).CaseNumber + '_' + casmap.get(email.ParentId).Subject;
                        }
                        else if(casmap.get(email.ParentId).Subject==null && (email.Subject!=null))
                        {
                            email.Subject =  casmap.get(email.ParentId).CaseNumber + '_' + email.Subject;
                        }
                        else if(casmap.get(email.ParentId).Subject==null && email.Subject==null)
                        {
                             email.Subject =  casmap.get(email.ParentId).CaseNumber ;
                        }
                        System.debug('email.FromAddress' + email.FromAddress);                        
                    }            
            }
                        
        }catch(Exception ex){
                System.debug('addCaseNumberToEmailSubject' + ex.getMessage() +ex.getLineNumber() + ex.getTypeName() +ex.getCause());
            }      
    }
}