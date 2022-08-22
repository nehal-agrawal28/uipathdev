trigger Products_SL on Product2(after insert, after update) {
  fflib_SObjectDomain.triggerHandler(Products_SL.class);
}