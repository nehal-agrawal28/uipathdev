public without sharing class TaskTriggerHandler    {
 
    private String PrimaryTaskId {get;set;}  
  
    private list<Task> oldTasks = new list<Task>();
    private map<Id, Task> oldMapTasks = new map<Id, Task>();
    private list<Task> newTasks = new list<Task>();
  
    private set<string> statusChangingGroupTaskIds = new set<string>();
    private list<Task> statusChangingTasks = new list<Task>();
    private map<string,string> MapStatusChangingTasks = new Map<string,string>();
  
    private set<string> deleteGroupTaskIds = new set<string>();
    private list<Task> deleteTasks = new list<Task>();
  


  
  public TaskTriggerHandler(list<Task> newTasks, map<Id, Task> oldMapTasks){
    this.newTasks = newTasks;
    this.oldMapTasks = oldMapTasks;
  }
  
  

  public void processStatusChanging(){
    qualifiedTasks();
    fetchTasksWithGroupTaskIds();
    UpdateTasks();
    CommitTasks();
    deleteTasksWithGroupTaskIds();
    CommitDeleteTasks();
    UpdateRelatedOppANDAccount();
  }
  
  private void UpdateRelatedOppANDAccount(){
      Set<Id> oppIds = new Set<Id>();  
      Id onboardingPlaybookRT = SObjectType.Task.getRecordTypeInfosByName().get('Onboarding Playbook').getRecordTypeId();
      for(task t:this.newTasks){
          Task oldTask = oldMapTasks.get(t.Id);
          if(t.Last_Onboarding_Task__c == true && t.RecordTypeId == onboardingPlaybookRT && t.Status != oldTask.Status && t.Status == 'Completed' && (String.valueOf(t.WhatId)).substring(0,3) == '006') {
              oppIds.add(t.WhatId);
          }
      }
      if(oppIds.size() > 0) {
          List<Opportunity> allOpps = [SELECT Id, AccountId, Customer_Onboarded__c  FROM Opportunity WHERE Id IN: oppIds];
          Set<Id> accIds = new Set<Id>();  
          for(Opportunity opp: allOpps) {
              accIds.add(opp.AccountId);
              opp.Customer_Onboarded__c = 'Onboarding completed';
          }
          
          List<Account> allAccs = [SELECT Id, Customer_Onboarded__c FROM Account WHERE Id IN: accIds];
          for(Account acc: allAccs)
              acc.Customer_Onboarded__c = 'Onboarding completed';
              
          update allOpps;
          update allAccs;
      }
  }
  
  private void qualifiedTasks(){
    for(task t:this.newTasks){

            if(t.Group_Task_Id__c !=null && t.Group_Task_Id__c !=''){
            
            
            If(t.Status == 'Completed') {
            PrimaryTaskId = t.id;
            }
            
                statusChangingGroupTaskIds.add(t.Group_Task_Id__c);
        MapStatusChangingTasks.put(t.Group_Task_Id__c,t.Status);
            }

    }
  }

  private void fetchTasksWithGroupTaskIds(){
        system.debug('KG--> statusChangingGroupTaskIds '+ statusChangingGroupTaskIds);
        if(statusChangingGroupTaskIds !=null ){
            this.statusChangingTasks = [select Status,Group_Task_Id__c, Primary_Group_Task__c from task where Group_Task_Id__c in:statusChangingGroupTaskIds];
        }
    
  }
  
  private void UpdateTasks(){
    for(task t:this.statusChangingTasks){
      t.Status = MapStatusChangingTasks.get(t.Group_Task_Id__c);
      t.Primary_Group_Task__c = PrimaryTaskId;
    }
  }
  
  private void CommitTasks(){
        system.debug('KG--> this.statusChangingTasks.size() '+ this.statusChangingTasks.size());
    if(this.statusChangingTasks.size()>0){
      update this.statusChangingTasks;
    }
  }
    
  private void deleteTasksWithGroupTaskIds(){
        system.debug('KG--> statusChangingGroupTaskIds '+ statusChangingGroupTaskIds);
        if(statusChangingGroupTaskIds !=null ){
            this.deleteTasks = [select Status,Group_Task_Id__c, Primary_Group_Task__c, Is_This_Primary_Group_Task__c from task where Group_Task_Id__c in:statusChangingGroupTaskIds and Primary_Group_Task__c != '' and Is_This_Primary_Group_Task__c = false];
        }
    
  }
  
    private void CommitDeleteTasks(){
        system.debug('KG--> this.statusChangingTasks.size() '+ this.statusChangingTasks.size());
    if(this.deleteTasks.size()>0){
      delete this.deleteTasks;
    }
  }
    
    public void CreatedFromPortal() {
        User usr = [SELECT IsPortalEnabled, Contact.AccountId FROM User WHERE Id = :UserInfo.getUserId()];
        if (usr.IsPortalEnabled) {
            for (Task tsk : this.newTasks) {
                tsk.WhatId = usr.Contact.AccountId;
            }
        }
    }
  
}