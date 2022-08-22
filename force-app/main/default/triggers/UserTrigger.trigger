trigger UserTrigger on User(after insert, after update) {
  // Remove 11.5.21 as it's causing partner portal registrations to fail.
  // if (Trigger.isAfter && Trigger.isInsert) {
  //     UserTriggerHandler.ShareOpportunities(Trigger.new);
  // }
  if (Trigger.isAfter && Trigger.isUpdate) {
    UserTriggerHandler.removeInactiveLicenses(Trigger.new);
  }
}