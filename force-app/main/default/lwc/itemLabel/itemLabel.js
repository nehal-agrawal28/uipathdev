import { LightningElement, api } from "lwc";

export default class ItemLabel extends LightningElement {
  @api required;
  @api desc;
  @api label;
}