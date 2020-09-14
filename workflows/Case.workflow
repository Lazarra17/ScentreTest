<?xml version="1.0" encoding="UTF-8"?>
<Workflow xmlns="http://soap.sforce.com/2006/04/metadata">
    <alerts>
        <fullName>AlertBankGuaranteeCaseOwner</fullName>
        <description>Alert Bank Guarantee Case Owner</description>
        <protected>false</protected>
        <recipients>
            <type>owner</type>
        </recipients>
        <senderType>CurrentUser</senderType>
        <template>unfiled$public/Bank_Guarantee_Email_to_RAS</template>
    </alerts>
    <alerts>
        <fullName>AlertCaseOwner</fullName>
        <description>Alert Case Owner</description>
        <protected>false</protected>
        <recipients>
            <type>owner</type>
        </recipients>
        <senderType>CurrentUser</senderType>
        <template>unfiled$public/SUPPORTNewassignmentnotificationSAMPLE</template>
    </alerts>
    <alerts>
        <fullName>CAS_ApprovalRejectionNotification</fullName>
        <description>Case Approval Rejection Notification</description>
        <protected>false</protected>
        <recipients>
            <type>owner</type>
        </recipients>
        <senderType>CurrentUser</senderType>
        <template>unfiled$public/CaseApprovalRejected</template>
    </alerts>
    <alerts>
        <fullName>CAS_CaseApproveNotification</fullName>
        <description>Case Approve Notification</description>
        <protected>false</protected>
        <recipients>
            <type>owner</type>
        </recipients>
        <senderType>CurrentUser</senderType>
        <template>unfiled$public/CaseApproved</template>
    </alerts>
    <alerts>
        <fullName>CAS_CaseRejectionNotification</fullName>
        <description>Case Rejection Notification</description>
        <protected>false</protected>
        <recipients>
            <type>owner</type>
        </recipients>
        <senderType>CurrentUser</senderType>
        <template>unfiled$public/CaseRejected</template>
    </alerts>
    <alerts>
        <fullName>SOCStatusUpdate</fullName>
        <ccEmails>fitout@scentregroup.com</ccEmails>
        <description>SOC Status Update</description>
        <protected>false</protected>
        <recipients>
            <type>owner</type>
        </recipients>
        <recipients>
            <recipient>btouma@scentregroup.com</recipient>
            <type>user</type>
        </recipients>
        <senderType>CurrentUser</senderType>
        <template>unfiled$public/SOC_Email_Template</template>
    </alerts>
    <fieldUpdates>
        <fullName>Approval_date</fullName>
        <description>To capture the date the approval was procided</description>
        <field>Approved_Date__c</field>
        <formula>NOW()</formula>
        <name>CAS_SetApprovaldate</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>Formula</operation>
        <protected>false</protected>
    </fieldUpdates>
    <fieldUpdates>
        <fullName>CAS_SetApprovedToTrue</fullName>
        <field>Approved__c</field>
        <literalValue>1</literalValue>
        <name>CAS_SetApprovedToTrue</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>Literal</operation>
        <protected>false</protected>
        <reevaluateOnChange>true</reevaluateOnChange>
    </fieldUpdates>
    <fieldUpdates>
        <fullName>CAS_SetJDESentStatus</fullName>
        <description>Set the JDE Sent Status to &apos;Ready&apos;</description>
        <field>JDESentStatus__c</field>
        <literalValue>Ready</literalValue>
        <name>CAS_SetJDESentStatus</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>Literal</operation>
        <protected>false</protected>
    </fieldUpdates>
    <fieldUpdates>
        <fullName>CAS_SetStatusToApproved</fullName>
        <field>Status</field>
        <literalValue>Approved</literalValue>
        <name>CAS_SetStatusToApproved</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>Literal</operation>
        <protected>false</protected>
        <reevaluateOnChange>true</reevaluateOnChange>
    </fieldUpdates>
    <fieldUpdates>
        <fullName>CAS_SetStatusToClosed</fullName>
        <field>Status</field>
        <literalValue>Closed</literalValue>
        <name>CAS_SetStatusToClosed</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>Literal</operation>
        <protected>false</protected>
    </fieldUpdates>
    <fieldUpdates>
        <fullName>CAS_SetStatusToCompleted</fullName>
        <field>Status</field>
        <literalValue>Completed</literalValue>
        <name>CAS_SetStatusToCompleted</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>Literal</operation>
        <protected>false</protected>
    </fieldUpdates>
    <fieldUpdates>
        <fullName>CAS_SetStatusToNew</fullName>
        <field>Status</field>
        <literalValue>New</literalValue>
        <name>CAS_SetStatusToNew</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>Literal</operation>
        <protected>false</protected>
    </fieldUpdates>
    <fieldUpdates>
        <fullName>CAS_SetStatusToPendingApproval</fullName>
        <field>Status</field>
        <literalValue>Pending Approval</literalValue>
        <name>CAS_SetStatusToPendingApproval</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>Literal</operation>
        <protected>false</protected>
    </fieldUpdates>
    <fieldUpdates>
        <fullName>CAS_SetStatusToProcessing</fullName>
        <description>Set this lease variation to Processing for Manual update by RAS</description>
        <field>Status</field>
        <literalValue>Processing</literalValue>
        <name>CAS_SetStatusToProcessing</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>Literal</operation>
        <protected>false</protected>
        <reevaluateOnChange>true</reevaluateOnChange>
    </fieldUpdates>
    <fieldUpdates>
        <fullName>StatusPendingApproval</fullName>
        <description>Set the status to pending approval.</description>
        <field>Status</field>
        <literalValue>Pending Approval</literalValue>
        <name>Status Pending Approval</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>Literal</operation>
        <protected>false</protected>
    </fieldUpdates>
    <fieldUpdates>
        <fullName>StatusRejected</fullName>
        <description>Set the case status to rejected.</description>
        <field>Status</field>
        <literalValue>Rejected</literalValue>
        <name>Status Rejected</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>Literal</operation>
        <protected>false</protected>
    </fieldUpdates>
    <fieldUpdates>
        <fullName>Status_Pending_Approval</fullName>
        <field>Status</field>
        <literalValue>Pending Approval</literalValue>
        <name>Status Pending Approval</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>Literal</operation>
        <protected>false</protected>
    </fieldUpdates>
    <fieldUpdates>
        <fullName>Status_Rejected</fullName>
        <field>Status</field>
        <literalValue>Rejected</literalValue>
        <name>Status Rejected</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>Literal</operation>
        <protected>false</protected>
    </fieldUpdates>
    <fieldUpdates>
        <fullName>UpdateCaseOwner</fullName>
        <description>Update Case Owner to M. Khan from Revenue Assurance</description>
        <field>OwnerId</field>
        <lookupValue>mkhan@scentregroup.com</lookupValue>
        <lookupValueType>User</lookupValueType>
        <name>Update Case Owner</name>
        <notifyAssignee>true</notifyAssignee>
        <operation>LookupValue</operation>
        <protected>false</protected>
    </fieldUpdates>
    <fieldUpdates>
        <fullName>UpdateMilestoneToApproved</fullName>
        <field>Milestone__c</field>
        <literalValue>Internal Approval Granted</literalValue>
        <name>UpdateMilestoneToApproved</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>Literal</operation>
        <protected>false</protected>
        <reevaluateOnChange>true</reevaluateOnChange>
    </fieldUpdates>
    <fieldUpdates>
        <fullName>UpdateMilestoneToPendingApproval</fullName>
        <field>Milestone__c</field>
        <literalValue>Pending Internal Approval</literalValue>
        <name>UpdateMilestoneToPendingApproval</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>Literal</operation>
        <protected>false</protected>
        <reevaluateOnChange>true</reevaluateOnChange>
    </fieldUpdates>
    <fieldUpdates>
        <fullName>UpdateMilestoneToRejected</fullName>
        <field>Milestone__c</field>
        <literalValue>Internal Approval Rejected</literalValue>
        <name>UpdateMilestoneToRejected</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>Literal</operation>
        <protected>false</protected>
        <reevaluateOnChange>true</reevaluateOnChange>
    </fieldUpdates>
    <fieldUpdates>
        <fullName>Update_COVID_Record_Type</fullName>
        <field>RecordTypeId</field>
        <lookupValue>LVI_COVID19</lookupValue>
        <lookupValueType>RecordType</lookupValueType>
        <name>Update COVID Record Type</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>LookupValue</operation>
        <protected>false</protected>
    </fieldUpdates>
    <rules>
        <fullName>COVID19 Case</fullName>
        <actions>
            <name>Update_COVID_Record_Type</name>
            <type>FieldUpdate</type>
        </actions>
        <active>true</active>
        <criteriaItems>
            <field>Case.SubType__c</field>
            <operation>equals</operation>
            <value>COVID-19 Rent Request</value>
        </criteriaItems>
        <description>Updates to correct record type</description>
        <triggerType>onCreateOnly</triggerType>
    </rules>
    <rules>
        <fullName>Update Web Email</fullName>
        <active>false</active>
        <description>For COVID19 Cases</description>
        <formula>AND( ISCHANGED( ContactId ) , RecordTypeId = &quot;0122P0000004NXUQA2&quot;)</formula>
        <triggerType>onAllChanges</triggerType>
    </rules>
</Workflow>
