# Introduction

In this scenario the management of a mid-size consumer lending company is concerned about the rising default rate on personal loans.

The management wants data-driven insights about the factors driving the increase of default rate and recommendations about the underwriting policy to lower and maintain the default rate below the target of 10%.

They also asked if i can construct a tool for the BI and Risk analysts to monitor and present monthly the numbers of Loan Book's performance.

# Dataset

 As a data analyst of the company i have been provided with two csv files:

1. Borrower profiles with demographic and financial data of the applicants.

2. Application details from existing Loan Book.


# Goals

To address both requests i have structured the project in two parts.

## Part 1 - Loan Default Risk Assessment & Underwriting Strategy

A three phase process to identify, quantify and control default risk.

1. Explore the data and identify the key risk factors driving default rate increase.

2. Create a framework to quantify the risk.

3. Provide data driven recommendations from the analysis to improve the underwriting process, decrease the default rate and control the risk of default.



## Part 2 - Loan Book Performance Monitoring

A stored procedure returning a clean BI-ready Dashboard with all the metrics necessary to monitor and present the Loan Book's performance monthly to management.


# My Tools for the Project

- **PostgreSQL :** Open source relational database for all data storage and querying.
- **pgAdmin** PostgreSQL GUI used to create tables and import source CSV files. 
- **VS Code :**  Code editor for writing and managing SQL scripts.
- **SQL :** Primary language for data exploration, analysis and manipulation. 
- **Git :** Version control for tracking code changes and project history.
- **GitHub :** Platform for hosting
  and sharing scripts and documentation.
- **Draw.io :** Visual documentation and diagram creation tool.
- **pgAdmin** PostgreSQL GUI used to create tables and import source CSV files.

# Set Up & Data Preparation

1. Create the Database and the Tables and import the source csv files using pgAdmin's import tool. 
<br><br>

![visual](visuals_&_assets/ddl_&_import.png)
<br><br>
*Set up process (image created with draw.io).*
<br><br>
<br><br>
![visual](visuals_&_assets/data_modelling.png)
<br><br>
 *A star schema with one dimension table
(borrowers_dim) and one fact table
(loans_fact) joined on borrower_id.(image created with draw.io).*

For full field descriptions
see the [Data Dictionary](https://github.com/theodorosmalezidis/Loan_Default_Risk_Analysis/blob/main/Data_Dictionary.md).

2. Data Integrity Checks & Reporting View Creation

Before i explore and analyze the data i decided to create a View from the two tables as a 'reporting mart', to act as a  single source of truth for all the analysis.
This will make it easier to query and analyze the data without having to join the tables every time avoiding as possible complex queries.

- Validate primary keys before join and create VIEW

```sql
-- NULL check on primary keys

select 
    * 
from 
    borrowers_dim
where
    borrower_id is null;

select 
    *
from
    loans_fact
where
    loan_id is null;


-- Duplicate check on primary keys

select 
      borrower_id  
    , count(*) as duplicates
from
    borrowers_dim
group by
    borrower_id
having
    count(*) > 1
order by
    duplicates desc;

select 
      loan_id  
    , count(*) as duplicates
from
    loans_fact
group by
    loan_id
having
    count(*) > 1
order by
    duplicates desc;
```

No nulls and no duplicates, primary keys are clean — safe to create the view.

- Create View

```sql
drop view if exists loan_default_risk;

create view loan_default_risk as 

select
      b.borrower_id
    , b.age
    , b.state
    , b.education_level
    , b.employment_status
    , b.years_employed
    , b.annual_income
    , b.credit_score
    , b.home_ownership
    , b.dependents
    , b.existing_monthly_debt
    , l.loan_id
    , l.application_date
    , l.loan_purpose
    , l.loan_amount
    , l.term_months
    , l.interest_rate
    , l.monthly_payment
    , l.dti_ratio
    , l.loan_status
    , l.days_delinquent
    , l.defaulted
    , l.was_ever_delayed
      -- create a risk category column in specific buckets based on loan status and days delinquent
    , case   
        when l.loan_status='Paid Off'  then 'Closed'
        when l.days_delinquent > 90 then 'Defaulted'
        when l.days_delinquent = 0 then 'Performing'
        when l.days_delinquent between 1 and 30 then 'Low Risk'
        when l.days_delinquent between 31 and 90 then 'High Risk'
        else 'Unknown'
      end as risk_category

from
    borrowers_dim b
        join loans_fact l
            on b.borrower_id = l.borrower_id;
```
With the reporting view in place
 the analysis can begin.

For Part 1 Overview see [here](https://github.com/theodorosmalezidis/Loan_Default_Risk_Analysis/tree/main/Part_1).


For Part 2 Overview see [here](https://github.com/theodorosmalezidis/Loan_Default_Risk_Analysis/tree/main/Part_2).