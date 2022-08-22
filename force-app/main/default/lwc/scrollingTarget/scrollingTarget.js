import { LightningElement, wire, api } from 'lwc';

import {
    subscribe,
    MessageContext
  } from "lightning/messageService";
  import SCROLL_TARGET_CHANNEL from "@salesforce/messageChannel/ScrollTargetMessageChannel__c";

export default class ScrollingTarget extends LightningElement {

  @api divId;

  //2. Wiring MessageContext to a property
  @wire(MessageContext)
  messageContext;
  receivedMessage;
  subscription = null;

  //3. Handling the user input
  connectedCallback() {
    console.log("in handle subscribe");
    if (this.subscription) {
      return;
    }

    //4. Subscribing to the message channel
    this.subscription = subscribe(
      this.messageContext,
      SCROLL_TARGET_CHANNEL,
      (message) => {
        this.handleMessage(message);
      }
    );
  }

  handleMessage(message) {
    this.receivedMessage = message
      ? JSON.stringify(message.divId, null, "\t")
      : "no message";

    this.handleValueChange(this.receivedMessage);
  }

  //a method called in setter
  handleValueChange(receivedMessage) {
    const topDiv = this.template.querySelector('[data-id=' + receivedMessage + ']');
    if(topDiv!==null && topDiv!==undefined && topDiv!==''){
      topDiv.scrollIntoView({behavior: "smooth", block: "center", inline: "nearest"});
    }
  }
}