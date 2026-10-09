import { LightningElement, api, track } from 'lwc';

import { TYPING_INTERVAL, RICH_TEXT_FORMATS } from 'c/tsaNetConstants'

import { getActionRequestParamLabel } from 'c/tsaNetHelper'

export default class TsaNetActionModalFormField extends LightningElement {

    @api mode

    get label(){
        return getActionRequestParamLabel(this.mode)
    }

    get richTextFormats() {
        return RICH_TEXT_FORMATS
    }

    @track value

    @track typingTimer

    handleChangeField(event){
        clearTimeout(this.typingTimer)
        this.value = event?.target?.value

        this.typingTimer = setTimeout(() => {
            this.dispatchEvent(new CustomEvent('change', { detail: { value: this.value }}))
        }, TYPING_INTERVAL)
    }
}