# Introduction

In this scenario the management of a mid-size consumer lending company is concerned about the rising default rate on personal loans.

The management wants data-driven insights about the factors driving the increase of default rate and recommendations about the underwriting policy to lower and maintain the default rate below the target of 10%.

They also asked if i can construct a tool for the BI and Risk analysts to monitor and present monthly the numbers of Loan Book's performance.

# Dataset

 As a data analyst of the company i have been provided with two datasets:

1. Borrower profiles with demographic and financial data of the applicants().

2. Application details from existing Loan Book.
<br><br>

![visual](visuals_&_assets/data_modelling.png)

 *A star schema with one dimension table
(borrowers_dim) and one fact table
(loans_fact) joined on borrower_id.(diagram created with draw.io).*

For full field descriptions
see the [Data Dictionary](https://github.com/theodorosmalezidis/Loan_Default_Risk_Analysis/blob/main/Data_Dictionary.md).

# Goals

To address both requests i have structured the project in two parts.

## Part 1 - Loan Default Risk Assessment & Underwriting Strategy

A three phase process to identify, quantify and control credit risk.

1. Explore the data and identify the key risk factors driving default rate increase.

2. Create a framework to quantify the risk.

3. Provide data driven recommendations from the analysis to improve the underwriting process, decrease the default rate and control the risk of default.

For Part 1 Overview see [here](https://github.com/theodorosmalezidis/Loan_Default_Risk_Analysis/tree/main/Part_1).

## Part 2 - Loan Book Performance Monitoring

A stored procedure returning a clean BI-ready Dashboard with all the metrics necessary to monitor and present the Loan Book's performance monthly to management.

For Part 2 Overview see [here](https://github.com/theodorosmalezidis/Loan_Default_Risk_Analysis/tree/main/Part_2).



# My Tools for the Project

- **PostgreSQL :** A powerhouse opensource database. 
- **VS Code :** The ultimate code editor.
- **SQL :** The language to explore and manipulate data. 
- **Git :** The version control wizard that keeps my code history tidy and collaborative.
- **GitHub :** Essential for sharing my logic and SQL scripts and analysis, ensuring project tracking.
- **Draw.io :** I use this tool to create clear visual documentation.

