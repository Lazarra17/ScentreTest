<?xml version="1.0" encoding="UTF-8"?>
<Workflow xmlns="http://soap.sforce.com/2006/04/metadata">
    <alerts>
        <fullName>ApprovalRejectedEmailAlert</fullName>
        <description>Risk Approval Rejected Email Alert</description>
        <protected>false</protected>
        <recipients>
            <type>owner</type>
        </recipients>
        <senderType>CurrentUser</senderType>
        <template>unfiled$public/ApprovalRejected</template>
    </alerts>
    <alerts>
        <fullName>FinalApprovalRejectedEmailAlert</fullName>
        <description>Final Approval Rejected Email Alert</description>
        <protected>false</protected>
        <recipients>
            <type>owner</type>
        </recipients>
        <senderType>CurrentUser</senderType>
        <template>unfiled$public/ApprovalRejected</template>
    </alerts>
    <alerts>
        <fullName>NotifyRM</fullName>
        <description>Notify RM</description>
        <protected>false</protected>
        <recipients>
            <field>RMLARS__c</field>
            <type>userLookup</type>
        </recipients>
        <senderType>CurrentUser</senderType>
        <template>unfiled$public/OldApprovalRequest</template>
    </alerts>
    <alerts>
        <fullName>OPP_ApprovalApprovedEmailAlert</fullName>
        <description>OPP_ApprovalApprovedEmailAlert</description>
        <protected>false</protected>
        <recipients>
            <type>owner</type>
        </recipients>
        <senderType>CurrentUser</senderType>
        <template>unfiled$public/OPP_ApprovalApproved</template>
    </alerts>
    <alerts>
        <fullName>OPP_ApprovalRejectedEmailAlert</fullName>
        <description>OPP_ApprovalRejectedEmailAlert</description>
        <protected>false</protected>
        <recipients>
            <type>owner</type>
        </recipients>
        <senderType>CurrentUser</senderType>
        <template>unfiled$public/OPP_ApprovalRejected</template>
    </alerts>
    <alerts>
        <fullName>OPP_RejectionEmailAlert</fullName>
        <description>OPP_Rejection Email Alert</description>
        <protected>false</protected>
        <recipients>
            <type>owner</type>
        </recipients>
        <senderType>CurrentUser</senderType>
        <template>unfiled$public/OldApprovalRejected</template>
    </alerts>
    <fieldUpdates>
        <fullName>OPPUpdateLatestApprovedCapital</fullName>
        <description>Update the field Latest Approved Capital with Total Capital</description>
        <field>LatestApprovedCapital__c</field>
        <formula>TotalForecastCapital__c</formula>
        <name>OPP_UpdateLatestApprovedCapital</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>Formula</operation>
        <protected>false</protected>
    </fieldUpdates>
    <fieldUpdates>
        <fullName>OPPUpdateLatestApprovedRent</fullName>
        <description>Update the field Latest Approved Rent with Proposed Minimum Rent</description>
        <field>LatestApprovedRent__c</field>
        <formula>AnnualMinimumRent__c</formula>
        <name>OPP_UpdateLatestApprovedRent</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>Formula</operation>
        <protected>false</protected>
    </fieldUpdates>
    <fieldUpdates>
        <fullName>OPP_DealAchievedDate</fullName>
        <description>Opportunity field update on &quot;Deal Achieved Date&quot;</description>
        <field>DealAchievedDate__c</field>
        <formula>TODAY()</formula>
        <name>OPP_DealAchievedDate</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>Formula</operation>
        <protected>false</protected>
    </fieldUpdates>
    <fieldUpdates>
        <fullName>OPP_FinalApprovalReject</fullName>
        <field>ApprovalStatus__c</field>
        <literalValue>Final Approval Rejected</literalValue>
        <name>OPP_FinalApprovalReject</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>Literal</operation>
        <protected>false</protected>
    </fieldUpdates>
    <fieldUpdates>
        <fullName>OPP_InitialApprovalGranted</fullName>
        <field>ApprovalStatus__c</field>
        <literalValue>Initial Approval Granted</literalValue>
        <name>OPP_InitialApprovalGranted</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>Literal</operation>
        <protected>false</protected>
        <reevaluateOnChange>true</reevaluateOnChange>
    </fieldUpdates>
    <fieldUpdates>
        <fullName>OPP_InitialApprovalRejected</fullName>
        <field>ApprovalStatus__c</field>
        <literalValue>Initial Approval Rejected</literalValue>
        <name>OPP_InitialApprovalRejected</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>Literal</operation>
        <protected>false</protected>
        <reevaluateOnChange>true</reevaluateOnChange>
    </fieldUpdates>
    <fieldUpdates>
        <fullName>OPP_PendingApproverBlank</fullName>
        <description>Field update to make the pending approver blank once the approval process is complete</description>
        <field>Pending_Approver__c</field>
        <name>OPP_PendingApproverBlank</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>LookupValue</operation>
        <protected>false</protected>
        <reevaluateOnChange>true</reevaluateOnChange>
    </fieldUpdates>
    <fieldUpdates>
        <fullName>OPP_PendingInitialApproval</fullName>
        <field>ApprovalStatus__c</field>
        <literalValue>Pending Initial Approval</literalValue>
        <name>OPP_PendingInitialApproval</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>Literal</operation>
        <protected>false</protected>
        <reevaluateOnChange>true</reevaluateOnChange>
    </fieldUpdates>
    <fieldUpdates>
        <fullName>OPP_PendingRiskApproval</fullName>
        <field>ApprovalStatus__c</field>
        <literalValue>Pending Risk Approval</literalValue>
        <name>OPP_PendingRiskApproval</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>Literal</operation>
        <protected>false</protected>
        <reevaluateOnChange>true</reevaluateOnChange>
    </fieldUpdates>
    <fieldUpdates>
        <fullName>OPP_RiskApprovalGranted</fullName>
        <field>ApprovalStatus__c</field>
        <literalValue>Risk Approval Granted</literalValue>
        <name>OPP_RiskApprovalGranted</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>Literal</operation>
        <protected>false</protected>
        <reevaluateOnChange>true</reevaluateOnChange>
    </fieldUpdates>
    <fieldUpdates>
        <fullName>OPP_RiskApprovalRejected</fullName>
        <description>Update Approval Status field whenever risk approval is rejected.</description>
        <field>ApprovalStatus__c</field>
        <literalValue>Risk Approval Rejected</literalValue>
        <name>OPP_RiskApprovalRejected</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>Literal</operation>
        <protected>false</protected>
        <reevaluateOnChange>true</reevaluateOnChange>
    </fieldUpdates>
    <fieldUpdates>
        <fullName>OPP_SetApprStatusToFinalApproved</fullName>
        <field>ApprovalStatus__c</field>
        <literalValue>Final Approval Granted</literalValue>
        <name>OPP_SetApprStatusToFinalApproved</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>Literal</operation>
        <protected>false</protected>
        <reevaluateOnChange>true</reevaluateOnChange>
    </fieldUpdates>
    <fieldUpdates>
        <fullName>OPP_SetApprStatusToLicenseRejected</fullName>
        <field>ApprovalStatus__c</field>
        <literalValue>Licence Approval Rejected</literalValue>
        <name>Licence Approval Rejected</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>Literal</operation>
        <protected>false</protected>
        <reevaluateOnChange>true</reevaluateOnChange>
    </fieldUpdates>
    <fieldUpdates>
        <fullName>OPP_SetApprovalStatusToLicenseGranted</fullName>
        <field>ApprovalStatus__c</field>
        <literalValue>Licence Approval Granted</literalValue>
        <name>Licence Approval Granted</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>Literal</operation>
        <protected>false</protected>
        <reevaluateOnChange>true</reevaluateOnChange>
    </fieldUpdates>
    <fieldUpdates>
        <fullName>OPP_SetApprovalStatusToPendingFinal</fullName>
        <field>ApprovalStatus__c</field>
        <literalValue>Pending Final Approval</literalValue>
        <name>OPP_SetApprovalStatusToPendingFinal</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>Literal</operation>
        <protected>false</protected>
        <reevaluateOnChange>true</reevaluateOnChange>
    </fieldUpdates>
    <fieldUpdates>
        <fullName>OPP_SetApprovalStatusToPendingLicense</fullName>
        <field>ApprovalStatus__c</field>
        <literalValue>Pending Licence Approval</literalValue>
        <name>Pending Licence Approval</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>Literal</operation>
        <protected>false</protected>
        <reevaluateOnChange>true</reevaluateOnChange>
    </fieldUpdates>
    <fieldUpdates>
        <fullName>OPP_SetApprovalStatusToPendingRCA</fullName>
        <field>ApprovalStatus__c</field>
        <literalValue>Pending RCA Approval</literalValue>
        <name>OPP_SetApprovalStatusToPendingRCA</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>Literal</operation>
        <protected>false</protected>
    </fieldUpdates>
    <fieldUpdates>
        <fullName>OPP_SetApprovalStatusToPendingRisk</fullName>
        <field>ApprovalStatus__c</field>
        <literalValue>Pending Risk Approval</literalValue>
        <name>OPP_SetApprovalStatusToPendingRisk</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>Literal</operation>
        <protected>false</protected>
        <reevaluateOnChange>true</reevaluateOnChange>
    </fieldUpdates>
    <fieldUpdates>
        <fullName>OPP_SetApprovalStatusToRMGranted</fullName>
        <description>Update the Approval Status field value to &quot;RM Approval Granted&quot;.</description>
        <field>ApprovalStatus__c</field>
        <literalValue>RM Approval Granted</literalValue>
        <name>RM Approval Status Granted</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>Literal</operation>
        <protected>false</protected>
        <reevaluateOnChange>true</reevaluateOnChange>
    </fieldUpdates>
    <fieldUpdates>
        <fullName>OPP_SetApprovalStatusToRMRejected</fullName>
        <description>Update Opportunity Approval Status to &quot;RM Approval Rejected&quot;</description>
        <field>ApprovalStatus__c</field>
        <literalValue>RM Approval Rejected</literalValue>
        <name>RM Approval Status Rejected</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>Literal</operation>
        <protected>false</protected>
        <reevaluateOnChange>true</reevaluateOnChange>
    </fieldUpdates>
    <fieldUpdates>
        <fullName>OPP_UpdApprovalToPendingRM</fullName>
        <field>ApprovalStatus__c</field>
        <literalValue>Pending RM Approval</literalValue>
        <name>Pending RM Approval Status</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>Literal</operation>
        <protected>false</protected>
    </fieldUpdates>
    <fieldUpdates>
        <fullName>OPP_UpdateDealAchieved</fullName>
        <description>Opportunity field update on &quot;Deal Achieved&quot;</description>
        <field>DealAchieved__c</field>
        <literalValue>1</literalValue>
        <name>OPP_UpdateDealAchieved</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>Literal</operation>
        <protected>false</protected>
    </fieldUpdates>
    <fieldUpdates>
        <fullName>OPP_UpdateStageToProposeAccept</fullName>
        <field>StageName</field>
        <literalValue>Propose &amp; Accept</literalValue>
        <name>OPP_UpdateStageToProposeAccept</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>Literal</operation>
        <protected>false</protected>
    </fieldUpdates>
    <fieldUpdates>
        <fullName>OPP_Update_security_deposit_with_rent</fullName>
        <description>Update the security deposit amount with 2 months gross rent</description>
        <field>SecurityDeposit__c</field>
        <formula>((AnnualMinimumRent__c+TotalOutgoings__c+TotalPromotionLevy__c)/12)*2</formula>
        <name>OPP - Update security deposit with rent</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>Formula</operation>
        <protected>false</protected>
    </fieldUpdates>
    <fieldUpdates>
        <fullName>OPP_Update_the_Opportunity_Name</fullName>
        <field>Name</field>
        <formula>Property__r.Name + &quot; - &quot; + Space__r.Name + &quot; - &quot; + Account.Name + &quot; - &quot; + TEXT(Type)</formula>
        <name>OPP - Update the Opportunity Name</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>Formula</operation>
        <protected>false</protected>
    </fieldUpdates>
    <fieldUpdates>
        <fullName>Opp_StageUpdate</fullName>
        <description>TO DO delete this field update</description>
        <field>StageName</field>
        <literalValue>Propose &amp; Accept</literalValue>
        <name>Opp_StageUpdate</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>Literal</operation>
        <protected>false</protected>
    </fieldUpdates>
    <fieldUpdates>
        <fullName>Opp_StageUpdateProposeAccept</fullName>
        <field>StageName</field>
        <literalValue>Propose &amp; Accept</literalValue>
        <name>Opp_StageUpdateProposeAccept</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>Literal</operation>
        <protected>false</protected>
        <reevaluateOnChange>true</reevaluateOnChange>
    </fieldUpdates>
    <fieldUpdates>
        <fullName>PendingStoreRoomApproval</fullName>
        <field>ApprovalStatus__c</field>
        <literalValue>Pending Store Room Approval</literalValue>
        <name>Pending Store Room Approval</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>Literal</operation>
        <protected>false</protected>
    </fieldUpdates>
    <fieldUpdates>
        <fullName>RCAApprovalGranted</fullName>
        <field>ApprovalStatus__c</field>
        <literalValue>RCA Approval Granted</literalValue>
        <name>RCA Approval Granted</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>Literal</operation>
        <protected>false</protected>
    </fieldUpdates>
    <fieldUpdates>
        <fullName>RCAApprovalRejected</fullName>
        <description>Update Approval Status field whenever RCA approval is rejected.</description>
        <field>ApprovalStatus__c</field>
        <literalValue>RCA Approval Rejected</literalValue>
        <name>RCA Approval Rejected</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>Literal</operation>
        <protected>false</protected>
    </fieldUpdates>
    <fieldUpdates>
        <fullName>RMRiskApprovalGranted</fullName>
        <field>ApprovalStatus__c</field>
        <literalValue>RM &amp; Risk Approval Granted</literalValue>
        <name>RM and Risk Approval Granted</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>Literal</operation>
        <protected>false</protected>
        <reevaluateOnChange>true</reevaluateOnChange>
    </fieldUpdates>
    <fieldUpdates>
        <fullName>RiskApprovalRejected</fullName>
        <description>Update Approval Status field whenever risk approval is rejected.</description>
        <field>ApprovalStatus__c</field>
        <literalValue>Risk Approval Rejected</literalValue>
        <name>Risk Approval Rejected</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>Literal</operation>
        <protected>false</protected>
    </fieldUpdates>
    <fieldUpdates>
        <fullName>StoreRoomApprovalGranted</fullName>
        <description>Update the Approval Status field value to &quot;RM Approval Granted&quot;.</description>
        <field>ApprovalStatus__c</field>
        <literalValue>Store Room Approval Granted</literalValue>
        <name>Store Room Approval Granted</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>Literal</operation>
        <protected>false</protected>
        <reevaluateOnChange>true</reevaluateOnChange>
    </fieldUpdates>
    <fieldUpdates>
        <fullName>StoreRoomRejected</fullName>
        <description>Update Opportunity Approval Status to &quot;RM Approval Rejected&quot;</description>
        <field>ApprovalStatus__c</field>
        <literalValue>Store Room Rejected</literalValue>
        <name>Store Room Rejected</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>Literal</operation>
        <protected>false</protected>
    </fieldUpdates>
    <tasks>
        <fullName>DisclosureStatementRequired</fullName>
        <assignedTo>Retail Admin</assignedTo>
        <assignedToType>opportunityTeam</assignedToType>
        <description>Hi Anita,

This Opportunity has been approved and the Disclosure Statement can now be prepared. 
Please review the Opportunity details and clauses and generate the DS for the Leasing Executive&apos;s review.</description>
        <dueDateOffset>1</dueDateOffset>
        <notifyAssignee>false</notifyAssignee>
        <priority>High</priority>
        <protected>false</protected>
        <status>Open</status>
        <subject>Disclosure Statement Required</subject>
    </tasks>
    <tasks>
        <fullName>OPP_RejectionTask</fullName>
        <assignedToType>owner</assignedToType>
        <dueDateOffset>1</dueDateOffset>
        <notifyAssignee>false</notifyAssignee>
        <priority>Normal</priority>
        <protected>false</protected>
        <status>Open</status>
        <subject>Update the Opportunity and Resubmit for Approval</subject>
    </tasks>
    <tasks>
        <fullName>SeekJVApproval</fullName>
        <assignedTo>useradmin@scentregroup.com</assignedTo>
        <assignedToType>user</assignedToType>
        <description>Hi Christopher, 

Prepare seek JV approval</description>
        <dueDateOffset>7</dueDateOffset>
        <notifyAssignee>false</notifyAssignee>
        <priority>High</priority>
        <protected>false</protected>
        <status>Open</status>
        <subject>Seek JV Approval</subject>
    </tasks>
</Workflow>
