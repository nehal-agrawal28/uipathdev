public without sharing class AssignGroupAction_PP extends AbstractQueueable {
  List<User> users;
  String groupName;

  public AssignGroupAction_PP(List<User> users, String groupName) {
    super('AssignGroupAction_PP');
    this.users = users;
    this.groupName = groupName;
  }

  public override void work() {
    ((GroupsService_PP) Application_PP.Service.newInstance(GroupsService_PP.class))
      .assignGroup(this.users, this.groupName);
  }
}