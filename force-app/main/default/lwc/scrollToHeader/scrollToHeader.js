import {LightningElement, wire, api} from 'lwc';

import { publish, MessageContext } from "lightning/messageService";
import SCROLL_TARGET_CHANNEL from "@salesforce/messageChannel/ScrollTargetMessageChannel__c";

export default class ScrollToHeader extends LightningElement {

    //2. Wiring the MessageContext to a property
    @wire(MessageContext)
    messageContext;

    @api menuItem1;
    @api menuItem2;
    @api menuItem3;
    @api menuItem4;
    @api menuItem5;
    @api menuItem6;

   //3. Handling the user input.
  //which in our case is going to be a button click
  handleClick(event) {
    const message = {
      divId: event.target.value, //data-id="redDiv"
    };

    //4. Publishing the message
    publish(this.messageContext, SCROLL_TARGET_CHANNEL, message);
  }
}