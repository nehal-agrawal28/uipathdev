public without sharing class GroupsSelector_PP extends fflib_SObjectSelector {
  @TestVisible
  private static final String GROUP_TYPE_QUEUE = 'Queue';
  @TestVisible
  private static final String GROUP_TYPE_REGULAR = 'Regular';

  @TestVisible
  private static Map<String, Group> groupByDeveloperName;
  @TestVisible
  private static Map<String, Group> queueByDeveloperName;

  public List<Schema.SObjectField> getSObjectFieldList() {
    return new List<Schema.SObjectField>{
      Group.Id,
      Group.DeveloperName,
      Group.DoesIncludeBosses,
      Group.DoesSendEmailToMembers,
      Group.Email,
      Group.Name,
      Group.RelatedId,
      Group.Type
    };
  }

  public Schema.SObjectType getSObjectType() {
    return Group.SObjectType;
  }

  public static void enableCacheAll() {
    if (isCacheEnabled()) {
      // Cache already populated
      return;
    }

    groupByDeveloperName = new Map<String, Group>();
    for (Group grp : new GroupsSelector_PP().selectAllGroups()) {
      groupByDeveloperName.put(grp.DeveloperName.toLowerCase(), grp);
    }

    queueByDeveloperName = new Map<String, Group>();
    for (Group grp : new GroupsSelector_PP().selectAllQueues()) {
      queueByDeveloperName.put(grp.DeveloperName.toLowerCase(), grp);
    }
    cacheGroups(queueByDeveloperName, new GroupsSelector_PP().selectAllQueues());
  }

  public List<Group> selectById(Set<Id> idSet) {
    return (List<Group>) selectSObjectsById(idSet);
  }

  public List<Group> selectAllGroups() {
    return (List<Group>) Database.query(
      newQueryFactory(false, false, true).setCondition('Type=:GROUP_TYPE_REGULAR').toSOQL()
    );
  }

  public List<Group> selectAllQueues() {
    return (List<Group>) Database.query(
      newQueryFactory(false, false, true).setCondition('Type=:GROUP_TYPE_QUEUE').toSOQL()
    );
  }

  public List<Group> selectGroupByDeveloperName(Set<String> names) {
    if (isCacheEnabled()) {
      return selectFromCache(groupByDeveloperName, names);
    }

    fflib_QueryFactory queryFactory = newQueryFactory(false, false, true);
    queryFactory.setCondition('DeveloperName IN :names AND Type=:GROUP_TYPE_REGULAR');
    return (List<Group>) Database.query(queryFactory.toSOQL());
  }

  public List<Group> selectQueueByDeveloperName(Set<String> names) {
    if (isCacheEnabled()) {
      return selectFromCache(queueByDeveloperName, names);
    }

    fflib_QueryFactory queryFactory = newQueryFactory();
    queryFactory.setCondition('DeveloperName IN :names AND Type=:GROUP_TYPE_QUEUE');
    return (List<Group>) Database.query(queryFactory.toSOQL());
  }

  private static void cacheGroups(Map<String, Group> groupByDeveloperName, List<Group> groups) {
    groupByDeveloperName = new Map<String, Group>();
    for (Group grp : groups) {
      groupByDeveloperName.put(grp.DeveloperName.toLowerCase(), grp);
    }
  }

  private static Boolean isCacheEnabled() {
    return groupByDeveloperName != null || queueByDeveloperName != null;
  }

  private static List<Group> selectFromCache(Map<String, Group> cache, Set<String> names) {
    List<Group> result = new List<Group>();
    for (String name : names) {
      name = name.toLowerCase();
      if (cache.containsKey(name)) {
        result.add(cache.get(name));
      }
    }
    return result;
  }

  public List<Group> selectByRelatedIdsAndTypes(Set<Id> relatedIds, Set<String> types, Boolean withSharing) {
    if (withSharing) {
      return (List<Group>) Database.query(
        newQueryFactory(true, true, true).setCondition('RelatedId IN :relatedIds AND Type IN :types').toSOQL()
      );
    } else {
      return (List<Group>) Database.query(
        newQueryFactory(false, false, true).setCondition('RelatedId IN :relatedIds AND Type IN :types').toSOQL()
      );
    }
  }
}