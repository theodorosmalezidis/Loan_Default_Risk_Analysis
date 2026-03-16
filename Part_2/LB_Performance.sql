/*"The loan book health summary is packaged
 as a stored procedure returning metrics
 in a presentation-ready tall format.
 The risk team executes the procedure
 monthly to populate the management
 dashboard without any manual
 reformatting required.*/ 
 
with portfolio_summary as (
    select
          
          count(*) as total_loans
        , sum(case when risk_category='Closed' then 1 else 0 end) as total_closed
        , sum(case when risk_category='Performing' then 1 else 0 end) as total_performing
        , sum(case when risk_category='Low Risk' then 1 else 0 end) as total_low_risk
        , sum(case when risk_category='High Risk' then 1 else 0 end) as total_high_risk
        , sum(case when risk_category='Defaulted' then 1 else 0 end) as total_defaulted
    from
        loan_default_risk
   
)

select 
      metric_name
    , metric_value

from
    (
        select 
              'Total Loans' as metric_name
            , total_loans as metric_value
        from
            portfolio_summary
        
        union all

        select 
              'Total Closed' as metric_name
            , total_closed as metric_value
        from
            portfolio_summary
        
        union all

        select 
              'Total Performing' as metric_name
            , total_performing as metric_value
        from
            portfolio_summary
        
        union all

        select 
              'Total Low Risk' as metric_name
            , total_low_risk as metric_value
        from
            portfolio_summary
        
        union all

            select 
              'Total High Risk' as metric_name
            , total_high_risk as metric_value
        from
            portfolio_summary
        
        union all

        select 
              'Total Defaulted' as metric_name
            , total_defaulted as metric_value
        from
            portfolio_summary

        union all

        select 
              'Closed Loans Rate %' as metric_name
            , cast(total_closed*100.0/total_loans as decimal(10,2)) as metric_value
        from
            portfolio_summary

        union all   

        select 
              'Performing Loans Rate %' as metric_name
            , cast(total_performing*100.0/total_loans as decimal(10,2)) as metric_value
        from
            portfolio_summary

        union all   

        select 
              'Low Risk Loans Rate %' as metric_name
            , cast(total_low_risk*100.0/total_loans as decimal(10,2)) as metric_value
        from
            portfolio_summary

        union all   

        select 
              'High Risk Loans Rate %' as metric_name
            , cast(total_high_risk*100.0/total_loans as decimal(10,2)) as metric_value
        from
            portfolio_summary

        union all   

        select 
              'Defaulted Loans Rate %' as metric_name
            , cast(total_defaulted*100.0/total_loans as decimal(10,2)) as metric_value
        from
            portfolio_summary
  

    )
