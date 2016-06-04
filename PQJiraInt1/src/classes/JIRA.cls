public with sharing class JIRA {

    // Change values in this class according to you JIRA/Salesforce coordinates.

    public static String baseUrl = 'https://lynch22.atlassian.net'; // Base URL of your JIRA instance
    public static String systemId = '1'; // Salesforce Connector System ID in JIRA
//    public static String username = 'kenalynch';  // JIRA username
//    public static String password = 'pass1234'; // JIRA password
    public static String username = 'KLynch';  // JIRA username
    public static String password = 'LeadDev@1'; // JIRA password

    public static String username_sersol = 'klynch';  // JIRA username
    public static String password_sersol = 'DevPost2016@23'; // JIRA password
    public static String username_pq = 'KLynch';  // JIRA username
    public static String password_pq = 'LeadDev@1'; // JIRA password

    public static String agentProfileName = 'System Administrator'; // Jira agent profile name in Salesforce

    // Constructs Basic Http Authentication header from provided credentials
    public static String authHeader(String u, String p) {
        Blob headerValue = Blob.valueOf(u + ':' + p);
        return 'Basic ' + EncodingUtil.base64Encode(headerValue);
    }

    // Sends a request and returns the response
    public static HttpResponse sendRequest(HttpRequest req) {
        Http http = new Http();
        return http.send(req);
    }
    
    // Create an email/chatter message for the JIRA Issue watchers for a significant update
    public boolean updateWatchers(JIRACXIssue__c jira, String watcherMsg){
		
        return true;
    }
    
    
    // Detects whether current user is not JIRA agent. By calling this you can make sure that
    // infinite loops won't happen in triggers (for instance when synchronizing an issue with JIRA)
    public static Boolean currentUserIsNotJiraAgent() {
        Boolean allow = false;
        List<Profile> jiraAgentProfile = [SELECT Id FROM Profile WHERE Name=:JIRA.agentProfileName];
        if (!jiraAgentProfile.isEmpty()) {
            String jiraProfileAgentId = String.valueOf(jiraAgentProfile[0].id);
            allow = UserInfo.getProfileId() != jiraProfileAgentId;
        }
        return allow || Test.isRunningTest();
    }
    
    // JIRA REST API Classes
    public class JIRASearchResult {
        public String expand;
        public Integer startAt;
        public Integer maxResults;
        public Integer total;
    }
    
    public class JIRAProjects {
        public List<JIRAProject> projs;
    }
    public class JIRAProject {
        private String self {get; set;}
        private String id {get; set;}
        private String key {get; set;}
        private String name {get; set;}
        private fld_avatar aURL {get; set;}
        
        public String getSelf(){ return this.self;}
        public void setSelf(String inSelf){ this.self = inSelf;}        
        public String getId(){ return this.id;}
        public void setId(String inId){ this.id = inId;}        
        public String getKey(){ return this.Key;}
        public void setKey(String inKey){ this.key = inKey;}        
        public String getName(){ return this.Name;}
        public void setName(String inName){ this.name = inName;}        
        public fld_avatar getAURL(){ return this.aURL;}
        public void setAURL(fld_avatar inAURL){ this.aURL = inAURL;}        
        
    }
    public class AvatarURL {
        public String size1;
        public String size2;
        public String size3;
        public String size4;
    }

    public class JIRAFieldResponse {
        //String expand;
        //Integer startAt;
        // maxResults;
        //Integer thetotal;
        public List<JIRACXField.JIRAField> fields;
        
        public List<JIRACXField.JIRAField> getFields() { return fields; }
    }
    
    public class JIRAIssueResponse {
        public String expand {get; set;}
        public Integer startAt {get; set;}
        public Integer maxResults {get; set;}
        public Integer thetotal {get; set;}
        public List<JIRAIssue> issues {get; set;}
        
        public List<JIRAIssue> getIssues() { return issues; }
    }
    public class JIRAIssue {
        public String expand {get; set;}
        public String id {get; set;}
        public String self {get; set;}
        public String key {get;set;}
        public IssueFields fields {get; set;}
        ///String timespent;
        
        public String getKey() { return key; }
        
    }
    public class Fields {
        public String self {get; set;}
        public String id {get; set;}
        public String Description {get; set;}
        public String iconUrl {get; set;}
        public String name {get; set;}
        public boolean subtask {get; set;}
        public Integer avatarId {get; set;}
    }

    public class IssueFields {
        public String summary {get; set;}
        public String description {get; set;}
        public Resolution resolution {get; set;}
        public JIRAProject project {get; set;}
        public fld_assignee assignee {get; set;}
        public String updated {get; set;}
        public Status status  {get; set;}
        
    }
    public class Status {
        public String self {get; set;}
        public String description {get; set;}
        public String iconURL {get; set;}
        public String name {get; set;}
        public String id {get; set;}
        public StatusCategory statusCategory {get; set;}
    }

    public class Resolution {
        public String self {get; set;}
        public String id {get; set;}
        public String description {get; set;}
        public String name {get; set;}
    }

    public class StatusCategory {
        public String self {get; set;}
        public String id {get; set;}
        public String key {get; set;}
        public String colorName {get; set;}
        public String name {get; set;}
    }
    
    public class fld_avatar {
        public String URL48px {get; set;}
        public String URL24px {get; set;}
        public String URL16px {get; set;}
        public String URL32px {get; set;}
    }
    
    public class fld_assignee {
        public String self {get; set;}
        public String name {get; set;}
        public String key {get; set;}
        public String emailAddress {get; set;}
        public fld_avatar avatarURLs {get; set;}
        public String displayName {get; set;}
        public boolean isActive {get; set;}
        public String timezone {get; set;}
    }

    public class IssueWatcherResponse {
        public String self {get; set;}
        public boolean isWatching {get; set;}
        public integer watchCount {get; set;}
        public List<IssueUser> watchers {get; set;}
        
        public List<IssueUser> getIssueWatchers() { return watchers; }
    }

    public class IssueUser {
         public String self {get;set;}
         public String name {get;set;}
         public String displayname {get;set;}
         public boolean active {get;set;}
        
        public String getSelf() { return self ; }
        public String getName() { return name ; }
        public String getDisplayName() { return DisplayName ; }
        public boolean getActive() { return Active ; }
        
    }

    public class IssueCommentResponse {
         public Integer startAt {get;set;}
         public Integer maxResults {get;set;}
         public Integer total {get;set;}
         public List<IssueComment> comments;
        
        public Integer getStartAt() { return startAt ; }
        public Integer getMaxResults() { return maxResults ; }
        public Integer getTotal() { return total ; }
    }

    public class IssueComment {
         public String self {get;set;}
         public String id {get;set;}
         public IssueUser author {get;set;}
         public String body {get;set;}
         public IssueUser updateAuthor {get;set;}
         public String created {get;set;}
         public String updated {get;set;}
    }
}