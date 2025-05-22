# Automated Threat Response with AWS GuardDuty, Lambda, SNS, and Terraform

This project demonstrates how to automate the detection and response of security threats in AWS using **native cloud services** and **infrastructure as code**. GuardDuty identifies threats, Lambda processes them, SNS sends real-time alerts, and DynamoDB prevents alert duplication. The entire setup is deployed via Terraform.

---

## Project Summary

> **Goal:** Detect security threats in AWS (via GuardDuty) and automatically trigger alerts while avoiding duplicates.

-  GuardDuty detects suspicious behavior (e.g., port scans, malware, IAM abuse)
-  EventBridge triggers a Lambda function
-  Lambda checks DynamoDB to **prevent alert duplication**
-  If the finding is new, Lambda sends an alert to **Amazon SNS**
-  You get a real-time email notification
-  All infrastructure is managed with **Terraform**

---

## Architecture Overview

```
┌────────────┐       ┌─────────────┐       ┌──────────────┐       ┌────────────┐
│ GuardDuty  │──────▶ EventBridge │──────▶│   Lambda      │──────▶│   SNS Topic│
└────────────┘       └─────────────┘       └──────────────┘       └────┬───────┘
                                                        │               │
                                                ┌───────▼──────┐  ┌─────▼───────┐
                                                │ DynamoDB     │  │ Email Alert │
                                                └──────────────┘  └─────────────┘
```

---

## Technologies Used

| Tool       | Purpose                             |
|------------|-------------------------------------|
| AWS GuardDuty | Detects real-time threats         |
| AWS Lambda   | Handles alerts with custom logic  |
| Amazon SNS   | Sends alert via email             |
| DynamoDB     | Stores finding IDs for deduplication |
| EventBridge  | Connects GuardDuty to Lambda      |
| Terraform    | Deploys the infrastructure        |

---


## Key Features

- **Automated Threat Detection** – based on GuardDuty findings
- **Real-Time Alerts** – sent via SNS to email
- **Deduplication** – prevents spam from repeated findings using DynamoDB
- **Event-Driven Architecture** – powered by EventBridge and Lambda
- **Infrastructure as Code** – everything deployed and versioned using Terraform

---


## Screenshots

| Screenshot              | What to Capture                         |
|-------------------------|------------------------------------------|
| SNS Topic            | Confirmed email subscription             |
| Lambda Function      | Env vars for SNS + DynamoDB              |
| CloudWatch Logs      | `Alert sent` and `Duplicate skipped`     |
| DynamoDB Table       | One or more `finding_id` entries         |
| Email Alert          | Real SNS alert content                   |
| Terraform Output     | Successful `apply` summary               |
| GitHub Repo (optional) | Project structure & file layout        |

---


## Skills Demonstrated

- Deploying and configuring AWS GuardDuty for threat detection
- Building event-driven automation using EventBridge and Lambda
- Using Amazon SNS for real-time alert delivery
- Writing and managing infrastructure using Terraform
- Testing and simulating GuardDuty findings via the AWS CLI
- Applying cloud security best practices in an automated workflow


---

