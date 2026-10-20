({
    /** Loads the TSANet Case info for the quick action; closes with a toast when it cannot be loaded. */
	init : function(cmp, event, helper) {
        cmp.set('v.isLoaded', false)
        helper.fetch(cmp, 'c.getTSANetInfo', { recordId: cmp.get('v.recordId') }).then(data => {
            if(!data || !data.record){
                helper.closeWithError('This action is only available on a TSANet Case.')
                return
            }
            cmp.set('v.record', data.record)
            cmp.set('v.state', data)
            cmp.set('v.isLoaded', true)
        }).catch(message => {
            helper.closeWithError(message)
        })
	},

    /** Closes the quick action panel and refreshes the record page behind it. */
    close : function(){
        $A.get('e.force:closeQuickAction').fire()
        $A.get('e.force:refreshView').fire()
    }
})
