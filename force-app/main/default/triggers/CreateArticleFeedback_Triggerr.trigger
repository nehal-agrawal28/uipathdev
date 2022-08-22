trigger CreateArticleFeedback_Triggerr on FeedItem(after insert) {
  CreateArticleFeedback_helper.updateRelatedCaseStatus(Trigger.new);
}