({
	fetch : function(cmp, method, params) {
        return new Promise($A.getCallback(function(resolve, reject) {
            const action = cmp.get(method)
            params && action.setParams(params)
            action.setCallback(this, response => {
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
    toast : function(title, type, message) {
        $A.get("e.force:showToast").setParams({ title: title, type: type, message: message }).fire()
    },

    /** Shows an error toast and closes the quick action instead of leaving an empty panel. */
    closeWithError : function(message) {
        this.toast('Error', 'error', message)
        $A.get('e.force:closeQuickAction').fire()
    }
})