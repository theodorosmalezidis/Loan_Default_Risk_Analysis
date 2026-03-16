-- Create borrowers_dim table with primary key.

create table borrowers_dim (
      borrower_id varchar(50) primary key
    , age int
    , state varchar(50)
    , education_level varchar(50)
    , employment_status varchar(50)
    , years_employed int
    , annual_income decimal(15, 2)
    , credit_score int
    , home_ownership varchar(50)
    , dependents int
    , existing_monthly_debts decimal(15, 2) 
);

-- Create loans_fact table with primary key and foreign key to relate with the borrowers_dim table.


create table loans_fact (
      loan_id varchar(50) primary key
    , borrower_id varchar(50) references borrowers_dim(borrower_id)
    , application_date date
    , loan_purpose varchar(50)
    , loan_amount decimal(10, 2)
    , term_months int
    , interest_rate decimal(5, 2)
    , monthly_payment decimal(10, 2)
    , dti_ratio decimal(5, 2)
    , loan_status varchar(20)
    , days_delinquent int
    , defaulted int 
    , was_ever_delayed int
);
