public with sharing class ContentController_PP {
  @AuraEnabled(cacheable=true)
  public static List<ConnectApi.ManagedContentVersion> getManagedContentByTopic(String topicId) {
    List<ConnectApi.ManagedContentVersion> results;

    String language = 'en_US';
    String communityId = Network.getNetworkId();
    List<Topic> topics = [SELECT Name FROM Topic WHERE Id = :topicId AND networkId = :communityId];

    List<String> topicNames = new List<String>(Utilities_PP.pluckStringField(topics, Topic.Name));

    try {
      ConnectApi.ManagedContentVersionCollection contentList = ConnectApi.ManagedContent.getManagedContentByTopics(
        communityId,
        topicNames,
        0,
        25,
        language,
        'cms_document',
        true
      );
      results = contentList.items;
    } catch (Exception e) {
      System.debug('Error Message : ' + e);
      results = new List<ConnectApi.ManagedContentVersion>();

      AuraHandledException auraException = new AuraHandledException(e.getMessage());
      auraException.setMessage(e.getMessage());
      throw auraException;
    }

    return results;
  }

  @AuraEnabled(cacheable=true)
  public static List<ConnectApi.ManagedContentVersion> getManagedContentUrl(String contentKey, String contentType) {
    List<ConnectApi.ManagedContentVersion> results;

    String language = 'en_US';
    String communityId = Network.getNetworkId();
    List<String> contentKeys = new List<String>();
    contentKeys.add(contentKey);

    try {
      ConnectApi.ManagedContentVersionCollection contentList = ConnectApi.ManagedContent.getManagedContentByContentKeys(
        communityId,
        contentKeys,
        0,
        25,
        language,
        contentType,
        true
      );
      results = contentList.items;
    } catch (Exception e) {
      System.debug('Error Message : ' + e);
      results = new List<ConnectApi.ManagedContentVersion>();

      AuraHandledException auraException = new AuraHandledException(e.getMessage());
      auraException.setMessage(e.getMessage());
      throw auraException;
    }

    return results;
  }
}