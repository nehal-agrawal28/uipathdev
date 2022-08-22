public without sharing class SharePartnerToUser_PP extends AbstractQueueable {
  List<User> users;
  public SharePartnerToUser_PP(List<User> users) {
    super('SharePartnerToUser_PP');
    this.users = users;
  }

  public override void work() {
    Set<Id> accountIds = new Set<Id>(Collection.of(this.users).pluckIds(User.AccountId));

    AccountRelationshipsSelector_PP accountRelationshipsSelector = (AccountRelationshipsSelector_PP) Application_PP.Selector.newInstance(
      AccountRelationship.SObjectType
    );
    List<AccountRelationship> relationships = accountRelationshipsSelector.selectByAccountIds(accountIds, false);

    ((AccountsService_PP) Application_PP.Service.newInstance(AccountsService_PP.class)).shareToPartners(relationships);
  }
}