<?xml version="1.0" encoding="UTF-8"?>
<Workflow xmlns="http://soap.sforce.com/2006/04/metadata">
    <alerts>
        <fullName>NotifyRetailSolicitor</fullName>
        <description>Notify Retail Solicitor</description>
        <protected>false</protected>
        <recipients>
            <type>owner</type>
        </recipients>
        <senderType>DefaultWorkflowUser</senderType>
        <template>unfiled$public/NotifyRetailSolicitor</template>
    </alerts>
    <alerts>
        <fullName>Notify_RDC</fullName>
        <ccEmails>bob.aston@mailinator.com</ccEmails>
        <description>Notify RDC</description>
        <protected>false</protected>
        <recipients>
            <type>owner</type>
        </recipients>
        <senderType>DefaultWorkflowUser</senderType>
        <template>unfiled$public/AttachLeasePlan</template>
    </alerts>
    <alerts>
        <fullName>Notify_the_task</fullName>
        <description>Notify the task</description>
        <protected>false</protected>
        <recipients>
            <field>Email</field>
            <type>email</type>
        </recipients>
        <senderType>CurrentUser</senderType>
        <template>unfiled$public/AttachLeasePlan</template>
    </alerts>
    <fieldUpdates>
        <fullName>TASK_UpdateRemainderField</fullName>
        <field>IsReminderSet</field>
        <literalValue>1</literalValue>
        <name>TASK_Update Remainder Field</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>Literal</operation>
        <protected>false</protected>
    </fieldUpdates>
</Workflow>
