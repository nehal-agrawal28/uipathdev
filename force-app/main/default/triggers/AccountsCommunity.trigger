/**
 * TO DO: This trigger is a temporary workaround and will be merge with the package trigger.
 */
trigger AccountsCommunity on Account(
  after delete,
  after insert,
  after update,
  before delete,
  before insert,
  before update
) {
  // Creates Domain class instance and calls appropriate overridable methods according to Trigger state
  fflib_SObjectDomain.triggerHandler(AccountsCommunity.class);
}