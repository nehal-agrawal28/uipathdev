public with sharing class DeactivatePartnerUsersController_PP {
  @AuraEnabled
  public static boolean deactivatePartnerUsers(String accountId) {
    AbstractQueueable.enqueue(new DeactivatePartnerUsersAction_PP(accountId));
    return true;
  }
}