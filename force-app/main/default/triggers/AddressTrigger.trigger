/**
 * Created by komal.karnawat on 2019-04-23.
 */

trigger AddressTrigger on Address__c (before insert, before update, before delete, after insert, after update, after delete, after undelete) {

    // Instantiate the AddressTriggerHandler Class. All the methods and trigger logic should be written in the AddressTriggerHandler
    new AddressTriggerHandler().run();

}