# Requirements Document for Real Estate Portfolio Management

## Problem Statement

Real estate investors are unable to get a consolidated view of their portfolio. This is due to the fact that investors manage their properties :

1. By employing different property managers in different markets and each property would typically use a different software.
2. By themselves.
3. A combination of using property managers and a self managed approach.

This means that investors need to log into multi websites and their own excel sheets to get a full picture of their portfolio.

## Objective

The objective of this project is to build a web based application that can help investors aggregate information from different property management softwares,  documents, and spreadsheets to build a consolidated view of an investor's real estate portfolio.



# Real Estate Portfolio Aggregation Platform – Requirements

## 1. Product Overview

### Goal

Build a web-based application that aggregates, normalizes, and visualizes real estate portfolio data across:

* Property management systems (PMS)
* Self-managed spreadsheets
* Documents (leases, compliance, insurance, etc.)

### Core Value Proposition

* Single source of truth for portfolio performance
* Automated monitoring of risks and required actions
* Reduction of manual tracking (Excel, logins, emails)

---

## 2. User Personas

### Primary Users

* Individual real estate investors (small to mid-size portfolios)
* Semi-professional investors (multi-market, mixed management)

### Secondary Users

* Asset managers
* Property managers (limited access)
* Accountants / analysts

---

## 3. Core Functional Requirements

## 3.1 Portfolio Aggregation

### Data Sources

The system must support ingestion from:

#### A. Property Management Software (PMS)

* API integrations (preferred)
* CSV exports (fallback)
* Email ingestion (statements, reports)

#### B. Spreadsheets

* Excel / Google Sheets upload
* Scheduled sync (Google Sheets API)
* Template-based parsing + flexible mapping

#### C. Documents

* PDF, DOCX uploads
* Email attachments ingestion
* OCR + document classification

---

## 3.2 Data Normalization Layer

### Key Requirement

Standardize inconsistent data across sources into a unified schema.

### Core Entities

* Property
* Unit (for multi-family)
* Tenant
* Lease
* Payment / Rent
* Expense
* Document
* Alert / Issue

### Examples of Normalization

* “Unit #2A” vs “Apt 2A” → standardized Unit ID
* Rent frequency (weekly/monthly) normalized to monthly equivalent
* Different lease formats mapped into structured lease fields

---

## 3.3 Portfolio Dashboard

### Overview Metrics

* Total portfolio value (manual + API-fed)
* Monthly rental income (actual vs expected)
* Occupancy rate
* Delinquency rate
* NOI (if expenses available)

### Drill-Down Views

* By property
* By market
* By property manager
* By unit

---

## 3.4 Property & Unit-Level Views

### Property Summary

* Address, type, acquisition date
* Property manager (if applicable)
* Ownership structure

### Unit-Level Data (if multi-family)

* Unit number
* Tenant name
* Lease start/end
* Current rent
* Payment status

---

## 3.5 Rent & Payment Tracking

### Features

* Expected vs received rent
* Late payments tracking
* Partial payments
* Historical payment trends

### Alerts

* Rent overdue (configurable thresholds)
* Chronic late payer flag
* Missing payment data from PMS

---

## 3.6 Lease Management

### Lease Data Extraction

* Lease start/end dates
* Rent amount
* Security deposit
* Renewal terms

### Features

* Lease expiration alerts
* Renewal tracking
* Rent escalation tracking

---

## 3.7 Tenant Management

### Tenant Profiles

* Name, contact info
* Lease association
* Payment history
* Communication log (optional future feature)

---

## 3.8 Document Management System

### Supported Documents

* Leases
* Inspection certificates
* Permits
* Insurance certificates
* HOA documents
* Tax documents

### Features

* Tagging (property, unit, tenant, type)
* OCR + metadata extraction
* Expiry tracking

### Alerts

* Expiring insurance
* Missing compliance documents
* Upcoming inspections

---

## 3.9 Alerts & Monitoring System

### Central “Needs Attention” Feed

Examples:

* Rent overdue
* Lease expiring in X days
* Insurance expiring
* Missing document
* Vacancy > threshold
* Data sync failure

### Alert Features

* Severity levels (info, warning, critical)
* Custom rules (user-defined thresholds)
* Notifications (email, SMS, in-app)

---

## 3.10 Expense & Financial Tracking (Optional MVP+)

* Expense ingestion (PMS or manual)
* Categorization (repairs, taxes, utilities)
* NOI calculation
* CapEx tracking

---

## 4. Integrations

### 4.1 PMS Integrations

* Build abstraction layer for multiple systems
* API-based connectors
* Fallback: CSV ingestion

### 4.2 Email Integration

* Dedicated inbox for ingestion
* Auto-classification of attachments

### 4.3 Cloud Storage

* Google Drive / Dropbox sync (documents)

---

## 5. Data Ingestion & Processing

### 5.1 ETL Pipeline

* Extract (API, file, email)
* Transform (mapping + normalization)
* Load (central database)

### 5.2 Data Mapping UI

* User maps fields from spreadsheet → system schema
* Save reusable templates

### 5.3 Data Quality Handling

* Missing data flags
* Conflict resolution rules
* Versioning / audit trail

---

## 6. User Experience Requirements

### 6.1 Onboarding

* Guided setup:

  * Add properties
  * Connect PMS
  * Upload spreadsheets
  * Upload documents

### 6.2 Navigation

* Portfolio → Property → Unit hierarchy
* Global search (property, tenant, document)

### 6.3 Customization

* Custom dashboards
* Custom alerts
* Custom tags (markets, strategies, etc.)

### 6.4 Dashboard
The dashboard should show:
- the list of properties owned by the investor
- for each property items that need attention. Examples of items that need attention include:
    - Rent delayed
    - Mortgage payment due soon
    - Smoke alarm inspection due
    - Any county or city inspection due
    - Insurance payment due

### 6.5 Document Vault
Application should maintain a document vault. For each property in the dashboard, the application should show a list of documents for that property. Examples of documents for a property include:
    - Title
    - Compliance documents including (Lead Paint inspection, fire safety inspection, Rental License, etc)
    - Certificate of Insurance
    - Leases for

---

## 7. Security & Compliance

* Role-based access control
* Data encryption (at rest + in transit)
* Audit logs
* Secure document storage
* Optional 2FA

---

## 8. Non-Functional Requirements

### Performance

* Dashboard load < 2 seconds
* Near real-time sync for APIs

### Scalability

* Support portfolios from 1 → 1,000+ units

### Reliability

* 99.9% uptime target
* Graceful degradation if integrations fail

---

## 9. Architecture (High-Level)

### Frontend

* React / Next.js web app

### Backend

* API layer (Python)
* Microservices for:

  * Ingestion
  * Normalization
  * Alerts

### Data Layer

* Relational DB (PostgreSQL)
* Document storage (S3 or equivalent)

### Processing

* Background jobs (queue-based)
* OCR + NLP for documents

---

## 10. Future Enhancements

* AI-driven insights (e.g., “this property underperforms similar assets”)
* Predictive vacancy / delinquency
* Automated underwriting for new deals
* Integration with accounting tools
* Mobile app

---



