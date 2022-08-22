public interface ICampaignsSelector_PP extends fflib_ISObjectSelector {
  List<Campaign> selectById(Set<Id> idSet);
  List<Campaign> selectByName(String campaignName);
  List<Campaign> selectByName(Set<String> campaignName);
}