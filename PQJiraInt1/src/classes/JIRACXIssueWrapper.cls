public class JIRACXIssueWrapper {

    private JIRACXIssue__c issue {get; set;}
    private boolean collapsed {get; set;}
    private boolean isWatching {get; }
        
    public JIRACXIssue__c getIssue(){
        return issue;
    }
    public void setIssue(JIRACXIssue__c inIssue){
        this.issue = inIssue;
    }
    public boolean getCollapsed(){
        system.debug('getting Collapsed - ' + this.collapsed);
       return this.collapsed;
    }
    public void setCollapsed(boolean newCollapse){
        system.debug('Setting collapsed - ' + newCollapse);
        this.collapsed = newCollapse;
    }
    public PageReference toggleCollapse(){
        system.debug('toggle collapse to - ' + !this.collapsed);
        setCollapsed(!this.collapsed);
        return null;
    }
    public JIRACXIssueWrapper(JIRACXIssue__c inIssue, boolean inCollapse){
        this.issue= inIssue;
        this.collapsed = inCollapse;
    }
    public boolean getIsWatching(){
    	for(JIRA_Watcher__c jw : issue.JIRA_Watchers__r ){
    		if (jw != null && jw.SFUsers__c != null && jw.SFUsers__r.id == UserInfo.getUserId()){
				return true;    			
    		}
    	}
    	return false;
    }
}