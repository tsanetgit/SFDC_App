import { LightningElement, api } from 'lwc';
import { CloseActionScreenEvent } from 'lightning/actions';
 
export default class TsaNetCaseSubmitSuccess extends LightningElement {

    @api message
    @api description

    @api status

    get iconName(){
        switch(this.status){
            case 'success':
                return 'utility:success'
            case 'error':
                return 'utility:error'
            case 'warning':
                return 'utility:warning'
            default:
                return 'utility:success'
        }
    }
}