({

    handleClose : function(cmp, event, helper){
        this.LightningConfirm.open({
            message: 'Do you really want to close this case? This action cannot be undone.',
            label: 'Confirm Case Closure',
            variant: 'header',
            theme: 'warning',
        }).then((result) => {
            if (result) {
                helper.close(cmp, event, helper);
        	} else {
                helper.navigateToRecord(cmp, event, helper)
            }
        });
    },

    close : function(cmp, event, helper){
        cmp.set('v.isLoading', true)
        helper.fetch(cmp, 'c.closeTSANetCase', { tsaNetCaseId: cmp.get('v.recordId') }).then(result => {
            cmp.set('v.isLoading', false)
            try {
            	const record = JSON.parse(result)
                if(Object.prototype.hasOwnProperty.call(record, 'status') && record.status == 'CLOSED'){
                	helper.toast('Success', 'success', 'Case has been closed successfully!')
                }
            	helper.navigateToRecord(cmp)
            } catch(e){
                console.debug(e)
                helper.toast('Error', 'error', result)
            	helper.navigateToRecord(cmp)
            }
        }).catch(error => {
            	if(error == 'Unauthorized'){
                    helper.fetch(cmp, 'c.getNewAccessToken', null).then(result => {
                        if(result){
                            helper.fetch(cmp, 'c.closeTSANetCase', { tsaNetCaseId: cmp.get('v.recordId') }).then(retryResult => {
                                cmp.set('v.isLoading', false)
                                try {
                                    const record = JSON.parse(retryResult)
                                    if(Object.prototype.hasOwnProperty.call(record, 'status') && record.status == 'CLOSED'){
                                        helper.toast('Success', 'success', 'Case has been closed successfully!')
                                    }
                                    helper.navigateToRecord(cmp)
                                } catch(e){
                                    console.debug(e)
                                    helper.toast('Error', 'error', retryResult)
                                    helper.navigateToRecord(cmp)
                                }
                            })
                        } else {
                            console.error(error)
                            helper.toast('Error', 'error', error)
                        }
                    }).catch(err => {
                        console.error(err)
                        helper.toast('Error', 'error', err)
                    })
                } else {
                    console.error(error)
                    helper.toast('Error', 'error', error)
                }
        })
    },

	fetch : function(cmp, method, params) {
        return new Promise($A.getCallback(function(resolve, reject) {
            cmp.set('v.isLoading', true)
            const action = cmp.get(method)
            params && action.setParams(params)
            action.setCallback(this, response => {
                cmp.set('v.isLoading', false)
                const state = response.getState()
                switch (state) {
                case 'SUCCESS': resolve(response.getReturnValue())
                break
                case 'INCOMPLETE': console.log('INCOMPLETE')
                break
                case 'ERROR': {
                    const errors = response.getError()
                    errors
                    ? reject(errors[0].message)
                    : console.error('Unknown error')
                    break
                }
                default: console.log(state)
            }
                               })
            $A.enqueueAction(action)
        }))
    },

    navigateToRecord: function(cmp) {
        const navService = cmp.find("navService");
        if(navService){
            const pageReference = {
                type: 'standard__recordPage',
                attributes: {
                    recordId: cmp.get("v.recordId"),
                    objectApiName: "tsanetconnect__TSANetCase__c",
                    actionName: "view"
                }
            }
            navService.navigate(pageReference)

            $A.get('e.force:refreshView').fire()
        }
    },

    toast : function(title, type, message) {
        $A.get("e.force:showToast").setParams({ title: title, type: type, message: message }).fire()
    }
})