({
  doInit: function (component, event, helper) {
    let pageRef = component.get("v.pageReference");
    let accountId = pageRef.state.c__accountId;

    if (accountId) {
      // fetch data from server
      helper.fetchInitialData(component, event, helper, accountId);
      // add iframe message listner
      helper.listenIFrameMessage(component, event, helper);
    } else {
      component.set("v.showAccountModal", true);
    }
  },

  // backToAccount: function(component, event, helper) {
  // 	event.preventDefault();
  // 	event.stopPropagation();

  // 	$A.get("e.force:navigateToSObject")
  // 		.setParams({
  // 			recordId: component.get("v.account").Id
  // 		})
  // 		.fire();
  // },

  // handleMenuSelect: function(component, event, helper) {
  // 	let selectedMenuItemValue = event.getParam("value");
  // 	if (selectedMenuItemValue == "NewOpportunityModal") {
  // 		component.set("v.showNewOppModal", true);
  // 	}
  // },

  showOpportunityModal: function (component, event, helper) {
    component.set("v.showNewOppModal", true);
  },

  hideOpportunityModal: function (component, event, helper) {
    component.set("v.showNewOppModal", false);
  },

  showAccountModal: function (component, event, helper) {
    component.set("v.showAccountModal", true);
  },

  hideAccountModal: function (component, event, helper) {
    let account = component.get("v.account");
    if (account && account.Id) {
      component.set("v.showAccountModal", false);
    } else {
      window.history.back();
    }
  },

  tabClicked: function (component, event, helper) {
    let tabId = event.target.dataset.item;
    if (tabId) {
      helper.tabVisibility(component, event, helper, tabId);
    }
  },

  refreshAllData: function (component, event, helper) {
    helper.fetchInitialData(component, event, helper, component.get("v.account").Id);
  }
});