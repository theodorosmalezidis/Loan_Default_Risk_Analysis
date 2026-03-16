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




/* some basic eda*/


/* calculate total number of borrowers */

select
     count(distinct borrower_id) as total_borrowers
from
    loan_default_risk


/* calculate total number of loans originated */

select
     count(distinct loan_id) as total_loans
from
    loan_default_risk

/* more loans than borrowers, which means some borrowers have multiple loans, 
we can check that later if we want to see if multiple loans increase the risk of default or not,
but we can find out how many borrowers have multiple loans first. */

with borrower_loan_counts as (

    select
          borrower_id
        , count(*) as loan_count
    from
        loan_default_risk
    group by
        borrower_id
)
select
      loan_count
    , count(*) as total_borrowers
from
    borrower_loan_counts
group by
    loan_count
order by
    loan_count desc;


/*calculate total default_rate of portfolio to find the actual risk of the portfolio
and have a benchmark to compare the default rates of different segments and risk buckets we will create later on.*/

select
      sum(defaulted) as total_default_count
    , count(*) as total_loans
    , cast(sum(defaulted)*100.0/count(*) as decimal (10,2)) as default_rate
from
    loan_default_risk      

/*which factors have the biggest 'spread' in default rates 
 to see what's actually driving the risk*/





with default_rate_data as(   --creating a cte to calculate default rates for each factor and category, and filter out categories with less than 10 loans to ensure statistical significance.


    select 
          'Loan Purpose' as factor
        , loan_purpose as category
        , count(*) as loan_volume
        , cast(sum(defaulted)*100.0/count(*) as decimal(10,2)) as default_rate
    from 
        loan_default_risk
    group by 
          1
        , 2
    having count(*)>=10

    union all

    select 
          'Home Ownership' as factor
        , home_ownership as category
        , count(*) as loan_volume
        , cast(sum(defaulted)*100.0/count(*) as decimal(10,2)) as default_rate
    from 
        loan_default_risk
    group by 
          1
        , 2
    having count(*)>=10

    union all

    select 
          'Employment Status' as factor
        , employment_status as category
        , count(*) as loan_volume
        , cast(sum(defaulted)*100.0/count(*) as decimal(10,2)) as default_rate
    from 
        loan_default_risk
    group by 
          1
        , 2
    having count(*)>=10

    union all

    select 
          'Credit Score' as factor
        , case 
            when credit_score < 600 then '<600'
            when credit_score between 600 and 649 then '600-649'
            when credit_score between 650 and 699 then '650-699'
            when credit_score between 700 and 749 then '700-749'
            else '750+' end as category
        , count(*) as loan_volume
        , cast(sum(defaulted)*100.0/count(*) as decimal(10,2)) as default_rate
     from 
        loan_default_risk
    group by 
          1
        , 2
    having count(*)>=10
    

    union all

    select 
          'Annual Income' as factor
        , case 
            when annual_income < 40000 then '<40000'
            when annual_income between 40000 and 69999 then '40000-69999'
            when annual_income between 70000 and 99999 then '70000-99999'
            when annual_income between 100000 and 129999 then '100000-129999'
            else '130000+' end as category
        , count(*) as loan_volume
        , cast(sum(defaulted)*100.0/count(*) as decimal(10,2)) as default_rate
     from 
        loan_default_risk
    group by 
          1
        , 2
    having count(*)>=10

  union all

    select 
          'dti Ratio' as factor
        , case 
            when dti_ratio < 20 then 'Very Low Risk'
            when dti_ratio between 20 and 34 then 'Low Risk'
            when dti_ratio between 35 and 49 then 'Moderate Risk'
            when dti_ratio between 50 and 74 then 'High Risk'
            else 'Very High Risk' end as category
        , count(*) as loan_volume
        , cast(sum(defaulted)*100.0/count(*) as decimal(10,2)) as default_rate
     from 
        loan_default_risk
    group by 
          1
        , 2
    having count(*)>=10

  union all

    select 
          'Interest Rate' as factor
        , case 
            when interest_rate < 7.5 then '<7.5'
            when interest_rate between 7.5 and 9.99 then '7.5-9.99'
            when interest_rate between 10 and 12.49 then '10-12.49'
            else '>12.5' end as category
        , count(*) as loan_volume
        , cast(sum(defaulted)*100.0/count(*) as decimal(10,2)) as default_rate
     from 
        loan_default_risk
    group by 
          1
        , 2
    having count(*)>=10

)   


select 
      factor
    , min(default_rate) as min_rate
    , max(default_rate) as max_rate
    , max(default_rate)-min(default_rate) as spread
from
    default_rate_data
group by
    factor
order by
    spread desc;
-- annual income shows the lowest spread suggesting it is not an significant predictor

/*After identifing the 3 big factors i drill down more to isolate the buckets with the biggest contibution to default rate of each.*/

-- credit score buckets

 select 
          'Credit Score' as factor
        , case 
            when credit_score < 600 then '<600'
            when credit_score between 600 and 649 then '600-649'
            when credit_score between 650 and 699 then '650-699'
            when credit_score between 700 and 749 then '700-749'
            else '750+' end as category
        , count(*) as loan_volume
        , cast(sum(defaulted)*100.0/count(*) as decimal(10,2)) as default_rate
     from 
        loan_default_risk
    group by 
          1
        , 2
      having
        count(*)>=10
    order by 
        default_rate desc;

-- interest rate buckets

select 
          'Interest Rate' as factor
        , case 
            when interest_rate < 7.5 then '<7.5'
            when interest_rate between 7.5 and 9.99 then '7.5-9.99'
            when interest_rate between 10 and 12.49 then '10-12.49'
            else '>=12.5' end as category
        , count(*) as loan_volume
        , cast(sum(defaulted)*100.0/count(*) as decimal(10,2)) as default_rate
     from 
        loan_default_risk
    group by 
          1
        , 2
      having
        count(*)>=10
    order by 
        default_rate desc;

--dti_ratio buckets

   select 
          'dti Ratio' as factor
        , case 
            when dti_ratio < 20 then '< 20'
            when dti_ratio between 20 and 34 then '20-34'
            when dti_ratio between 35 and 49 then '35-49'
            when dti_ratio between 50 and 74 then '50-74'
            else '>75' end as category
        , count(*) as loan_volume
        , cast(sum(defaulted)*100.0/count(*) as decimal(10,2)) as default_rate
     from 
        loan_default_risk
    group by 
          1
        , 2
    having
        count(*)>=10
    order by 
        default_rate desc;



/* create a risk-score (Cross-Factor Validation) with the bucket with highest default rate from each of the three factors contibute to the overall default rate of portfolio*/




with risk_scoreboard as ( -- CTE to calculate the risk score for each loan based on the three highest-default buckets identified in the factor analysis above.

    SELECT 
          CASE WHEN credit_score  <  600  THEN 1 ELSE 0 END +
          CASE WHEN interest_rate >= 12.5 THEN 1 ELSE 0 END +
          CASE WHEN dti_ratio     >  50   THEN 1 ELSE 0 END  AS risk_score
        , defaulted
    FROM loan_default_risk

)

select 
      risk_score
    , count(*) as total_loans
    , sum(defaulted) as total_defaults
    , cast(sum(defaulted)*100.0/count(*) as decimal(10,2)) as default_rate
    , cast(count(*)*100.0/sum(count(*)) over() as decimal(10,2)) as pct_of_portfolio
    , cast(sum(defaulted)*100.0/sum(sum(defaulted)) over() as decimal(10,2)) as pct_of_all_defaults
    /*this metric quantifies how much riskier these borrowers are relative to the average borrower in the portfolio. 
    It compares the default rate of each risk score bucket to the overall default rate of the entire portfolio, 
    showing how much more likely is a loan in this risk score to default compared to the average loan in the portfolio(most important metric ) */
    , cast((sum(defaulted)*100.0/count(*))/((sum(sum(defaulted)) over ()*100.0/sum(count(*)) over())) as decimal(10,2)) as risk_ratio 
from 
    risk_scoreboard
group by
    risk_score
order by
    default_rate desc;


/*Create a comparison of the three key risk factors
  across the portfolio and the risk score 2 & 3 segments to quantify the anomaly that drives elevated default rates*/

select 
      'Portfolio' as segment
    ,  cast(avg(credit_score) as decimal (10,2)) as avg_credit_score
    , cast(avg(interest_rate) as decimal (10,2))as avg_interest_rate
    , cast(avg(dti_ratio) as decimal (10,2))as avg_dti_ratio
from 
    loan_default_risk

union all 

select 
      'Risk Score 3' as segment
    , cast(avg(credit_score) as decimal (10,2)) as avg_credit_score
    , cast(avg(interest_rate) as decimal (10,2))as avg_interest_rate
    , cast(avg(dti_ratio) as decimal (10,2))as avg_dti_ratio
from 
    loan_default_risk
where
    case when credit_score  <  600  then 1 else 0 end +
    case when interest_rate >= 12.5 then 1 else 0 end +
    case when dti_ratio     >  50   then 1 else 0 end = 3

union all 

select 
      'Risk Score 2' as segment
    , cast(avg(credit_score) as decimal (10,2)) as avg_credit_score
    , cast(avg(interest_rate) as decimal (10,2))as avg_interest_rate
    , cast(avg(dti_ratio) as decimal (10,2))as avg_dti_ratio
from 
    loan_default_risk
where
    case when credit_score  <  600  then 1 else 0 end +
    case when interest_rate >= 12.5 then 1 else 0 end +
    case when dti_ratio     >  50   then 1 else 0 end = 2