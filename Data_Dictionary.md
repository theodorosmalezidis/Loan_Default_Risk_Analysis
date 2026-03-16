
# Data Dictionary





### 1. **borrowers_dim Table**


| Column Name      | Data Type     | Description                                                                                   |
|------------------|---------------|-----------------------------------------------------------------------------------------------|
| borrower_id       | VARCHAR(50) primary key           | A unique identifier for each borrower in the dimension table.               |
| age        | INT           | The age of the borrower.                                        |
| state | VARCHAR(50)  | The borrower's state of residence.         |
| education_level          | VARCHAR(50)  | The borrower's education level (5 distinct values)      .                                  |
| employment_status    | VARCHAR(50)  | Current employment status of the borrower (5 distinct values)     .                                                |
| years_employed| INT  | Number of years the borrower is employed.                               |
| annual_income      | DECIMAL (15, 2)        | The borrower's annual income.
| credit_score     | INT          | The borrower's current FICO credit score.                                  |
| home_ownership      | VARCHAR(50)  |The borrower's current home ownership status (3 distinct values).               |
| dependents           | INT  | Number of household members financially supported by the borrower.|
| existing_monthly_debts | DECIMAL (15, 2)     | The borrower's current monthly debt payments.

---



### 2. **loans_fact Table**


| Column Name      | Data Type     | Description                                                                                   |
|------------------|---------------|-----------------------------------------------------------------------------------------------|
| loan_id       | VARCHAR(50) primary key           | A unique id for each loan record in the fact table.               |
|  borrower_id    | VARCHAR(50) foreign key           |A unique identifier that connects the borrowers_dim table to the loans_fact table.                                        |
| application_date | DATE  | The date of the loan's application.         |
| loan_purpose          | VARCHAR(50)  | The official purpose stated for the loan application .                                  |
| loan_amount    | DECIMAL (15, 2)  | Total amount of the loan     .                                                |
| term_months| INT  | The total duration of a loan expressed in months — i.e., how long the borrower has to repay the loan in full.                               |
| interest_rate      | DECIMAL (5, 2)        | The annual percentage charged  on the principal loan amount.
| monthly_payment     | DECIMAL (10, 2)          | The fixed amount the borrower pays each month to repay the loan, covering both principal and interest, calculated based on the loan amount, interest rate, and term.                                  |
| dti_ratio      | DECIMAL (5, 2)  |The percentage of the borrower's gross monthly income that goes toward paying monthly debt obligations.               |
| loan_status           | VARCHAR(50)  | The current repayment status of the loan, classified based on the number of days elapsed since the last missed or overdue payment (4 distinct values).|
| days_delinquent | INT     | The number of days THE borrower is past due on a scheduled loan payment — measured from the payment due date to the current date (or reporting date).
| defaulted | INT     | Binary indicator of whether the loan has reached default status. Assigned 1 when the borrower has failed to make payments for 90 or more consecutive days (days_delinquent ≥ 90), and 0 otherwise. Stored as INT to support direct aggregation.
| was_ever_delayed | INT     | Binary indicator of whether the loan ever exceeded 31 days delinquent at any point in its lifetime, regardless of current loan status. Stored as INT to support direct aggregation.