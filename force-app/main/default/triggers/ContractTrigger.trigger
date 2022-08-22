trigger ContractTrigger on Contract (after insert) {
    new ContractTriggerHandler().run();
}