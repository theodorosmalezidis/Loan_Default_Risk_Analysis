

--- stored procedure with all states overview deafault rate with comparison to portfolio dr target as parameter.

SELECT
      state
    , COUNT(*)                                                    AS total_loans
    , SUM(defaulted)                                              AS total_defaults
    , CAST(SUM(defaulted)*100.0/COUNT(*) 
        AS DECIMAL(10,2))                                         AS state_dr
    , CAST(SUM(defaulted)*100.0/COUNT(*) 
        AS DECIMAL(10,2)) - 10.0                                  AS vs_dr_target
    , RANK() OVER (
        ORDER BY SUM(defaulted)*100.0/COUNT(*) DESC)              AS risk_rank
FROM
    loan_default_risk
GROUP BY
    state;



-- stored as proceduure to allow for dynamic state input and comparison of key risk factors within the state to identify the drivers of elevated default rates, after the previous query reveal the states above dr target.


    WITH state_condition_dr AS (
        SELECT
              'DTI > 50'                AS risk_condition
            , COUNT(*)                  AS condition_loans
            , CAST(SUM(defaulted)*100.0/COUNT(*)
                AS DECIMAL(10,2))       AS condition_dr
        FROM loan_default_risk
        WHERE state        = @target_state
          AND dti_ratio    > 50
        GROUP BY state

        UNION ALL

        SELECT
              'Credit Score < 600'      AS risk_condition
            , COUNT(*)                  AS condition_loans
            , CAST(SUM(defaulted)*100.0/COUNT(*)
                AS DECIMAL(10,2))       AS condition_dr
        FROM loan_default_risk
        WHERE state        = @target_state
          AND credit_score < 600
        GROUP BY state

        UNION ALL

        SELECT
              'Interest Rate >= 12.5'   AS risk_condition
            , COUNT(*)                  AS condition_loans
            , CAST(SUM(defaulted)*100.0/COUNT(*)
                AS DECIMAL(10,2))       AS condition_dr
        FROM loan_default_risk
        WHERE state        = @target_state
          AND interest_rate >= 12.5
        GROUP BY state
    )
    SELECT
          risk_condition
        , condition_loans
        , condition_dr                  AS default_rate
        , RANK() OVER (
            ORDER BY condition_dr DESC) AS dr_rank
    FROM
        state_condition_dr
    ORDER BY
        dr_rank ASC;

---------------------------------------

SELECT
      state
    , COUNT(*)                                                    AS total_loans
    , SUM(defaulted)                                              AS total_defaults
    , CAST(SUM(defaulted)*100.0/COUNT(*) 
        AS DECIMAL(10,2))                                         AS state_dr
    , CAST(SUM(defaulted)*100.0/COUNT(*) 
        AS DECIMAL(10,2)) - 10.0                                 AS vs_dr_target
    , RANK() OVER (
        ORDER BY SUM(defaulted)*100.0/COUNT(*) DESC)              AS risk_rank
FROM
    loan_default_risk
GROUP BY
    state
having count(*)>=20;







  WITH state_condition_dr AS (
        SELECT
              'DTI > 50'                AS risk_condition
            , COUNT(*)                  AS condition_loans
            , CAST(SUM(defaulted)*100.0/COUNT(*)
                AS DECIMAL(10,2))       AS condition_dr
        FROM loan_default_risk
        WHERE state        = 'Virginia'
          AND dti_ratio    > 50
        GROUP BY state

        UNION ALL

        SELECT
              'Credit Score < 600'      AS risk_condition
            , COUNT(*)                  AS condition_loans
            , CAST(SUM(defaulted)*100.0/COUNT(*)
                AS DECIMAL(10,2))       AS condition_dr
        FROM loan_default_risk
        WHERE state        = 'Virginia'
          AND credit_score < 600
        GROUP BY state

        UNION ALL

        SELECT
              'Interest Rate >= 12.5'   AS risk_condition
            , COUNT(*)                  AS condition_loans
            , CAST(SUM(defaulted)*100.0/COUNT(*)
                AS DECIMAL(10,2))       AS condition_dr
        FROM loan_default_risk
        WHERE state        =  'Virginia'
          AND interest_rate >= 12.5
        GROUP BY state
    )
    SELECT
          risk_condition
        , condition_loans
        , condition_dr                  AS default_rate
        , RANK() OVER (
            ORDER BY condition_dr DESC) AS dr_rank
    FROM
        state_condition_dr
    ORDER BY
        dr_rank ASC;



select * FROM borrowers_dim