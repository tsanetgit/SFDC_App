import { LightningElement, api } from 'lwc';
 
export default class TsaNetActionModalSubmitResult extends LightningElement {

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

    get iconClass(){
        switch(this.status){
            case 'success':
                return 'success-icon'
            case 'error':
                return 'error-icon'
            case 'warning':
                return 'warning-icon'
            default:
                return 'success-icon'
        }
    }
}