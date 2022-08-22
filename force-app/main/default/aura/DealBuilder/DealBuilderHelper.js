({
  fetchInitialData: function (component, event, helper, accountId) {
    helper.resetAll(component, event, helper);
    component.set("v.showSpinner", true);

    let action = component.get("c.getInitialData");
    action.setParam("accountId", accountId);
    action.setCallback(this, function (response) {
      if (response.getState() === "SUCCESS") {
        let wrapper = response.getReturnValue();
        component.set("v.vfBaseUrl", wrapper.vfBaseUrl);
        component.set("v.account", wrapper.account);
        component.set("v.contractList", wrapper.contractList);
        component.set("v.isOppCreatable", wrapper.isOppCreatable);

        if (wrapper.account && wrapper.account.Id) {
          component.set("v.accountFetched", true);
        }
        // show Contract table
        if (wrapper.hasRRPermission || (wrapper.contractList && wrapper.contractList.length > 0)) {
          component.set("v.showContractSection", true);
        }
        // hide timeline if no active contract
        if (wrapper.hasRRPermission && (!wrapper.contractList || wrapper.contractList.length <= 0)) {
          component.set("v.hideTimeLine", true);
          setTimeout(() => {
            helper.tabVisibility(component, event, helper, "tabularView");
          }, 1000);
        }
      } else {
        console.log("Error DealBuilderController.getInitialData:" + JSON.stringify(response.getError()));
        helper.showToast("error", "Error", "Something went wrong while fetching data");
      }
      component.set("v.showSpinner", false);
    });
    $A.enqueueAction(action);
  },

  listenIFrameMessage: function (component, event, helper) {
    // IFRAME message listener
    var eventMethod = window.addEventListener ? "addEventListener" : "attachEvent";
    var eventer = window[eventMethod];
    window.saveCmpRef = component;
    var messageEvent = eventMethod == "attachEvent" ? "onmessage" : "message";
    eventer(
      messageEvent,
      (e) => {
        // debugger;
        var key = e.message ? "message" : "data";
        var contentHeight = e[key];
        var iFrame = document.getElementById("idIframe");
        if (iFrame) {
          if (contentHeight && contentHeight > 450) {
            iFrame.height = contentHeight + 50 + "px";
          } else {
            iFrame.height = "500px";
          }
        }
      },
      false
    );
  },

  tabVisibility: function (component, event, helper, tabId) {
    // reset all
    for (let item of document.querySelectorAll(".slds-tabs_default__item")) {
      item.classList.remove("slds-is-active");
    }
    for (let item of document.querySelectorAll(".slds-tabs_default__content")) {
      item.classList.remove("slds-show");
      item.classList.add("slds-hide");
    }

    // make selected tab active
    let contractTableTabs = component.get("v.contractTableTabs");
    contractTableTabs[tabId] = true;
    component.set("v.contractTableTabs", contractTableTabs);

    let currentTab = document.querySelector(`[data-item=${tabId}]`).closest("li");
    currentTab.classList.add("slds-is-active");
    document.getElementById(tabId).classList.remove("slds-hide");
    document.getElementById(tabId).classList.add("slds-show");
  },

  resetAll: function (component, event, helper) {
    component.set("v.accountFetched", false);
    component.set("v.showContractSection", false);
    component.set("v.showNewOppModal", false);
    component.set("v.showAccountModal", false);
  },

  showToast: function (type, title, message, mode) {
    mode = mode || "dismissible";
    let toast = $A.get("e.force:showToast");
    if (toast) {
      toast
        .setParams({
          type: type,
          title: title,
          message: message,
          mode: mode
        })
        .fire();
    } else {
      alert(message);
    }
  }
});