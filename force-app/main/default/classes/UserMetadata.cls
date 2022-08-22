/**
 * Responsibility: Lazy loads User related metadata and provides a single shared static cached access point
 */
public with sharing class UserMetadata {
  public static Set<Id> PortalProfileIds {
    get {
      PortalProfileIds = new Map<Id, Profile>(
          [
            SELECT Id
            FROM Profile
            WHERE
              Name IN (
                'Global Partner Portal Admin',
                'Global Partner Portal Content Login User',
                'Global Partner Portal Content User',
                'Global Partner Portal Login Admin',
                'Global Partner Portal Login Manager',
                'Global Partner Portal Login User',
                'Global Partner Portal Manager',
                'Global Partner Portal User',
                'Apex Testing Only'
              )
          ]
        )
        .keyset();
      return PortalProfileIds;
    }
    set;
  }
}