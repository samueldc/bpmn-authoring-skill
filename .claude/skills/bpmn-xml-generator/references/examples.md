# BPMN Examples

Four complete, valid BPMN 2.0 XML files ready to be uploaded via `POST /v1/definitions`.

---

## Example 1 — Simple Approval (userTask + exclusiveGateway)

**Use case:** A requester submits a form; a manager approves or rejects.

```xml
<?xml version="1.0" encoding="UTF-8"?>
<definitions
  xmlns="http://www.omg.org/spec/BPMN/20100524/MODEL"
  xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
  xmlns:camunda="http://camunda.org/schema/1.0/bpmn"
  xmlns:dc="http://www.omg.org/spec/DD/20100524/DC"
  xmlns:di="http://www.omg.org/spec/DD/20100524/DI"
  xmlns:bpmndi="http://www.omg.org/spec/BPMN/20100524/DI"
  xsi:schemaLocation="http://www.omg.org/spec/BPMN/20100524/MODEL
                      http://www.omg.org/spec/BPMN/2.0/20100501/BPMN20.xsd"
  id="Definitions_simple-approval"
  targetNamespace="http://bpmn.io/schema/bpmn"
  exporter="bpmn-xml-generator"
  exporterVersion="1.0">

  <process id="simple-approval" name="Simple Approval" isExecutable="true">

    <!-- ═══ START ═══ -->
    <startEvent id="start" name="Request Submitted">
      <outgoing>flow_start_to_submit</outgoing>
    </startEvent>

    <!-- ═══ ACTIVITIES ═══ -->
    <userTask id="submit_task" name="Submit Request"
              camunda:candidateGroups="requesters">
      <extensionElements>
        <camunda:formData>
          <camunda:formField id="amount"        label="Amount (USD)"  type="long"/>
          <camunda:formField id="justification" label="Justification" type="string"/>
        </camunda:formData>
      </extensionElements>
      <ioSpecification>
        <dataOutput id="out_amount"        name="amount"/>
        <dataOutput id="out_justification" name="justification"/>
      </ioSpecification>
      <incoming>flow_start_to_submit</incoming>
      <outgoing>flow_submit_to_notify</outgoing>
    </userTask>

    <intermediateThrowEvent id="notify_pending" name="Request in Review">
      <dataInputAssociation>
        <sourceRef>amount</sourceRef>
        <sourceRef>justification</sourceRef>
      </dataInputAssociation>
      <messageEventDefinition messageRef="msg_pending"/>
      <incoming>flow_submit_to_notify</incoming>
      <outgoing>flow_notify_to_review</outgoing>
    </intermediateThrowEvent>

    <userTask id="review_task" name="Review Request"
              camunda:assignee="{{variables.manager}}"
              camunda:dueDate="{{variables.reviewDueDate}}">
      <extensionElements>
        <camunda:formData>
          <camunda:formField id="approved" label="Approved?" type="boolean"/>
          <camunda:formField id="comment"  label="Comment"   type="string"/>
        </camunda:formData>
      </extensionElements>
      <ioSpecification>
        <dataInput  id="in_amount"        name="amount"/>
        <dataInput  id="in_justification" name="justification"/>
        <dataOutput id="out_approved"     name="approved"/>
        <dataOutput id="out_comment"      name="comment"/>
      </ioSpecification>
      <incoming>flow_notify_to_review</incoming>
      <outgoing>flow_review_to_gw</outgoing>
    </userTask>

    <!-- ═══ GATEWAYS ═══ -->
    <exclusiveGateway id="gw_decision" name="Decision" default="flow_rejected">
      <incoming>flow_review_to_gw</incoming>
      <outgoing>flow_approved</outgoing>
      <outgoing>flow_rejected</outgoing>
    </exclusiveGateway>

    <serviceTask id="notify_approved" name="Notify Approved">
      <incoming>flow_approved</incoming>
      <outgoing>flow_to_end_approved</outgoing>
    </serviceTask>

    <!-- ═══ END ═══ -->
    <endEvent id="end_approved" name="Approved">
      <incoming>flow_to_end_approved</incoming>
    </endEvent>

    <endEvent id="end_rejected" name="Rejected">
      <incoming>flow_rejected</incoming>
    </endEvent>

    <!-- ═══ FLOWS ═══ -->
    <sequenceFlow id="flow_start_to_submit"  sourceRef="start"          targetRef="submit_task"/>
    <sequenceFlow id="flow_submit_to_notify" sourceRef="submit_task"     targetRef="notify_pending"/>
    <sequenceFlow id="flow_notify_to_review" sourceRef="notify_pending"  targetRef="review_task"/>
    <sequenceFlow id="flow_review_to_gw"     sourceRef="review_task"     targetRef="gw_decision"/>
    <sequenceFlow id="flow_approved"         sourceRef="gw_decision"     targetRef="notify_approved">
      <conditionExpression xsi:type="tFormalExpression">{{variables.approved == true}}</conditionExpression>
    </sequenceFlow>
    <sequenceFlow id="flow_rejected"         sourceRef="gw_decision"     targetRef="end_rejected"/>
    <sequenceFlow id="flow_to_end_approved"  sourceRef="notify_approved" targetRef="end_approved"/>

  </process>

  <message id="msg_pending" name="request_pending"/>

</definitions>
```

---

## Example 2 — Customer Onboarding (parallelGateway + timer escalation)

**Use case:** Welcome email and KYC check run in parallel. KYC has a 48h deadline.

```xml
<?xml version="1.0" encoding="UTF-8"?>
<definitions
  xmlns="http://www.omg.org/spec/BPMN/20100524/MODEL"
  xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
  xmlns:camunda="http://camunda.org/schema/1.0/bpmn"
  xmlns:dc="http://www.omg.org/spec/DD/20100524/DC"
  xmlns:di="http://www.omg.org/spec/DD/20100524/DI"
  xmlns:bpmndi="http://www.omg.org/spec/BPMN/20100524/DI"
  xsi:schemaLocation="http://www.omg.org/spec/BPMN/20100524/MODEL
                      http://www.omg.org/spec/BPMN/2.0/20100501/BPMN20.xsd"
  id="Definitions_customer-onboarding"
  targetNamespace="http://bpmn.io/schema/bpmn"
  exporter="bpmn-xml-generator"
  exporterVersion="1.0">

  <process id="customer-onboarding" name="Customer Onboarding" isExecutable="true">

    <!-- ═══ START ═══ -->
    <startEvent id="start" name="Account Created">
      <outgoing>flow_start_to_split</outgoing>
    </startEvent>

    <!-- ═══ PARALLEL SPLIT ═══ -->
    <parallelGateway id="gw_split" name="Parallel Start">
      <incoming>flow_start_to_split</incoming>
      <outgoing>flow_to_welcome</outgoing>
      <outgoing>flow_to_kyc</outgoing>
    </parallelGateway>

    <!-- ═══ BRANCH A: Welcome email ═══ -->
    <serviceTask id="send_welcome" name="Send Welcome Email">
      <incoming>flow_to_welcome</incoming>
      <outgoing>flow_welcome_done</outgoing>
    </serviceTask>

    <!-- ═══ BRANCH B: KYC with timeout boundary ═══ -->
    <userTask id="kyc_task" name="Complete KYC"
              camunda:candidateGroups="compliance">
      <extensionElements>
        <camunda:formData>
          <camunda:formField id="id_verified"  label="ID Verified?"   type="boolean"/>
          <camunda:formField id="risk_level"   label="Risk Level"     type="string"/>
        </camunda:formData>
      </extensionElements>
      <ioSpecification>
        <dataInput  id="in_customer_id"  name="customerId"/>
        <dataOutput id="out_id_verified" name="idVerified"/>
        <dataOutput id="out_risk_level"  name="riskLevel"/>
      </ioSpecification>
      <incoming>flow_to_kyc</incoming>
      <outgoing>flow_kyc_done</outgoing>
    </userTask>

    <!-- Timer boundary — escalate if KYC not done in 48h -->
    <boundaryEvent id="kyc_timeout" name="KYC Timeout (48h)"
                   attachedToRef="kyc_task"
                   cancelActivity="true">
      <outgoing>flow_kyc_escalate</outgoing>
      <timerEventDefinition>
        <timeDuration xsi:type="tFormalExpression">PT48H</timeDuration>
      </timerEventDefinition>
    </boundaryEvent>

    <serviceTask id="escalate_kyc" name="Escalate KYC">
      <incoming>flow_kyc_escalate</incoming>
      <outgoing>flow_escalate_to_end</outgoing>
    </serviceTask>

    <!-- ═══ PARALLEL JOIN ═══ -->
    <parallelGateway id="gw_join" name="Parallel Join">
      <incoming>flow_welcome_done</incoming>
      <incoming>flow_kyc_done</incoming>
      <outgoing>flow_join_to_activate</outgoing>
    </parallelGateway>

    <serviceTask id="activate_account" name="Activate Account">
      <incoming>flow_join_to_activate</incoming>
      <outgoing>flow_activate_to_end</outgoing>
    </serviceTask>

    <!-- ═══ END ═══ -->
    <endEvent id="end_active" name="Account Active">
      <incoming>flow_activate_to_end</incoming>
    </endEvent>

    <endEvent id="end_escalated" name="KYC Escalated">
      <incoming>flow_escalate_to_end</incoming>
    </endEvent>

    <!-- ═══ FLOWS ═══ -->
    <sequenceFlow id="flow_start_to_split"    sourceRef="start"            targetRef="gw_split"/>
    <sequenceFlow id="flow_to_welcome"        sourceRef="gw_split"         targetRef="send_welcome"/>
    <sequenceFlow id="flow_to_kyc"            sourceRef="gw_split"         targetRef="kyc_task"/>
    <sequenceFlow id="flow_welcome_done"      sourceRef="send_welcome"     targetRef="gw_join"/>
    <sequenceFlow id="flow_kyc_done"          sourceRef="kyc_task"         targetRef="gw_join"/>
    <sequenceFlow id="flow_kyc_escalate"      sourceRef="kyc_timeout"      targetRef="escalate_kyc"/>
    <sequenceFlow id="flow_escalate_to_end"   sourceRef="escalate_kyc"     targetRef="end_escalated"/>
    <sequenceFlow id="flow_join_to_activate"  sourceRef="gw_join"          targetRef="activate_account"/>
    <sequenceFlow id="flow_activate_to_end"   sourceRef="activate_account" targetRef="end_active"/>

  </process>

</definitions>
```

---

## Example 3 — Message Correlation (payment confirmation)

**Use case:** Order placed → waits for payment message → ships → done.

```xml
<?xml version="1.0" encoding="UTF-8"?>
<definitions
  xmlns="http://www.omg.org/spec/BPMN/20100524/MODEL"
  xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
  xmlns:camunda="http://camunda.org/schema/1.0/bpmn"
  xmlns:dc="http://www.omg.org/spec/DD/20100524/DC"
  xmlns:di="http://www.omg.org/spec/DD/20100524/DI"
  xmlns:bpmndi="http://www.omg.org/spec/BPMN/20100524/DI"
  xsi:schemaLocation="http://www.omg.org/spec/BPMN/20100524/MODEL
                      http://www.omg.org/spec/BPMN/2.0/20100501/BPMN20.xsd"
  id="Definitions_order-fulfillment"
  targetNamespace="http://bpmn.io/schema/bpmn"
  exporter="bpmn-xml-generator"
  exporterVersion="1.0">

  <message id="msg_payment_confirmed" name="payment_confirmed"/>

  <process id="order-fulfillment" name="Order Fulfillment" isExecutable="true">

    <!-- ═══ START ═══ -->
    <startEvent id="start" name="Order Placed">
      <outgoing>flow_start_to_reserve</outgoing>
    </startEvent>

    <!-- ═══ ACTIVITIES ═══ -->
    <serviceTask id="reserve_stock" name="Reserve Stock">
      <incoming>flow_start_to_reserve</incoming>
      <outgoing>flow_reserve_to_wait</outgoing>
    </serviceTask>

    <!-- eventBasedGateway: race between payment and timeout -->
    <eventBasedGateway id="gw_race" name="Wait for payment or timeout">
      <incoming>flow_reserve_to_wait</incoming>
      <outgoing>flow_to_payment_catch</outgoing>
      <outgoing>flow_to_timeout_catch</outgoing>
    </eventBasedGateway>

    <intermediateCatchEvent id="catch_payment" name="Payment Confirmed">
      <incoming>flow_to_payment_catch</incoming>
      <outgoing>flow_payment_to_ship</outgoing>
      <messageEventDefinition messageRef="msg_payment_confirmed"/>
    </intermediateCatchEvent>

    <intermediateCatchEvent id="catch_timeout" name="Payment Timeout">
      <incoming>flow_to_timeout_catch</incoming>
      <outgoing>flow_timeout_to_cancel</outgoing>
      <timerEventDefinition>
        <timeDuration xsi:type="tFormalExpression">PT24H</timeDuration>
      </timerEventDefinition>
    </intermediateCatchEvent>

    <serviceTask id="ship_order" name="Ship Order">
      <incoming>flow_payment_to_ship</incoming>
      <outgoing>flow_ship_to_end</outgoing>
    </serviceTask>

    <serviceTask id="cancel_order" name="Cancel Order">
      <incoming>flow_timeout_to_cancel</incoming>
      <outgoing>flow_cancel_to_end</outgoing>
    </serviceTask>

    <!-- ═══ END ═══ -->
    <endEvent id="end_shipped" name="Order Shipped">
      <incoming>flow_ship_to_end</incoming>
    </endEvent>

    <endEvent id="end_cancelled" name="Order Cancelled">
      <incoming>flow_cancel_to_end</incoming>
    </endEvent>

    <!-- ═══ FLOWS ═══ -->
    <sequenceFlow id="flow_start_to_reserve"   sourceRef="start"           targetRef="reserve_stock"/>
    <sequenceFlow id="flow_reserve_to_wait"    sourceRef="reserve_stock"   targetRef="gw_race"/>
    <sequenceFlow id="flow_to_payment_catch"   sourceRef="gw_race"         targetRef="catch_payment"/>
    <sequenceFlow id="flow_to_timeout_catch"   sourceRef="gw_race"         targetRef="catch_timeout"/>
    <sequenceFlow id="flow_payment_to_ship"    sourceRef="catch_payment"   targetRef="ship_order"/>
    <sequenceFlow id="flow_timeout_to_cancel"  sourceRef="catch_timeout"   targetRef="cancel_order"/>
    <sequenceFlow id="flow_ship_to_end"        sourceRef="ship_order"      targetRef="end_shipped"/>
    <sequenceFlow id="flow_cancel_to_end"      sourceRef="cancel_order"    targetRef="end_cancelled"/>

  </process>

</definitions>
```

---

## Example 4 — Credit Analysis with DMN (businessRuleTask + sub-process)

**Use case:** Loan application → credit DMN check → approval or manual review sub-process.

```xml
<?xml version="1.0" encoding="UTF-8"?>
<definitions
  xmlns="http://www.omg.org/spec/BPMN/20100524/MODEL"
  xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
  xmlns:camunda="http://camunda.org/schema/1.0/bpmn"
  xmlns:dc="http://www.omg.org/spec/DD/20100524/DC"
  xmlns:di="http://www.omg.org/spec/DD/20100524/DI"
  xmlns:bpmndi="http://www.omg.org/spec/BPMN/20100524/DI"
  xsi:schemaLocation="http://www.omg.org/spec/BPMN/20100524/MODEL
                      http://www.omg.org/spec/BPMN/2.0/20100501/BPMN20.xsd"
  id="Definitions_loan-application"
  targetNamespace="http://bpmn.io/schema/bpmn"
  exporter="bpmn-xml-generator"
  exporterVersion="1.0">

  <process id="loan-application" name="Loan Application" isExecutable="true">

    <!-- ═══ START ═══ -->
    <startEvent id="start" name="Application Received">
      <outgoing>flow_start_to_validate</outgoing>
    </startEvent>

    <!-- ═══ ACTIVITIES ═══ -->
    <userTask id="validate_docs" name="Validate Documents"
              camunda:candidateGroups="operations">
      <ioSpecification>
        <dataInput  id="in_applicant"  name="applicantName"/>
        <dataInput  id="in_amount_req" name="requestedAmount"/>
        <dataOutput id="out_docs_ok"   name="documentsValid"/>
      </ioSpecification>
      <incoming>flow_start_to_validate</incoming>
      <outgoing>flow_validate_to_gw_docs</outgoing>
    </userTask>

    <exclusiveGateway id="gw_docs" name="Docs Valid?" default="flow_docs_invalid">
      <incoming>flow_validate_to_gw_docs</incoming>
      <outgoing>flow_docs_valid</outgoing>
      <outgoing>flow_docs_invalid</outgoing>
    </exclusiveGateway>

    <!-- 'credit-score-decision' must be the id of a DMN definition already registered in the engine -->
    <businessRuleTask id="credit_rule" name="Evaluate Credit Score"
                      camunda:decisionRef="credit-score-decision">
      <extensionElements>
        <camunda:in  variables="all"/>
        <camunda:out variables="all"/>
      </extensionElements>
      <incoming>flow_docs_valid</incoming>
      <outgoing>flow_credit_to_gw_score</outgoing>
    </businessRuleTask>

    <exclusiveGateway id="gw_score" name="Auto-Approve?" default="flow_manual">
      <incoming>flow_credit_to_gw_score</incoming>
      <outgoing>flow_auto_approve</outgoing>
      <outgoing>flow_manual</outgoing>
    </exclusiveGateway>

    <serviceTask id="auto_approve" name="Auto-Approve Loan">
      <incoming>flow_auto_approve</incoming>
      <outgoing>flow_auto_to_end</outgoing>
    </serviceTask>

    <!-- Sub-process for manual review -->
    <subProcess id="sub_manual_review" name="Manual Review">
      <incoming>flow_manual</incoming>
      <outgoing>flow_sub_to_end</outgoing>

      <startEvent id="sub_start">
        <outgoing>sub_flow_1</outgoing>
      </startEvent>

      <userTask id="senior_review" name="Senior Analyst Review"
                camunda:candidateGroups="senior-analysts">
        <ioSpecification>
          <dataInput  id="sub_in_score"   name="creditScore"/>
          <dataInput  id="sub_in_amount"  name="requestedAmount"/>
          <dataOutput id="sub_out_dec"    name="seniorDecision"/>
          <dataOutput id="sub_out_note"   name="seniorNote"/>
        </ioSpecification>
        <incoming>sub_flow_1</incoming>
        <outgoing>sub_flow_2</outgoing>
      </userTask>

      <endEvent id="sub_end">
        <incoming>sub_flow_2</incoming>
      </endEvent>

      <sequenceFlow id="sub_flow_1" sourceRef="sub_start"     targetRef="senior_review"/>
      <sequenceFlow id="sub_flow_2" sourceRef="senior_review" targetRef="sub_end"/>
    </subProcess>

    <!-- ═══ END ═══ -->
    <endEvent id="end_approved" name="Loan Approved">
      <incoming>flow_auto_to_end</incoming>
      <incoming>flow_sub_to_end</incoming>
    </endEvent>

    <endEvent id="end_rejected" name="Application Rejected">
      <incoming>flow_docs_invalid</incoming>
    </endEvent>

    <!-- ═══ FLOWS ═══ -->
    <sequenceFlow id="flow_start_to_validate"  sourceRef="start"          targetRef="validate_docs"/>
    <sequenceFlow id="flow_validate_to_gw_docs" sourceRef="validate_docs" targetRef="gw_docs"/>
    <sequenceFlow id="flow_docs_valid"          sourceRef="gw_docs"       targetRef="credit_rule">
      <conditionExpression xsi:type="tFormalExpression">{{variables.documentsValid == true}}</conditionExpression>
    </sequenceFlow>
    <sequenceFlow id="flow_docs_invalid"        sourceRef="gw_docs"       targetRef="end_rejected"/>
    <sequenceFlow id="flow_credit_to_gw_score"  sourceRef="credit_rule"   targetRef="gw_score"/>
    <sequenceFlow id="flow_auto_approve"        sourceRef="gw_score"      targetRef="auto_approve">
      <conditionExpression xsi:type="tFormalExpression">{{variables.creditScore >= 700 &amp;&amp; variables.requestedAmount &lt;= 50000}}</conditionExpression>
    </sequenceFlow>
    <sequenceFlow id="flow_manual"              sourceRef="gw_score"      targetRef="sub_manual_review"/>
    <sequenceFlow id="flow_auto_to_end"         sourceRef="auto_approve"  targetRef="end_approved"/>
    <sequenceFlow id="flow_sub_to_end"          sourceRef="sub_manual_review" targetRef="end_approved"/>

  </process>

</definitions>
```

> **Note on XML escaping in expressions**: Use `&amp;&amp;` for `&&` and `&lt;` for `<` inside XML attribute values and element content.
