WITH spravato_shipments AS (
    SELECT 
        patient_id,
        rx_date,
        ship_date,
        rx_refills,
        refill_remaining,
        ROW_NUMBER() OVER (PARTITION BY patient_id ORDER BY ship_date) as shipment_number,
        LAG(ship_date) OVER (PARTITION BY patient_id ORDER BY ship_date) as previous_ship_date
    FROM 
        pe2eprddb.patiente2e_new.jbi_spp 
    WHERE 
        product = 'SPRAVATO'
        AND ship_date IS NOT NULL
),
patient_persistence AS (
    SELECT 
        patient_id,
        MIN(rx_date) as first_rx_date,
        MIN(ship_date) as first_ship_date,
        MAX(ship_date) as last_ship_date,
        COUNT(*) as total_shipments,
        MAX(rx_refills) as max_refills,
        MIN(refill_remaining) as min_refill_remaining,
        -- Calculate persistence as days from first to last shipment
        DATEDIFF(day, MIN(ship_date), MAX(ship_date)) as persistence_days,
        -- Alternative persistence calculation using current date for ongoing patients
        DATEDIFF(day, MIN(ship_date), 
            CASE 
                WHEN MAX(ship_date) >= CURRENT_DATE - INTERVAL '60 days' 
                THEN CURRENT_DATE 
                ELSE MAX(ship_date) 
            END) as persistence_days_current,
        -- Check if patient is still active (shipped within last 60 days)
        CASE 
            WHEN MAX(ship_date) >= CURRENT_DATE - INTERVAL '60 days' THEN 1 
            ELSE 0 
        END as is_active_patient
    FROM 
        spravato_shipments
    WHERE 
        first_rx_date >= '2023-01-01'
        AND first_rx_date <= '2023-12-31'
    GROUP BY 
        patient_id
)

SELECT
    -- Patient Demographics
    pp.patient_id,
    pp.persistence_days,
    pp.persistence_days_current,
    CASE WHEN pp.persistence_days_current > 180 THEN 1 ELSE 0 END AS persistent_over_180_days,
    
    -- Prescription and shipment info
    pp.first_rx_date,
    pp.first_ship_date,
    pp.last_ship_date,
    pp.total_shipments,
    pp.max_refills,
    pp.min_refill_remaining,
    pp.is_active_patient,
    
    -- SDOH data
    s.ice_ethnic_code_broad_desc AS ethnicity,
    s.ap_estimated_income_dollar_value_desc AS estimated_income,
    s.ice_education_level_code_desc AS education_level,
    s.ice_marital_status_code_code AS marital_status,
    
    -- Calculated therapy duration
    DATEDIFF(day, pp.first_ship_date, COALESCE(pp.last_ship_date, CURRENT_DATE)) AS therapy_duration,
    
    -- Product identifier
    'SPRAVATO' AS product
FROM
    patient_persistence pp
LEFT JOIN
    patiente2e_new_vw.vw_acxiom_sdoh s ON pp.patient_id = s.patient_id
ORDER BY
    pp.patient_id;
