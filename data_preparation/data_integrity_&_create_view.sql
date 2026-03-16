/*================================================
  Validate primary keys before join and create VIEW
=================================================*/

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


-- no nulls and no duplicates
-- primary keys are clean
-- safe to create the view




/*I ll create a view from both tables, as a 'reporting mart', to act as a  single source of truth for all the risk analysis.
This will make it easier to query and analyze the data without having to join the tables every time.
Also it ll  simplifiy the 'Analysis Phase' avoid as possible complex queries.*/


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
