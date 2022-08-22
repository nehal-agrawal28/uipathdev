trigger ProductTrigger on Product2 (before insert, before update, before delete, after insert, after update, after delete, after undelete) {

    // Instantiate the ProductTriggerHandler Class. All the methods and trigger logic should be written in the ProductTriggerHandler
    new ProductTriggerHandler().run();
}