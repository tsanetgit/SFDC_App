({
    /** Resolves the parent TSANet Case Id, loads its info and renders the Create Note modal. */
	init : function(cmp, event, helper) {
        const recordId = helper.resolveRecordId(cmp)
        cmp.set('v.isLoaded', false)

        // Opened without a parent record (e.g. "New" on the TSANet Notes list view): a note needs a TSANet Case.
        if(!recordId){
            helper.closeWithError(cmp, helper.NO_CASE_MESSAGE)
            return
        }

        cmp.set('v.recordId', recordId)
        helper.fetch(cmp, 'c.getTSANetInfo', { recordId: recordId }).then(data => {
            if(!data || !data.record){
                helper.closeWithError(cmp, helper.NO_CASE_MESSAGE)
                return
            }
            cmp.set('v.record', data.record)
            cmp.set('v.state', data)
            cmp.set('v.isLoaded', true)
        }).catch(message => {
            helper.closeWithError(cmp, message)
        })
	},

    close : function(){
        history.back()
        $A.get('e.force:refreshView').fire()
    }
})
