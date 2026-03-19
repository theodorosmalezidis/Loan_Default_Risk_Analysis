


/* some basic eda*/


-- calculate total number of borrowers 

select
     count(distinct borrower_id) as total_borrowers
from
    loan_default_risk;


-- calculate total number of loans originated 

select
     count(distinct loan_id) as total_loans
from
    loan_default_risk;



/* more loans than borrowers, which means some borrowers have multiple loans,
we can check  if multiple loans to a single borrower have higher default rate */


-- first distribution of loans per borrower
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
    loan_count ;


-- then single vs multiple comparison of default rates 
with borrowers_stats as(
    select 
        borrower_id
      , count(*) as total_loan_count
      ,max(defaulted) as has_ever_defaulted-- 1 if defaulted in any loan, 0 otherwise
    from
      loan_default_risk
    group by
        borrower_id   
)

select 
    case    
      when total_loan_count=1 then 'Single Loan' else 'Multiple Loans' end as borrower_category
  , count(*) as total_borrowers
  , sum(has_ever_defaulted) total_defaulted
  , cast(sum(has_ever_defaulted)*100.0/count(*) as decimal (10,2)) as default_rate
from 
  borrowers_stats
group by 
  1;

-- calculate  loan book default rate and difference to target default rate 

select 
      count(*) as total_loans
    , sum(defaulted) as total_defaults
    , cast(sum(defaulted)*100.0/count(*) as decimal(10,2)) as default_rate
    , cast(sum(defaulted)*100.0/count(*) as decimal(10,2))-10.0 as diff_vs_target
from
    loan_default_risk;



     
-- Calculate if factors i will measure have any nulls 

select 
      sum(case when loan_purpose is null then 1 else 0 end) as loan_purpose_nulls
    , sum(case when home_ownership is null then 1 else 0 end) as home_ownership_nulls
    , sum(case when employment_status is null then 1 else 0 end) as employment_status_nulls
    , sum(case when annual_income is null then 1 else 0 end) as annual_income_nulls
    , sum(case when credit_score is null then 1 else 0 end) as credit_score_nulls
    , sum(case when interest_rate is null then 1 else 0 end) as interest_rate_nulls
    , sum(case when dti_ratio is null then 1 else 0 end) as dti_ratio_nulls
    , sum(case when defaulted is null then 1 else 0 end) as defaulted_nulls

from
    loan_default_risk;




--which factors have the biggest 'spread' in default rates to see what's actually driving the risk





with default_rate_data as(   --creating a cte to calculate default rates for each factor and category, and filter out buckets with less than 10 loans to ensure statistical significance.


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
    having count(*)>=10 --  -- minimum 10 loans per bucket to ensure statistically meaningful default rates

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
            when dti_ratio < 20 then '< 20'
            when dti_ratio between 20 and 34 then '20-34'
            when dti_ratio between 35 and 49 then '35-49'
            else '>=50' end as category
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


/*After identifing the 3 big factors with the biggest contibution to the loan's book total default rate i drill down more to isolate the bucket from each factor with the highest to default rate.*/

with top_factors as(-- cte to create buckets in each of those factors and union all in one table

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

  union all

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

  union all

  select 
        'dti Ratio' as factor
      , case 
          when dti_ratio < 20 then '< 20'
          when dti_ratio between 20 and 34 then '20-34'
          when dti_ratio between 35 and 49 then '35-49'
          else '>=50' end as category
      , count(*) as loan_volume
      , cast(sum(defaulted)*100.0/count(*) as decimal(10,2)) as default_rate
  from 
      loan_default_risk
  group by 
        1
      , 2
  having
      count(*)>=10
)
,
ranking as( -- cte to rank the categories in each factor by default rate

  select
      factor 
    , category
    , loan_volume
    , default_rate
    , rank() over(partition by factor order by default_rate desc) as dr_rank
  from 
    top_factors
)

select -- final query to find top bucket with highest default rate in each factor
    factor 
  , category
  , loan_volume
  , default_rate
from
  ranking
where
  dr_rank=1




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


/*Calculation of default rate under new policy of mmediately decline all applications triggering a Risk Score of 3*/

select
      count(*) as remaining_loans                                                  
    , sum(defaulted) as remaining_defaults                                             
    , cast(sum(defaulted)*100.0/count(*) as decimal(10,2)) as new_default_rate                                    
    , 14.14 - cast(sum(defaulted)*100.0/count(*) as decimal(10,2))  as improvement                                
from
    loan_default_risk
where
    case when credit_score < 600  then 1 else 0 end +
    case when interest_rate >= 12.5 then 1 else 0 end +
    case when dti_ratio > 50 then 1 else 0 end < 3;



/*Calculation of default rate under new policy of mmediately decline all applications triggering a Risk Score of 3 and 2*/

select
      count(*) as remaining_loans                                                  
    , sum(defaulted) as remaining_defaults                                             
    , cast(sum(defaulted)*100.0/count(*) as decimal(10,2)) as new_default_rate                                    
    , 14.14 - cast(sum(defaulted)*100.0/count(*) as decimal(10,2)) as improvement                                
from
    loan_default_risk
where
    case when credit_score < 600  then 1 else 0 end +
    case when interest_rate >= 12.5 then 1 else 0 end +
    case when dti_ratio > 50 then 1 else 0 end < 2;


/* Comparison of comparing the NII nd critical numbers for existing loan book applying current Underwriting Policy vs recommended*/

-- Calculate Loan Book Numbers with current Underwriting Policy

select 
      'Current Policy' as policy
    , count(*) as total_loans
    , cast(sum(case when defaulted=0 then (term_months*monthly_payment)-loan_amount else 0 end) as decimal (10,2)) as interest_revenue
    , cast(sum(case when defaulted=1 then (loan_amount) else 0 end) as decimal (10,2)) as principal_lost
    , sum(case when defaulted=0 then (term_months*monthly_payment)-loan_amount else 0 end)-sum(case when defaulted=1 then (loan_amount) else 0 end) as nii
from 
    loan_default_risk

union all 

-- Calculate Loan Book Numbers with recommended Underwriting Policy

select 
      'New Policy' as policy
    , count(*) as total_loans
    , cast(sum(case when defaulted=0 then (term_months*monthly_payment)-loan_amount else 0 end) as decimal (10,2)) as interest_revenue
    , cast(sum(case when defaulted=1 then (loan_amount) else 0 end) as decimal (10,2)) as principal_lost
    , sum(case when defaulted=0 then (term_months*monthly_payment)-loan_amount else 0 end)-sum(case when defaulted=1 then (loan_amount) else 0 end) as nii
from 
    loan_default_risk
where 
    case when credit_score < 600  then 1 else 0 end +
    case when interest_rate >= 12.5 then 1 else 0 end +
    case when dti_ratio > 50 then 1 else 0 end < 2;