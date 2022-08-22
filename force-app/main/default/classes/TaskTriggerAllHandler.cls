/********************************************************************************************************
*    Handler Name:  TaskTriggerAllHandler.cls
*    Author: Mirela Chituc (mirela.chituc@uipath.com) 
*    Date:  27/4/2021
*    
*    Trigger: TaskTriggerAll.trigger
*    Test class: TaskTriggerAllHandlerTest.cls
********************************************************************************************************/

public without sharing class TaskTriggerAllHandler {
    
    //Handler for before insert methods
    public void onBeforeInsert(list<Task> newList , map<id, Task> newMap) {
    
    }
    //Handler for after insert methods
    public void onAfterInsert(list<Task> newList , map<id, Task> newMap) {
        // setUpContactStatus(newList, null, null, 'insert');
    }
    //Handler for before Update methods
    public void onBeforeUpdate(list<Task> newList, map<id, Task> newMap, map<id, Task> oldMap) {
       
    }
    //Handler for after Update methods
    public void onAfterUpdate(list<Task> newList, map<id, Task> newMap,  map<id, Task> oldMap) {
        // setUpContactStatus(newList, null, oldMap, 'update');
    }

    //Handler for before Deletes methods
    public void onBeforeDelete(list<Task> oldList , map<id, Task> oldMap) {

    }
    //Handler for after Deletes methods
    public void onAfterDelete(list<Task> oldList , map<id, Task> oldMap) {
        // setUpContactStatus(null, oldList, null, 'delete');
    }
    
   
    /*private void setUpContactStatus(List<Task> TaskList, List<Task> oldTaskList, Map<Id, Task> TaskOldMap, String triggerAction) {
        Set<Id> contactIds = new Set<Id>();
        Set<Id> LeadIds = new Set<Id>();
        
        if(TaskList != null) {
            for(Task tk: TaskList) {
                if(triggerAction == 'insert') { 
                    if(tk.WhoId != null) {
                        String sWhoId = String.valueOf(tk.WhoId); 
                        if(sWhoId != null) {
                            if(sWhoId.startsWith('00Q')) {
                                LeadIds.add(tk.WhoId);
                            } else {
                                contactIds.add(tk.WhoId);
                            }
                        }
                    }
                }
                if(triggerAction == 'update') { 
                    Task oldTask = TaskOldMap.get(tk.Id);
                    if(tk.WhoId != oldTask.WhoId) {
                        if(tk.WhoId != null) {
                            String sWhoId = String.valueOf(tk.WhoId);
                            if(sWhoId.startsWith('00Q')) {
                                LeadIds.add(tk.WhoId);
                            } else {
                                contactIds.add(tk.WhoId);
                            }
                        }
                        if(oldTask.WhoId != null) {
                            String sOldWhoId = String.valueOf(oldTask.WhoId);
                            if(sOldWhoId.startsWith('00Q')) {
                                leadIds.add(oldTask.WhoId);
                            } else {
                                contactIds.add(oldTask.WhoId);
                            }
                        }
                    }
                }
            }
        } else {
            for(Task tk: oldTaskList) {
                if(tk.WhoId != null) {
                    String sWhoId = String.valueOf(tk.WhoId);
                    if(sWhoId.startsWith('00Q')) {
                        LeadIds.add(tk.WhoId);
                    } else {
                        contactIds.add(tk.WhoId);
                    } 
                } 
            }
        }

        if(LeadIds.size() > 0) {
            List<Lead> LeadsWithContact = [SELECT Id, ConvertedContactId FROM Lead WHERE Id IN: LeadIds AND ConvertedContactId != null];
            for(Lead l: LeadsWithContact) {
                contactIds.add(l.ConvertedContactId);
            }
        }
        
        if(contactIds.size() > 0) {
            List<Contact> contactsToUpdate = [SELECT Id, Contact_Status__c FROM Contact WHERE Id IN: contactIds];
            for(Contact c: contactsToUpdate)
                c.Contact_Status__c = '';
            update contactsToUpdate;
        }
    }*/
}