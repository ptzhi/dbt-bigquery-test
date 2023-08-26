{{ config(materialized='view') }}

WITH tripdata_0 AS 
(
  SELECT 
    *,
    cast(VendorID as integer) as vendorid_int,
  FROM {{ source('staging','green_taxi_2021-01') }}
  WHERE VendorID is not null 
),
tripdata as
(
  SELECT 
    *,
    row_number() OVER(PARTITION BY vendorid_int, lpep_pickup_datetime) AS rn
  FROM tripdata_0
)

SELECT
    -- identifiers
    {{ dbt_utils.generate_surrogate_key(['vendorid','lpep_pickup_datetime'])}} as tripid,
    vendorid_int as vendorid,
    cast(RatecodeID as integer) as ratecodeid,
    cast(PULocationID as integer) as  pickup_locationid,
    cast(DOLocationID as integer) as dropoff_locationid,

    -- timestamps
    cast(lpep_pickup_datetime as timestamp) as pickup_datetime,
    cast(lpep_dropoff_datetime as timestamp) as dropoff_datetime,

    -- trip info
    store_and_fwd_flag,
    cast(passenger_count as integer) as passenger_count,
    cast(trip_distance as numeric) as trip_distance,
    cast(trip_type as integer) as trip_type,

    -- payment info
    cast(fare_amount as numeric) as fare_amount,
    cast(extra as numeric) as extra,
    cast(mta_tax as numeric) as mta_tax,
    cast(tip_amount as numeric) as tip_amount,
    cast(tolls_amount as numeric) as tolls_amount,
    cast(ehail_fee as numeric) as ehail_fee,
    cast(improvement_surcharge as numeric) as improvement_surcharge,
    cast(total_amount as numeric) as total_amount,
    cast(payment_type as integer) as payment_type,
    {{ get_payment_type_description('payment_type')}} as payment_type_description,
    cast(congestion_surcharge as numeric) as congestion_surcharge

FROM tripdata
WHERE rn=1

-- dbt build -m <model.sql> --var 'is_test_run: false'
{% if var('is_test_run', default=true) %}

  limit 100

{% endif %}