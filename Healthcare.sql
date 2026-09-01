create database healthcare;
use healthcare;

select count(*) from diabetic_data;

select * from diabetic_data limit 10;

update diabetic_data 
set race = nullif(race,'?'),weight=nullif(weight,'?'),payer_code=nullif(payer_code,'?'),
medical_specialty=nullif(medical_specialty,'?'),diag_1=nullif(diag_1,'?'),
diag_2=nullif(diag_2,'?'),diag_3=nullif(diag_3,'?');

alter table diabetic_data
modify diag_1 varchar(10);

set SQL_SAFE_UPDATES = 1

select round(sum(weight is null)/count(*) *100,1) as pct_missing_weight,
round(sum(payer_code is null)/count(*) *100,1) as pct_missing_payer,
round(sum(medical_specialty is null)/count(*) *100,1) as pct_missing_specialty
from diabetic_data;

-- STEP 2

select patient_nbr,count(*) as encounter_count from diabetic_data
group by patient_nbr having count(*) >1 
order by encounter_count DESC limit 10;

create table diabetic_data_debug  as 
select t.*
from diabetic_data as t
inner join
(select patient_nbr,min(encounter_id) as first_encounter
from diabetic_data group by patient_nbr) first_enc
on t.patient_nbr=first_enc.patient_nbr
and t.encounter_id =first_enc.first_encounter;

select count(*) from diabetic_data_debug

-- what we did is we remove d all the second encounters from the original dataset
-- and we also created a new dataset with the only first encounters and name the table as diabetic_data_debug

-- STEP 3

select discharge_disposition_id,count(*) as encounter_count
from diabetic_data
group by discharge_disposition_id 
order by encounter_count DESC;

SELECT * 
FROM ids_mapping
WHERE description LIKE '%hospice%' 
   OR description LIKE '%expired%' 
   OR description LIKE '%deceased%';
   
   -- 11,13,14,19,20,21,26

select * from diabetic_data_debug limit 10;

SET SQL_SAFE_UPDATES = 1;
   
DELETE FROM diabetic_data_debug 
WHERE discharge_disposition_id IN (11, 13, 14, 19, 20, 21, 26);


-- step 4
select * from ids_mapping;

create table discharge_disposition_map(
discharge_disposition_id int,
description varchar(150)
);

create table admission_source_map(
admission_source_id int,
description varchar(150)
);

describe discharge_disposition_map;
describe admission_source_map;

INSERT INTO discharge_disposition_map (discharge_disposition_id, description) VALUES
(1, 'Discharged to home'),
(2, 'Discharged/transferred to another short term hospital'),
(3, 'Discharged/transferred to SNF'),
(4, 'Discharged/transferred to ICF'),
(5, 'Discharged/transferred to another type of inpatient care institution'),
(6, 'Discharged/transferred to home with home health service'),
(7, 'Left AMA'),
(8, 'Discharged/transferred to home under care of Home IV provider'),
(9, 'Admitted as an inpatient to this hospital'),
(10, 'Neonate discharged to another hospital for neonatal aftercare'),
(11, 'Expired'),
(12, 'Still patient or expected to return for outpatient services'),
(13, 'Hospice / home'),
(14, 'Hospice / medical facility'),
(15, 'Discharged/transferred within this institution to Medicare approved swing bed'),
(16, 'Discharged/transferred/referred another institution for outpatient services'),
(17, 'Discharged/transferred/referred to this institution for outpatient services'),
(18, 'NULL'),
(19, 'Expired at home. Medicaid only, hospice.'),
(20, 'Expired in a medical facility. Medicaid only, hospice.'),
(21, 'Expired, place unknown. Medicaid only, hospice.'),
(22, 'Discharged/transferred to another rehab fac including rehab units of a hospital.'),
(23, 'Discharged/transferred to a long term care hospital.'),
(24, 'Discharged/transferred to a nursing facility certified under Medicaid but not certified under Medicare.'),
(25, 'Not Mapped'),
(26, 'Unknown/Invalid'),
(27, 'Discharged/transferred to a federal health care facility.'),
(28, 'Discharged/transferred/referred to a psychiatric hospital of psychiatric distinct part unit of a hospital'),
(29, 'Discharged/transferred to a Critical Access Hospital (CAH).'),
(30, 'Discharged/transferred to another Type of Health Care Institution not Defined Elsewhere');
     

insert into admission_source_map (admission_source_id, description) VALUES
(1, 'Physician Referral'),
(2, 'Clinic Referral'),
(3, 'HMO Referral'),
(4, 'Transfer from a hospital'),
(5, 'Transfer from a Skilled Nursing Facility (SNF)'),
(6, 'Transfer from another health care facility'),
(7, 'Emergency Room'),
(8, 'Court/Law Enforcement'),
(9, 'Not Available'),
(10, 'Transfer from critial access hospital'),
(11, 'Normal Delivery'),
(12, 'Premature Delivery'),
(13, 'Sick Baby'),
(14, 'Extramural Birth'),
(15, 'Not Available'),
(17, NULL),
(18, 'Transfer From Another Home Health Agency'),
(19, 'Readmission to Same Home Health Agency'),
(20, 'Not Mapped'),
(21, 'Unknown/Invalid'),
(22, 'Transfer from hospital inpt/same fac reslt in a sep claim'),
(23, 'Born inside this hospital'),
(24, 'Born outside this hospital'),
(25, 'Transfer from Ambulatory Surgery Center'),
(26, 'Transfer from Hospice');


select * from discharge_disposition_map;
select * from admission_source_map;

-- step 5
select * from diabetic_data_debug
limit 50;

ALTER TABLE diabetic_data_debug ADD COLUMN age_midpoint INT;

UPDATE diabetic_data_debug
SET age_midpoint = CASE
    WHEN age = '[0-10)'   THEN 5
    WHEN age = '[10-20)'  THEN 15
    WHEN age = '[20-30)'  THEN 25
    WHEN age = '[30-40)'  THEN 35
    WHEN age = '[40-50)'  THEN 45
    WHEN age = '[50-60)'  THEN 55
    WHEN age = '[60-70)'  THEN 65
    WHEN age = '[70-80)'  THEN 75
    WHEN age = '[80-90)'  THEN 85
    WHEN age = '[90-100)' THEN 95
END;

-- exploratory analysis

select 
  readmitted,
  count(*) as encounter_count, 
  round((count(*) /(select count(*) from diabetic_data_debug)) *100,1) as pct_of_total 
  from diabetic_data_debug 
  group by readmitted
  order by encounter_count DESC;
  
  select 
  age ,
  age_midpoint,
  count(*) as total_encounters,
  sum(readmitted='<30') as readmitted_under_30,
  round(sum(readmitted='<30')/count(*)*100,1) as readmission_rate_pct
  from diabetic_data_debug
  group by age,age_midpoint
  order by age_midpoint;
  
select 
 m.description as admission_type,
 count(*) as total_encounters,
 round(sum(d.readmitted='<30')/count(*) * 100,1) as readmission_rate_pct
 from diabetic_data_debug as d
 join ids_mapping as m
 on d.admission_type_id=m.admission_type_id
 group by m.description order by readmission_rate_pct DESC;
 
 -- ADVANCE TECHNIQUES
 

with patient_risk_base as (
select 
encounter_id,
patient_nbr,
age_midpoint,
time_in_hospital,
num_lab_procedures,
number_diagnoses,
number_inpatient,
number_emergency,
number_outpatient,
diag_1,
readmitted,
case when readmitted = '<30' then 1 else 0 end as is_readmitted_30
from diabetic_data_debug)
select * from patient_risk_base limit 20;

with patient_risk_base as (
select encounter_id,age_midpoint,num_medications,readmitted,
case when readmitted = '<30' then 1 else 0 end as is_readmitted_30
from diabetic_data_debug
)
select encounter_id,age_midpoint,num_medications,
rank() over (partition by age_midpoint order by num_medications DESC) as med_rank_age_group
from patient_risk_base 
order by age_midpoint,med_rank_age_group
limit 200;


with patient_risk_base as (
select encounter_id,number_inpatient,readmitted,
case when readmitted = '<30' then 1 else 0 end as is_readmitted_30
from diabetic_data_debug)
select encounter_id,number_inpatient,
ntile(4) over(order by number_inpatient DESC) as rank_quartile
from patient_risk_base;


select 
encounter_id,
num_medications,
case 
when num_medications <= 10 then 'low'
when num_medications between	 11 and 20 then'medium'
else 'high'
end as medicaiton_burden_tier,
case 
when number_diagnoses <= 5 then 'Low complexity'
when number_diagnoses between 6 and 0 then 'moderate complexity'
else 'High Complexity'
end as diagnosis_complexity_tier
from diabetic_data_debug;

-- diag_1 notes
-- 390-459: Diseases of the circulatory system
-- 460-519: Diseases of the respiratory system
-- 520-579: Diseases of the digestive system
-- 580-629: Diseases of the genitourinary system
-- 800-999: Injury and poisoning




with diag_categorized as (
select 
encounter_id,
readmitted,
case 
WHEN diag_1 LIKE '250%' THEN 'Diabetes'
  WHEN CAST(LEFT(diag_1, 3) AS UNSIGNED) BETWEEN 390 AND 459 THEN 'CIRCULATORY'
  WHEN CAST(LEFT(diag_1, 3) AS UNSIGNED) BETWEEN 460 AND 519 THEN 'Respiratory'
  WHEN CAST(LEFT(diag_1, 3) AS UNSIGNED) BETWEEN 520 AND 579 THEN 'Digestive'
  WHEN CAST(LEFT(diag_1, 3) AS UNSIGNED) BETWEEN 580 AND 629 THEN 'Genitourinary'
  WHEN CAST(LEFT(diag_1, 3) AS UNSIGNED) BETWEEN 800 AND 999 THEN 'Injury'
 else 'Other'
end as diagnosis_category,
case when readmitted='<30' then 1 else 0 end as is_readmitted_30
from diabetic_data_debug
where diag_1 is not null
)
select 
diagnosis_category,
count(*) as total_encounters,
round(AVG(is_readmitted_30)*100,1) as readmission_rate_pct
from diag_categorized
group by diagnosis_category
having avg(is_readmitted_30)>(
select avg(is_readmitted_30) from diag_categorized
)
order by readmission_rate_pct DESC;

-- Finding 1. Top diagnosis categories driving readmission
-- Finding 2. Does a medication change at discharge affect readmission?
SELECT
	`change`, 
    COUNT(*) as total_encounters,
	ROUND(SUM(readmitted = '<30') / COUNT(*) * 100, 1) AS readmission_rate_pct
FROM diabetic_data_debug
GROUP BY `change`;

-- Finding 3. Discharge disposition impact
SELECT
	m.description as discharge_disposition, 
    COUNT(*) AS total_encounters, 
	ROUND(SUM(d.readmitted = '<30') / COUNT(*) * 100, 1) AS readmission_rate_pct
FROM diabetic_data_debug as d
JOIN discharge_disposition_map as m
ON d.discharge_disposition_id = m.discharge_disposition_id
GROUP BY m.description
HAVING COUNT(*) > 100
ORDER BY readmission_rate_pct DESC
LIMIT 10;


-- Finding 4. A1C testing and readmission

SELECT
	A1Cresult, 
    COUNT(*) as total_encounters, 
	ROUND(SUM(readmitted = '<30') / COUNT(*) * 100, 1) AS readmission_rate_pct
FROM diabetic_data_debug
GROUP BY A1Cresult;
