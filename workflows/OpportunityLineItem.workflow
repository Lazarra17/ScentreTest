<?xml version="1.0" encoding="UTF-8"?>
<Workflow xmlns="http://soap.sforce.com/2006/04/metadata">
    <fieldUpdates>
        <fullName>OPP_SettheAnnualMinimumRent</fullName>
        <field>AnnualMinimumRent__c</field>
        <formula>TotalPrice</formula>
        <name>OPP_SettheAnnualMinimumRent</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>Formula</operation>
        <protected>false</protected>
        <targetObject>OpportunityId</targetObject>
    </fieldUpdates>
    <fieldUpdates>
        <fullName>Setproductfamilyfromproduct</fullName>
        <description>Set the product family on opportunity line item from related product&apos;s product family</description>
        <field>ProductFamily__c</field>
        <formula>TEXT(Product2.Family)</formula>
        <name>Set product family from product</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>Formula</operation>
        <protected>false</protected>
    </fieldUpdates>
    <rules>
        <fullName>OLI - Set the Product Family</fullName>
        <actions>
            <name>Setproductfamilyfromproduct</name>
            <type>FieldUpdate</type>
        </actions>
        <active>false</active>
        <criteriaItems>
            <field>Product2.IsActive</field>
            <operation>equals</operation>
            <value>True</value>
        </criteriaItems>
        <description>Set the product family of the opportunity line item by related product&apos;s product family</description>
        <triggerType>onAllChanges</triggerType>
    </rules>
</Workflow>
